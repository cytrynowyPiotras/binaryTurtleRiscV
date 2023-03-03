#-------------------------------------------------------------------------------
#author: Piotr Kowalski
#data : 2022.05.29
#description : RISC V writing a BMP file
#-------------------------------------------------------------------------------
#only 24-bits 600x50 pixels BMP files are supported
.eqv BMP_FILE_SIZE 90122
.eqv BYTES_PER_ROW 1800
.eqv BIN_FILE_SIZE 60

#used registers:
# a0 current x pos 10b
# a1 current y pos 6b
# a2 current pen color - 00RRGGBB
# a3 current direction
# a4 pen on/off (1/0)
# a5 next x value
# a6 next y value
# a7 moving distance
	.data
#space for the 600x50px 24-bits bmp image
.align 4
res:	.space 2

bin:	.space BIN_FILE_SIZE

image:	.space BMP_FILE_SIZE

binname: .asciz "commands.bin"

fname:	.asciz "source.bmp"
	.text
main:
	jal	read_bmp
	jal	read_bin
	li s0, 0 #set pos function
	li s1, 16384 #set direction function 0100 0000 0000 0000b
	li s2, 32768 #move function 1000 0000 0000 0000b
	li s3, 49152 #set pen function 1100 0000 0000 0000b
	la t0, bin
	li s4, 60
	j loadWord


loadWord:
	addi s4, s4, -1
	beqz s4, save_bmp
	lbu t1, (t0)
	slli t1, t1, 8
	addi t0, t0, 1
	lbu t2, (t0)
	add t1, t1, t2
	li t3, 0xC000 #1100 0000 0000 0000b
	and t2, t3, t1
	beq t2, s0, setPos
	beq t2, s1, setDir
	beq t2, s2, move
	beq t2, s3, setPen
setDir:
	li t3, 0x0003
	and t2, t3, t1
	mv a3, t2
	addi t0, t0, 1
	jal	loadWord

setPos:
	addi s4, s4, -1
	addi t0, t0, 1
	lbu t1, (t0)
	slli t1, t1, 8
	addi t0, t0, 1
	lbu t2, (t0)
	add t1, t1, t2

	li t3, 0xFC00 # 1111 1100 0000 0000b
	and t4, t3, t1
	srli a1, t4, 10
	mv a6, a1

	li t3, 0x03FF
	and a0, t3, t1
	mv a5, a0

	addi t0, t0, 1
	jal	loadWord
move:
	addi t0, t0, 1
	li t3, 0x3FF
	and a7, t3, t1

	li t3, 0
	beq a3, t3, DataMoveRight
	li t3, 1
	beq a3, t3, DataMoveUp
	li t3, 2
	beq a3, t3, DataMoveLeft
	li t3, 3
	beq a3, t3, DataMoveDown
# ============================================================================
DataMoveLeft:
	sub a5, a0, a7
	li t6, 1
	bltu a5, t6, reduceLeft
	beqz a4, updateLeft
	j paintLeft

reduceLeft:
	li a5, 1
	beqz a4, updateLeft
	j paintLeft

updateLeft:
	mv a0, a5
	j loadWord #if marker off

paintLeft:
	bne a5, a0 callLeft
	beq a5, a0 loadWord

callLeft:
	jal put_pixel
	addi a0, a0, -1
	j paintLeft
# ============================================================================
DataMoveRight:
	add a5, a0, a7
	li t6, 599
	bltu t6, a5, reduceRight
	beqz a4, updateRight
	j paintRight

reduceRight:
	li a5, 599
	beqz a4, updateRight
	j paintRight

updateRight:
	mv a0, a5
	j loadWord #if marker off

paintRight:
	bne a5, a0 callRight
	beq a5, a0 loadWord

callRight:
	jal put_pixel
	addi a0, a0, 1
	j paintRight
# ============================================================================
DataMoveDown:
	sub a6, a1, a7
	li t6, 1
	bltu a6, t6,  reduceDown
	beqz a4, updateDown
	j paintDown

reduceDown:
	li a6, 1
	beqz a4, updateDown
	j paintDown

updateDown:
	mv a1, a6
	j loadWord #if marker off

paintDown:
	bne a6, a1 callDown
	beq a6, a1 loadWord

callDown:
	jal put_pixel
	addi a1, a1, -1
	j paintDown
# ============================================================================
DataMoveUp:
	add a6, a1, a7
	li t6, 50
	bltu t6, a6, reduceUp
	beqz a4, updateUp
	j paintUp

