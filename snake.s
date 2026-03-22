.global _start

.equ SYS_ioctl, 29
.equ SYS_nanosleep, 101
.equ SYS_exit, 93

.equ TCGETS, 0x5401
.equ TCSETS, 0x5402

.equ STDIN, 0

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

	ldr x0, =sleep_time
	mov x1, #0
	mov x8, #SYS_nanosleep
	svc #0

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
sleep_time:
	.quad 2
	.quad 0
