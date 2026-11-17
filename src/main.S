.intel_syntax noprefix

.section .rdata,"dr"

menu:
    .asciz "\n========================================\n             BINARY LAB\n========================================\n\n  1. Binary Encoder\n  2. Binary Decoder\n  3. ASCII Explorer\n  4. Bit Operations\n  5. Binary Challenges\n  0. Exit\n\nSelect a module: "

encoder_message:
    .asciz "\n[BINARY ENCODER]\nConvert text and numbers into binary representations.\n\nPress ENTER to return to the menu."

decoder_message:
    .asciz "\n[BINARY DECODER]\nDecode binary sequences into readable values.\n\nPress ENTER to return to the menu."

ascii_message:
    .asciz "\n[ASCII EXPLORER]\nExplore ASCII characters and their binary representations.\n\nPress ENTER to return to the menu."

operations_message:
    .asciz "\n[BIT OPERATIONS]\nExplore AND, OR, XOR, NOT and bit shifts.\n\nPress ENTER to return to the menu."

challenges_message:
    .asciz "\n[BINARY CHALLENGES]\nPractice binary logic through interactive challenges.\n\nPress ENTER to return to the menu."

invalid_message:
    .asciz "\nInvalid option. Try again.\n"

exit_message:
    .asciz "\nBINARY LAB closed.\n"

input_format:
    .asciz "%d"

.section .text

.globl main
.def main; .scl 2; .type 32; .endef

main:
    push rbp
    mov rbp, rsp
    sub rsp, 48

menu_loop:
    lea rcx, [rip + menu]
    xor eax, eax
    call printf

    lea rcx, [rip + input_format]
    lea rdx, [rbp - 8]
    xor eax, eax
    call scanf

    cmp eax, 1
    jne exit_program

    call getchar

    mov eax, DWORD PTR [rbp - 8]

    cmp eax, 0
    je exit_program

    cmp eax, 1
    je open_encoder

    cmp eax, 2
    je open_decoder

    cmp eax, 3
    je open_ascii

    cmp eax, 4
    je open_operations

    cmp eax, 5
    je open_challenges

    jmp invalid_option

open_encoder:
    lea rcx, [rip + encoder_message]
    jmp show_module

open_decoder:
    lea rcx, [rip + decoder_message]
    jmp show_module

open_ascii:
    lea rcx, [rip + ascii_message]
    jmp show_module

open_operations:
    lea rcx, [rip + operations_message]
    jmp show_module

open_challenges:
    lea rcx, [rip + challenges_message]
    jmp show_module

show_module:
    xor eax, eax
    call printf
    call getchar
    jmp menu_loop

invalid_option:
    lea rcx, [rip + invalid_message]
    xor eax, eax
    call printf
    jmp menu_loop

exit_program:
    lea rcx, [rip + exit_message]
    xor eax, eax
    call printf

    xor eax, eax
    add rsp, 48
    pop rbp
    ret

.extern printf
.extern scanf
.extern getchar