reduceUp:
	li a6, 49
	beqz a4, updateUp
	j paintUp

updateUp:
	mv a1, a6
	j loadWord #if marker off

paintUp:
	bne a6, a1 callUp
	beq a6, a1 loadWord

callUp:
	jal put_pixel
	addi a1, a1, 1
	j paintUp

# ============================================================================

setPen:
	li t3, 0x2000 # 0010 0000 0000 0000b
	and t2, t3, t1
	srli a4, t2, 13 #sets pen

	li t6, 0x000F
	and t5, t1, t6 #t5 holds r halfbyte
	mv a2, t5
	slli a2, a2, 8

	li t6, 0x00F0
	and t5, t1, t6
	srli t5, t5, 4 #t5 holds g halfbyte
	add a2, a2, t5
	slli a2, a2, 8

	li t6 0x0F00
	and t5, t1, t6 #t5 holds b halfbyte
	srli t5, t5, 8
	add a2, a2, t5
	slli a2, a2, 4

	addi t0, t0, 1
	jal loadWord



# ============================================================================
put_pixel:
#description:
#	sets the color of specified pixel
#arguments:
#	a0 - x coordinate
#	a1 - y coordinate - (0,0) - bottom left corner
#	a2 - 0RGB - pixel color
#return value: none
	mv t5, a0
	mv t6, a2

	la t1, image	#adress of file offset to pixel array
	addi t1,t1,10
	lw t2, (t1)		#file offset to pixel array in $t2
	la t1, image		#adress of bitmap
	add t2, t1, t2	#adress of pixel array in $t2

	#pixel address calculation
	li t4,BYTES_PER_ROW
	mul t1, a1, t4 #t1= y*BYTES_PER_ROW
	mv t3, a0
	slli t5, t5, 1
	add t3, t3, t5	#$t3= 3*x
	add t1, t1, t3	#$t1 = 3x + y*BYTES_PER_ROW
	add t2, t2, t1	#pixel address

	#set new color
	sb t6,(t2)		#store B
	srli t6,t6,8
	sb t6,1(t2)		#store G
	srli t6,t6,8
	sb t6,2(t2)		#store R

	ret

# ============================================================================

read_bin:
#description:
#	reads the contents of a bin file into memory
#arguments:
#	none
#return value: none
	addi sp, sp, -4		#push $s1
	sw s1, 0(sp)
#open file
	li a7, 1024
        la a0, binname		#file name
        li a1, 0		#flags: 0-read file
        ecall
	mv s1, a0      # save the file descriptor

#check for errors - if the file was opened
#...

#read file
	li a7, 63
	mv a0, s1
	la a1, bin
	li a2, BIN_FILE_SIZE
	ecall

#close file
	li a7, 57
	mv a0, s1
        ecall

	lw s1, 0(sp)		#restore (pop) s1
	addi sp, sp, 4
	jr ra


# ============================================================================
read_bmp:
#description:
#	reads the contents of a bmp file into memory
#arguments:
#	none
#return value: none
	addi sp, sp, -4		#push $s1
	sw s1, 0(sp)
#open file
	li a7, 1024
        la a0, fname		#file name
        li a1, 0		#flags: 0-read file
        ecall
	mv s1, a0      # save the file descriptor

#check for errors - if the file was opened
#...

#read file
	li a7, 63
	mv a0, s1
	la a1, image
	li a2, BMP_FILE_SIZE
	ecall

#close file
	li a7, 57
	mv a0, s1
        ecall

	lw s1, 0(sp)		#restore (pop) s1
	addi sp, sp, 4
	jr ra

# ============================================================================
save_bmp:
#description:
#	saves bmp file stored in memory to a file
#arguments:
#	none
#return value: none
	addi sp, sp, -4		#push s1
	sw s1, (sp)
#open file
	li a7, 1024
        la a0, fname		#file name
        li a1, 1		#flags: 1-write file
        ecall
	mv s1, a0      # save the file descriptor


#save file
	li a7, 64
	mv a0, s1
	la a1, image
	li a2, BMP_FILE_SIZE
	ecall

#close file
	li a7, 57
	mv a0, s1
        ecall

	lw s1, (sp)		#restore (pop) $s1
	addi sp, sp, 4
	j exit


# ============================================================================

exit:	li 	a7,10		#Terminate the program
	ecall
