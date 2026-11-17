$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$env:PATH = "C:\msys64\ucrt64\bin;C:\msys64\usr\bin;$env:PATH"

$gcc = "C:\msys64\ucrt64\bin\gcc.exe"
$iverilog = "C:\msys64\ucrt64\bin\iverilog.exe"
$vvp = "C:\msys64\ucrt64\bin\vvp.exe"

$assembler = Join-Path $root "assembler\bin\binary-lab-assembler.exe"
$simulation = Join-Path $root "build\simulation\cpu-runner.vvp"
$runtime = Join-Path $root "build\runtime"

$sourceFiles = @(
    "assembler\src\main.c",
    "assembler\src\error.c",
    "assembler\src\parser.c",
    "assembler\src\instructions.c",
    "assembler\src\labels.c",
    "assembler\src\encoder.c",
    "assembler\src\output.c"
)

New-Item -ItemType Directory -Force "assembler\bin" | Out-Null
New-Item -ItemType Directory -Force "build\simulation" | Out-Null
New-Item -ItemType Directory -Force $runtime | Out-Null

Write-Host "Building the C assembler..." -ForegroundColor Cyan

& $gcc -std=c17 -Wall -Wextra -Wpedantic -Werror -I "assembler\include" @sourceFiles -o $assembler

if ($LASTEXITCODE -ne 0) {
    throw "Assembler compilation failed."
}

$rtl = @(
    "rtl\cpu\cpu_pkg.sv",
    "rtl\alu\alu.sv",
    "rtl\control\control_unit.sv",
    "rtl\registers\register_file.sv",
    "rtl\cpu\program_counter.sv",
    "rtl\memory\data_memory.sv",
    "rtl\memory\instruction_memory.sv",
    "rtl\bus\address_decoder.sv",
    "rtl\io\gpio.sv",
    "rtl\bus\memory_bus.sv",
    "rtl\cpu\cpu.sv",
    "testbench\integration\tb_cpu_runner.sv"
)

Write-Host "Compiling the SystemVerilog CPU..." -ForegroundColor Cyan

& $iverilog -g2012 -s tb_cpu_runner -o $simulation @rtl

if ($LASTEXITCODE -ne 0) {
    throw "CPU simulation compilation failed."
}

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:3000/")
$listener.Start()

Start-Process "http://localhost:3000/"

Write-Host ""
Write-Host "BINARY LAB CPU SERVER READY" -ForegroundColor Green
Write-Host "Address: http://localhost:3000/" -ForegroundColor Green
Write-Host "CPU: SystemVerilog + Icarus Verilog" -ForegroundColor Green
Write-Host "Assembler: C" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop." -ForegroundColor Yellow

function Send-JsonResponse {
    param(
        $Context,
        [int]$StatusCode,
        $Data
    )

    $json = $Data | ConvertTo-Json -Depth 8 -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)

    $Context.Response.StatusCode = $StatusCode
    $Context.Response.ContentType = "application/json; charset=utf-8"
    $Context.Response.ContentLength64 = $bytes.Length
    $Context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $Context.Response.Close()
}

