.global _start

.equ SYS_ioctl, 29
.equ SYS_nanosleep, 101
.equ SYS_exit, 93
.equ SYS_read, 63
.equ SYS_write, 64

.equ TCGETS, 0x5401
.equ TCSETS, 0x5402

.equ STDIN, 0
.equ STDOUT, 1

.equ ROW_LEN, 21
.equ MAX_SNAKE, 100

.text
_start:
	mov x0, #STDIN
	mov x1, #TCGETS
	ldr x2, =orig_termios
	mov x8, #SYS_ioctl
	svc #0

	ldr x0, =orig_termios
	ldr x1, =new_termios
	mov x2, #36
copy_loop:
	ldrb w3, [x0], #1
	strb w3, [x1], #1
	subs x2, x2, #1
	bne copy_loop

	ldr x0, =new_termios
	ldr w1, [x0, #12]
	mov w2, #10
	bic w1, w1, w2
	str w1, [x0, #12]

	mov w3, #0
	strb w3, [x0, #22]
	strb w3, [x0, #23]

	mov x0, #STDIN
	mov x1, #TCSETS
	ldr x2, =new_termios
	mov x8, #SYS_ioctl
	svc #0

	ldr x0, =snake_body_x
	mov w1, #12
	strb w1, [x0]
	mov w1, #11
	strb w1, [x0, #1]
	mov w1, #10
	strb w1, [x0, #2]

	ldr x0, =snake_body_y
	mov w1, #5
	strb w1, [x0]
	strb w1, [x0, #1]
	strb w1, [x0, #2]

read_loop:
	mov x0, #STDOUT
	ldr x1, =clear_screen
	mov x2, #clear_screen_len
	mov x8, #SYS_write
	svc #0

	ldr x0, =board
	ldr x1, =work_board
	mov x2, #board_len
copy_board_loop:
	ldrb w3, [x0], #1
	strb w3, [x1], #1
	subs x2, x2, #1
	bne copy_board_loop

	ldr x0, =snake_length
	ldrb w1, [x0]
	sub x1, x1, #1
	cmp x1, #0
	ble shift_done

	ldr x2, =snake_body_x
	ldr x3, =snake_body_y
	mov x4, x1

shift_loop:
	sub x5, x4, #1
	ldrb w6, [x2, x5]
	strb w6, [x2, x4]
	ldrb w6, [x3, x5]
	strb w6, [x3, x4]

	subs x4, x4, #1
	cmp x4, #0
	bgt shift_loop

shift_done:

	ldr x0, =direction
	ldrb w1, [x0]

	cmp w1, #0
	bne move_check_down
	ldr x0, =snake_body_y
	ldrb w2, [x0]
	sub w2, w2, #1
	strb w2, [x0]
	b move_done
move_check_down:
	cmp w1, #1
	bne move_check_left
	ldr x0, =snake_body_y
	ldrb w2, [x0]
	add w2, w2, #1
	strb w2, [x0]
	b move_done
move_check_left:
	cmp w1, #2
	bne move_check_right
	ldr x0, =snake_body_x
	ldrb w2, [x0]
	sub w2, w2, #1
	strb w2, [x0]
	b move_done
move_check_right:
	ldr x0, =snake_body_x
	ldrb w2, [x0]
	add w2, w2, #1
	strb w2, [x0]
move_done:

	ldr x0, =snake_body_x
	ldrb w1, [x0]
	cmp w1, #1
	blt game_over
	cmp w1, #18
	bgt game_over

	ldr x0, =snake_body_y
	ldrb w1, [x0]
	cmp w1, #1
	blt game_over
	cmp w1, #8
	bgt game_over

	mov x9, #0
	ldr x10, =snake_length
	ldrb w10, [x10]

draw_loop:
	cmp x9, x10
	bge draw_done

	ldr x0, =snake_body_y
	ldrb w4, [x0, x9]
	mov x5, #ROW_LEN
	mul x4, x4, x5

	ldr x0, =snake_body_x
	ldrb w5, [x0, x9]
	add x4, x4, x5

	ldr x6, =work_board
	add x6, x6, x4
	mov w7, #'o'
	strb w7, [x6]

	add x9, x9, #1
	b draw_loop

draw_done:

	mov x0, #STDOUT
	ldr x1, =work_board
	mov x2, #board_len
	mov x8, #SYS_write
	svc #0

	mov x0, #STDIN
	ldr x1, =keybuf
	mov x2, #1
	mov x8, #SYS_read
	svc #0

	cmp x0, #1
	bne no_key

	ldrb w2, [x1]

	cmp w2, #0x71
	beq end_loop

	cmp w2, #0x77
	bne check_s
	mov w3, #0
	ldr x0, =direction
	strb w3, [x0]
	b no_key
check_s:
	cmp w2, #0x73
	bne check_a
	mov x3, #1
	ldr x0, =direction
	strb w3, [x0]
	b no_key
check_a:
	cmp w2, #0x61
	bne check_d
	mov x3, #2
	ldr x0, =direction
	strb w3, [x0]
	b no_key
check_d:
	cmp w2, #0x64
	bne no_key
	mov w3, #3
	ldr x0, =direction
	strb w3, [x0]

no_key:
	ldr x0, =sleep_time
	mov x1, #0
	mov x8, #SYS_nanosleep
	svc #0

	b read_loop

game_over:
	mov x0, #STDOUT
	ldr x1, =game_over_msg
	mov x2, #game_over_len
	mov x8, #SYS_write
	svc #0

end_loop:

	mov x0, #STDIN
	mov x1, #TCSETS
	ldr x2, =orig_termios
	mov x8, #SYS_ioctl
	svc #0

	mov x0, #0
	mov x8, #93
	svc #0

.data
.align 3
orig_termios:
	.skip 36
new_termios:
	.skip 36
keybuf:
	.skip 1
sleep_time:
	.quad 0
	.quad 100000000
clear_screen:
	.ascii "\033[2J\033[H"
clear_screen_len = . - clear_screen

board:
	.ascii "####################\n"
    	.ascii "#..................#\n"
    	.ascii "#..................#\n"
    	.ascii "#..................#\n"
    	.ascii "#..................#\n"
    	.ascii "#..................#\n"
    	.ascii "#..................#\n"
    	.ascii "#..................#\n"
    	.ascii "#..................#\n"
    	.ascii "####################\n"
board_len = . - board

work_board:
	.skip board_len

snake_body_x:
	.skip MAX_SNAKE
snake_body_y:
	.skip MAX_SNAKE
snake_length:
	.byte 3
direction:
	.byte 3
game_over_msg:
	.ascii "\nGAME OVER\n"
game_over_len = . - game_over_msg