function Get-SignedByte {
    param([string]$Bits)

    $value = [Convert]::ToInt32($Bits, 2)

    if ($value -ge 128) {
        $value -= 256
    }

    return $value
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $path = $request.Url.AbsolutePath

        if ($request.HttpMethod -eq "POST" -and $path -eq "/api/execute") {
            try {
                $reader = [System.IO.StreamReader]::new(
                    $request.InputStream,
                    $request.ContentEncoding
                )

                $body = $reader.ReadToEnd()
                $reader.Close()

                $data = $body | ConvertFrom-Json

                $operation = [string]$data.operation
                $first = [string]$data.a
                $second = [string]$data.b

                if ($first -notmatch '^[01]{8}$') {
                    throw "The first input must contain exactly 8 binary digits."
                }

                if ($operation -notin @("and", "or", "xor", "not")) {
                    throw "Unsupported operation."
                }

                if ($operation -ne "not" -and $second -notmatch '^[01]{8}$') {
                    throw "The second input must contain exactly 8 binary digits."
                }

                $valueA = Get-SignedByte $first

                if ($operation -eq "not") {
                    $valueB = -1
                    $assembly = @"
ADDI R1, $valueA
ADDI R2, -1
XOR R3, R2
HALT
"@
                }
                else {
                    $valueB = Get-SignedByte $second

                    $assembly = @"
ADDI R1, $valueA
ADDI R2, $valueB
$($operation.ToUpper()) R3, R2
HALT
"@
                }

                $sourcePath = Join-Path $runtime "request.asm"
                $binaryPath = Join-Path $runtime "request.bin"

                Set-Content -LiteralPath $sourcePath -Value $assembly -Encoding ascii

                & $assembler $sourcePath -o $binaryPath

                if ($LASTEXITCODE -ne 0) {
                    throw "The assembler rejected the generated program."
                }

                $simulatorOutput = & $vvp $simulation "+program=$binaryPath" 2>&1

                if ($LASTEXITCODE -ne 0) {
                    throw "CPU simulator failed: $($simulatorOutput -join ' ')"
                }

                $outputText = $simulatorOutput -join "`n"

                if ($outputText -notmatch 'EXECUTION_STATUS=HALTED') {
                    throw "CPU did not halt successfully: $outputText"
                }

                if ($outputText -notmatch 'REGISTER_R3=(\d+)') {
                    throw "CPU did not return register R3."
                }

                $result = [int]$Matches[1]

                $response = @{
                    success = $true
                    operation = $operation
                    inputA = $first
                    inputB = if ($operation -eq "not") { $null } else { $second }
                    result = $result
                    binary = [Convert]::ToString($result, 2).PadLeft(8, '0')
                    assembly = $assembly.Trim()
                    machineCodeBytes = (Get-Item $binaryPath).Length
                    execution = $outputText
                }

                Send-JsonResponse $context 200 $response
            }
            catch {
                Send-JsonResponse $context 400 @{
                    success = $false
                    error = $_.Exception.Message
                }
            }

            continue
        }

        if ($request.HttpMethod -eq "GET") {
            $relativePath = $path.TrimStart("/")

            if ([string]::IsNullOrWhiteSpace($relativePath)) {
                $relativePath = "index.html"
            }

            $publicRoot = (Resolve-Path "web\public").Path
            $filePath = [System.IO.Path]::GetFullPath(
                (Join-Path $publicRoot $relativePath)
            )

            if (
                $filePath.StartsWith(
                    $publicRoot,
                    [System.StringComparison]::OrdinalIgnoreCase
                ) -and
                (Test-Path -LiteralPath $filePath -PathType Leaf)
            ) {
                $bytes = [System.IO.File]::ReadAllBytes($filePath)
                $context.Response.StatusCode = 200

                switch ([System.IO.Path]::GetExtension($filePath).ToLowerInvariant()) {
                    ".html" { $context.Response.ContentType = "text/html; charset=utf-8" }
                    ".css" { $context.Response.ContentType = "text/css; charset=utf-8" }
                    ".js" { $context.Response.ContentType = "application/javascript; charset=utf-8" }
                    ".wasm" { $context.Response.ContentType = "application/wasm" }
                    default { $context.Response.ContentType = "application/octet-stream" }
                }
            }
            else {
                $bytes = [System.Text.Encoding]::UTF8.GetBytes("Not found")
                $context.Response.StatusCode = 404
                $context.Response.ContentType = "text/plain; charset=utf-8"
            }

            $context.Response.ContentLength64 = $bytes.Length
            $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
            $context.Response.Close()
            continue
        }

        Send-JsonResponse $context 405 @{
            success = $false
            error = "Method not allowed."
        }
    }
}
finally {
    $listener.Stop()
    $listener.Close()
}
