################ CSC258H1F Winter 2024 Assembly Final Project ##################
# This file contains our implementation of Tetris.
# This is a copy of the original submission of the project where some personal info has been refactored (ex, Student number).
#
# Made by: Gunwoo Joung (Kyle)
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       16
# - Unit height in pixels:      16
# - Display width in pixels:    512
# - Display height in pixels:   512
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

	.data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
	.word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
	.word 0xffff0000

GAME_OVER:
	.word 66,67,68,69,70,98,130,162,194,226,258,259,260,261,262,230,198,197,199,			# G: 19
	75,76,77,110,142,174,206,238,270,106,138,171,172,173,170,202,234,266,				# A: 18
	81,82,86,87,113,115,117,145,148,151,177,209,241,273,215,183,247,279,119,			# M: 19
	89,90,91,92,93,121,153,185,186,187,188,189,217,249,281,282,283,284,285,				# E: 19
	322,323,324,325,326,358,390,422,454,486,518,517,516,515,514,482,450,418,386,354,		# O: 20
	329,361,393,425,457,490,523,492,461,429,397,365,333,						# V: 13
	336, 337, 338, 339, 340, 368, 400, 432, 433, 434, 435, 436, 464, 496, 528, 529, 530, 531, 532,	# E; 19
	343,344,345,346,347,375,407,439,471,503,535,440,441,442,443,411,379,473,506,539			# R: 20
	349,381,413,445,477,541,									# !: 6
	610,611,612,613,614,645,676,707,738,739,740,741,742,648, 712					# Z:: 15
	618,619,620,621,653,685,684,683,682,650,714,746,716,749,					# R: 14
	623,624,625,655,687,688,689,719,751,752,753,							# E: 11
	627,628,629,660,692,724,756,									# T: 7
	631, 632, 633, 634, 666, 698, 697, 696, 695, 663, 727, 759, 729, 762,				# R: 14
	636,638,669,701,733,765,									# Y: 6
	834,867,900,869,838,931,962,933,966, 872,936,							# X:: 11
	842,843,844,845,874,906,938,970,971,972,973,974,941,909,877,					# Q: 15
	848,850,880,882,912,914,944,946,976,977,978,							# U: 11
	852,853,854,885,917,949,980,981,982,								# I: 9
	856,857,858,889,921,953,985									# T: 7
	
GAME_OVER_SIZE:
	.word 273

PAUSE:
	.word 66,67,68,69,98,101,130,133,162,163,164,165,194,226,72,73,103,135,167,199,231,168,169,106,138,170,202,
	234,76,79,108,111,140,143,172,175,204,207,236,237,238,239,81,82,83,84,113,145,177,178,179,180,212,241,242,
	243,244,86,87,88,118,150,182,183,184,214,246,247,248,90,91,92,122,125,154,157,186,189,218,221,250,251,252,	# paused
	386,387,388,418,420,450,451,452,482,514,390,391,392,422,424,454,455,486,488,518,520,394,395,396,426,458,459,
	460,490,522,523,524,398,399,400,430,462,463,464,496,526,527,528,402,403,404,434,466,467,468,500,532,531,530,
	408,409,410,440,442,472,473,474,504,536,578,579,580,611,643,675,707,582,583,584,614,616,646,648,678,680,710,
	711,712,770,771,772,802,804,834,835,866,868,898,900,774,775,776,806,838,839,840,870,902,903,904,778,779,780,
	810,842,843,844,876,906,907,908,782,784,814,816,846,848,878,880,910,911,912,786,818,819,850,882,914,852,821,
	790,822,854,886,918,792,793,794,824,856,857,858,888,920,921,922							# press p to resume
PAUSE_SIZE:
	.word 234

##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main

# Run the Tetris game.
main:
	# Initialize saved varaibles for the game
	# set $s1 to stack pointer for future reference
	add $s1, $zero, $sp
	
reset_to:
	
	add $sp, $s1, $zero		# set sp to the correct address
	# time: time before last gravity pull (roughly a second)
	addi $s0, $zero, 0x0
	# set stack memory of the playable field to 0.
	add $t1, $zero, $zero		# $t1 = index
	addi $t2, $zero, 200		# $t2: repeated $t2 times

initialize_stack:

	beq $t1, $t2, spawn_tetromino	# end of loop (index = 200)
	addi $t3, $zero, 0x0		# load 0
	sw $t3, 0($sp)
	addi $sp, $sp, -4		
	addi $t1, $t1, 1		# increment
	j initialize_stack
	
spawn_tetromino:
	jal find_completed_line
	add $sp, $s1, $zero
	# the middle of a tetromino (this is the axis we rotate on)
	addi $s2, $sp, -20
	# initialize the rest of the 3 units
	add $s3, $zero, $s2
	add $s4, $zero, $s2
	add $s5, $zero, $s2
	# generate a random number between 0 and 6 inclusive
	addi $v0, $zero, 42
	addi $a0, $zero 1
	addi $a1, $zero,7
	syscall

	# branch to the corresponding tetromino (1 to 7 inclusive)
	addi $t0, $a0, 1
	addi $t1, $zero, 1
	beq $t0, $t1, tetro_i
	addi $t0, $a0, 1
	addi $t1, $zero, 2
	beq $t0, $t1, tetro_j
	addi $t0, $a0, 1
	addi $t1, $zero, 3
	beq $t0, $t1, tetro_l
	addi $t0, $a0, 1
	addi $t1, $zero, 4
	beq $t0, $t1, tetro_o
	addi $t0, $a0, 1
	addi $t1, $zero, 5
	beq $t0, $t1, tetro_s
	addi $t0, $a0, 1
	addi $t1, $zero, 6
	beq $t0, $t1, tetro_t
	addi $t0, $a0, 1
	addi $t1, $zero, 7
	beq $t0, $t1, tetro_z
	
tetro_i:
	addi $a0, $zero, -20		# row 0, column 5 (middle)
	addi $a1, $zero, -24		# row 0, column 6
	addi $a2, $zero, -16		# row 0, column 4
	addi $a3, $zero, -12		# row 0, column 3
	jal collision_unit		# if $t9 == 0, there is no collision
	beq $t9, $zero, game_loop	# error check
	j game_over			# if tetromino cannot be drawn, end game
	
tetro_j:
	addi $a0, $zero, -20		# row 0, column 5 (middle)
	addi $a1, $zero, -24		# row 0, column 6
	addi $a2, $zero, -16		# row 0, column 4
	addi $a3, $zero, -64		# row 1, column 6
	jal collision_unit		# if $t9 == 0, there is no collision
	beq $t9, $zero, game_loop	# error check
	j game_over			# if tetromino cannot be drawn, end game
tetro_l:
	addi $a0, $zero, -20		# row 0, column 5 (middle)
	addi $a1, $zero, -24		# row 0, column 6
	addi $a2, $zero, -16		# row 0, column 4
	addi $a3, $zero, -56		# row 0, column 4
	jal collision_unit		# if $t9 == 0, there is no collision
	beq $t9, $zero, game_loop	# error check
	j game_over			# if tetromino cannot be drawn, end game
tetro_o:
	addi $a0, $zero, -20		# row 0, column 5 (middle)
	addi $a1, $zero, -60		# row 1, column 5
	addi $a2, $zero, -16		# row 0, column 4
	addi $a3, $zero, -56		# row 1, column 4
	jal collision_unit		# if $t9 == 0, there is no collision
	beq $t9, $zero, game_loop	# error check
	j game_over			# if tetromino cannot be drawn, end game
tetro_s:
	addi $a0, $zero, -20		# row 0, column 5 (middle)
	addi $a1, $zero, -24		# row 0, column 6
	addi $a2, $zero, -60		# row 1, column 5
	addi $a3, $zero, -56		# row 1, column 4
	jal collision_unit		# if $t9 == 0, there is no collision
	beq $t9, $zero, game_loop	# error check
	j game_over			# if tetromino cannot be drawn, end game
tetro_t:
	addi $a0, $zero, -20		# row 0, column 5 (middle)
	addi $a1, $zero, -24		# row 0, column 6
	addi $a2, $zero, -16		# row 0, column 3
	addi $a3, $zero, -60		# row 1, column 5
	jal collision_unit		# if $t9 == 0, there is no collision
	beq $t9, $zero, game_loop	# error check
	j game_over			# if tetromino cannot be drawn, end game
tetro_z:
	addi $a0, $zero, -20		# row 0, column 5 (middle)
	addi $a1, $zero, -60		# row 1, column 5
	addi $a2, $zero, -64		# row 1, column 6
	addi $a3, $zero, -16		# row 0, column 4
	jal collision_unit		# if $t9 == 0, there is no collision
	beq $t9, $zero, game_loop	# error check
	j game_over			# if tetromino cannot be drawn, end game

game_loop:
# 1a. Check if key has been pressed
	lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
	lw $t8, 0($t0)                  # Load first word from keyboard
	beq $t8, 1, key_pressed		# If key is pressed, go to key_pressed
	j after_user_input		# else, skip checking for which key

# 1b. Check which key has been pressed
key_pressed:
	lw $a0, 4($t0)			# load keybaord value to function param
	# Interface controls
	beq $a0, 0x7A, keypress_z	# key z (retry)
	beq $a0, 0x78, keypress_x	# key x (quit)
	beq $a0, 0x70 keypress_p	# key p (pause)
	# Game controls (WASD)
	beq $a0, 0x77, keypress_w	# key w (rotate)
	beq $a0, 0x61, keypress_a	# key a (left)
	beq $a0, 0x73, keypress_s	# key s (down)
	beq $a0, 0x64, keypress_d	# key d (right)
	beq $a0, 0x20, keypress_space	# key space (place furthest down)
	# when reached, invalid key input
	j after_user_input		

# 2a. Check for collisions
keypress_w:
	lw $t0, 0($s2)			# value of the address (type)
	sub $a0, $s2, $s1		# middle is unchanged, get the offset from $s1
	
	sub $t5, $s3, $s2		# offset from $s2 (middle)
	jal rotate_unit
	add $a1, $t5, $a0		# total offset from $s1
	
	sub $t5, $s4, $s2		# offset from $s2
	jal rotate_unit
	add $a2, $t5, $a0		# total offset from $s1
	
	sub $t5, $s5, $s2		# offset from $s2
	jal rotate_unit
	add $a3, $t5, $a0		# total offset from $s1
	
	# check floor collision
	addi $t4, $zero, -800		# if there are units with more than or equal to 800, then collision with floor
	div $a0, $t4
	mflo $t5
	addi $t6, $zero, 1
	beq $t6, $t5, after_user_input	# collided with floor, return early
	div $a1, $t4
	mflo $t5
	addi $t6, $zero, 1
	beq $t6, $t5, after_user_input	# collided with floor, return early
	div $a2, $t4
	mflo $t5
	addi $t6, $zero, 1
	beq $t6, $t5, after_user_input	# collided with floor, return early
	div $a3, $t4
	mflo $t5
	addi $t6, $zero, 1
	beq $t6, $t5, after_user_input	# collided with floor, return early
	
	# check ceiling collision
	bgt $a0, 0, after_user_input
	bgt $a1, 0, after_user_input
	bgt $a2, 0, after_user_input
	bgt $a3, 0, after_user_input
	
	addi $t4, $zero, -40		# units before the left wall offsets are a multiple of 40 or is 0.
	div $a1, $t4
	mfhi $t5
	addi $t4, $zero, -40		# units before the left wall offsets are a multiple of 40 or is 0.
	div $a2, $t4
	mfhi $t6
	addi $t4, $zero, -40		# units before the left wall offsets are a multiple of 40 or is 0.
	div $a3, $t4
	mfhi $t7
	addi $t4, $zero, -40		# units before the left wall offsets are a multiple of 40 or is 0.
	div $a0, $t4
	mfhi $t4
	
	addi $t3, $zero, 0
	beq $t3, $t5, first_unit_left
	addi $t3, $zero, -36
	beq $t3, $t5, first_unit_right
	# neither
	addi $t3, $zero, 0
	beq $t3, $t6, second_unit_left
	addi $t3, $zero, -36
	beq $t3, $t6, second_unit_right
	# neither
	addi $t3, $zero, 0
	beq $t3, $t7, third_unit_left
	addi $t3, $zero, -36
	beq $t3, $t7, third_unit_right
	# neither, then all good
	j rotate_collision_checked

first_unit_left:
	addi $t3, $zero, -36
	beq $t3, $t6, after_user_input
	j second_unit_left
	
first_unit_right:
	addi $t3, $zero, 0
	beq $t3, $t6, after_user_input
	j second_unit_right
	
second_unit_left:
	addi $t3, $zero, -36
	beq $t3, $t7, after_user_input
	j third_unit_left

second_unit_right:
	addi $t3, $zero, 0
	beq $t3, $t7, after_user_input
	j third_unit_right
	
third_unit_left:
	addi $t3, $zero, -36
	beq $t3, $t4, after_user_input
	j rotate_collision_checked
	
third_unit_right:
	addi $t3, $zero, 0
	beq $t3, $t4, after_user_input
	j rotate_collision_checked

rotate_collision_checked:
	
	jal collision_unit			# if $t9 == 0, there is no collision
	j after_user_input

# Precondition: $t5 is the offset from $s2 (middle)
# Returns: $t5 as the rotated (clock_wise) offset from $s2 (middle)
rotate_unit:
	# there are 10 possible positions
	addi $t4, $zero, -8
	beq $t5, $t4, rotate_neg_8
	addi $t4, $zero, -80
	beq $t5, $t4, rotate_neg_80
	addi $t4, $zero, 8
	beq $t5, $t4, rotate_8
	addi $t4, $zero, 80
	beq $t5, $t4, rotate_80
	addi $t4, $zero, 36
	beq $t5, $t4, rotate_36
	addi $t4, $zero, -44
	beq $t5, $t4, rotate_neg_44
	addi $t4, $zero, -36
	beq $t5, $t4, rotate_neg_36
	addi $t4, $zero, 44
	beq $t5, $t4, rotate_44
	addi $t4, $zero, -4
	beq $t5, $t4, rotate_neg_4
	addi $t4, $zero, -40
	beq $t5, $t4, rotate_neg_40
	addi $t4, $zero, 4
	beq $t5, $t4, rotate_4
	addi $t4, $zero, 40
	beq $t5, $t4, rotate_40
	jr $ra

rotate_neg_8:
	addi $t5, $zero, -80
	jr $ra
rotate_neg_80:
	addi $t5, $zero, 8
	jr $ra
rotate_8:
	addi $t5, $zero, 80
	jr $ra
rotate_80:
	addi $t5, $zero, -8
	jr $ra
rotate_36:
	addi $t5, $zero, -44
	jr $ra
rotate_neg_44:
	addi $t5, $zero, -36
	jr $ra
rotate_neg_36:
	addi $t5, $zero, 44
	jr $ra
rotate_44:
	addi $t5, $zero, 36
	jr $ra
rotate_neg_4:
	addi $t5, $zero, -40
	jr $ra
rotate_neg_40:
	addi $t5, $zero, 4
	jr $ra
rotate_4:
	addi $t5, $zero, 40
	jr $ra
rotate_40:
	addi $t5, $zero, -4
	jr $ra

keypress_a:
	lw $t0, 0($s2)			# value of the address (type)
	sub $a0, $s2, $s1		# offset from $s1
	sub $a1, $s3, $s1		# offset from $s1
	sub $a2, $s4, $s1		# offset from $s1
	sub $a3, $s5, $s1		# offset from $s1
	
	# check left wall collision
	addi $t4, $zero, -40		# units before the left wall offsets are a multiple of 40 or is 0.
	div $a0, $t4
	mfhi $t5
	add $t6, $zero, $zero
	beq $t6, $t5, after_user_input	# collided with wall, return early
	div $a1, $t4
	mfhi $t5
	add $t6, $zero, $zero
	beq $t6, $t5, after_user_input	# collided with wall, return early
	div $a2, $t4
	mfhi $t5
	add $t6, $zero, $zero
	beq $t6, $t5, after_user_input	# collided with wall, return early
	div $a3, $t4
	mfhi $t5
	add $t6, $zero, $zero
	beq $t6, $t5, after_user_input	# collided with wall, return early
	
	# apply shift parameters for collision_unit
	addi $a0, $a0, 4		# (middle)
	addi $a1, $a1, 4		# +4 decreases unit by 1, which moves it left by 1
	addi $a2, $a2, 4
	addi $a3, $a3, 4
	jal collision_unit			# if $t9 == 0, there is no collision
	j after_user_input

sr_remove:
	sw $t0, 0($sp)
	j after_user_input

keypress_space:
	jal check_floor_and_setup_collision_down
	jal collision_unit		# if $t9 == 0, there is no collision
	beq $t9, $zero, keypress_space	# if there is no collision, repeat
	j spawn_tetromino		# if there is collision, set the piece down

keypress_s:
	jal check_floor_and_setup_collision_down
	jal collision_unit		# if $t9 == 0, there is no collision
	beq $t9, $zero, after_user_input# if there is no collision, continue
	j spawn_tetromino		# if there is collision, user is settling down the piece.

check_floor_and_setup_collision_down:
	add $s0, $zero, $zero		# reset gravity count

	lw $t0, 0($s2)			# value of the address (type)
	sub $a0, $s2, $s1		# offset from $s1
	sub $a1, $s3, $s1		# offset from $s1
	sub $a2, $s4, $s1		# offset from $s1
	sub $a3, $s5, $s1		# offset from $s1
	
	# check floor collision
	addi $t4, $zero, -760		# units before the floor offsets are at least of 760 and at most 796
	div $a0, $t4
	mflo $t5
	addi $t6, $zero, 1
	beq $t6, $t5, spawn_tetromino	# collided with floor, return early
	div $a1, $t4
	mflo $t5
	addi $t6, $zero, 1
	beq $t6, $t5, spawn_tetromino	# collided with floor, return early
	div $a2, $t4
	mflo $t5
	addi $t6, $zero, 1
	beq $t6, $t5, spawn_tetromino	# collided with floor, return early
	div $a3, $t4
	mflo $t5
	addi $t6, $zero, 1
	beq $t6, $t5, spawn_tetromino	# collided with floor, return early
	
	# apply shift parameters for collision_unit
	addi $a0, $a0, -40		# (middle)
	addi $a1, $a1, -40		# -40 increases unit by 10, which moves it down by 1
	addi $a2, $a2, -40		
	addi $a3, $a3, -40
	jr $ra

keypress_d:
	lw $t0, 0($s2)			# value of the address (type)
	sub $a0, $s2, $s1		# offset from $s1
	sub $a1, $s3, $s1		# offset from $s1
	sub $a2, $s4, $s1		# offset from $s1
	sub $a3, $s5, $s1		# offset from $s1
	
	# check right wall collision
	addi $t4, $zero, -40		# first get the column offset
	div $a0, $t4
	mfhi $t7
	addi $t4, $zero, 36		# units before the right wall offsets are a multiple of 36
	div $t7, $t4
	mfhi $t5
	add $t6, $zero, $zero
	beq $t7, $t6, key_d_edge_one	# exception, if $a0 == 0, then no collision.
	beq $t6, $t5, after_user_input	# collided with wall, return early
	
key_d_edge_one:
	addi $t4, $zero, -40		# first get the column offset
	div $a1, $t4
	mfhi $t7
	addi $t4, $zero, 36		# units before the right wall offsets are a multiple of 36
	div $t7, $t4
	mfhi $t5
	add $t6, $zero, $zero
	beq $t7, $t6, key_d_edge_two	# exception, if $a0 == 0, then no collision.
	beq $t6, $t5, after_user_input	# collided with wall, return early
	
key_d_edge_two:
	addi $t4, $zero, -40		# first get the column offset
	div $a2, $t4
	mfhi $t7
	addi $t4, $zero, 36		# units before the right wall offsets are a multiple of 36
	div $t7, $t4
	mfhi $t5
	add $t6, $zero, $zero
	beq $t7, $t6, key_d_edge_three	# exception, if $a0 == 0, then no collision.
	beq $t6, $t5, after_user_input	# collided with wall, return early

key_d_edge_three:
	addi $t4, $zero, -40		# first get the column offset
	div $a3, $t4
	mfhi $t7
	addi $t4, $zero, 36		# units before the right wall offsets are a multiple of 36
	div $t7, $t4
	mfhi $t5
	add $t6, $zero, $zero
	beq $t7, $t6, key_d_edge_four	# exception, if $a0 == 0, then no collision.
	beq $t6, $t5, after_user_input	# collided with wall, return early
	
key_d_edge_four:
	# apply shift parameters for collision_unit
	addi $a0, $a0, -4		# (middle)
	addi $a1, $a1, -4		# -4 increases unit by 1, which moves it right by 1
	addi $a2, $a2, -4		
	addi $a3, $a3, -4
	jal collision_unit			# if $t9 == 0, there is no collision
	j after_user_input

keypress_z:
	j reset_to

keypress_p:
	jal paused
	j after_user_input

keypress_x:
	addi $v0, $zero, 10		# Quit gracefully
	syscall
	
############################################################
############################################################

after_user_input:
	# gravity pull around every second (not exact)
	beq $s0, 50, keypress_s
	addi $s0, $s0, 1

# 3. Draw the screen
	lw $t0, ADDR_DSPL		# $t0 = base address for display
	add $t1, $zero, $zero		# $t1 = index
	addi $t2, $zero, 1024		# $t2: draw_background repeated $t2 times

draw_background:
	beq $t1, $t2, sleep		# end of loop (index = 1024)
	jal draw_tile			# draw a tile
	addi $t1, $t1, 1		# increment index
	addi $t0, $t0, 4		# increment address
	j draw_background

# Precondition: $t0 = address of the display of the index, $t1 = index of the loop
draw_tile:
	addi $t3, $zero, 0x20		# load 32 for the divisor
	div $t1, $t3		# division
	mflo $t8		# $t8 = row in the display
	mfhi $t9		# $t9 = column in the display
	# check the row idex
	slti $t3, $t8, 2  		# $t3 = ($s < 2)
	bgtz $t3, background_tile	# row < 2
	slti $t3, $t8, 22  		# $t3 = (2 <= $s < 22)
	blez $t3, background_tile	# 23 <= row
	# else 23 <= row index; check column
	slti $t3, $t9, 2  		# $t3 = ($s < 2)
	bgtz $t3, background_tile	# column < 2
	slti $t3, $t9, 12  		# $t3 = (2 <= $s < 12)
	blez $t3, background_tile	# 23 <= column
	
	# if all else, then it is a playable tile
	j playable_tile

playable_tile:
	# Draw from stack memory if not empty (= 0)
	# $t8 = 2 to 21, $t9 = 2 to 11; convert them so it starts at index 0
	addi $t8, $t8, -2
	addi $t9, $t9, -2
	# convert to address offset.
	addi $t7, $zero, 40
	mult $t8, $t7
	mflo $t8			# $t8 = offset of rows
	addi $t7, $zero, 4
	mult $t9, $t7
	mflo $t9			# $t9 = offset of columns
	add $t8, $t8, $t9		
	sub $t8, $zero, $t8 		# $t8 = total offset of address
	add $sp, $s1, $t8		# $sp = address in the stack of the unit
	# now load the unit and draw accordingly
	lw $t8, 0($sp)
	addi $t9, $zero, 1		# set $t9 = 1 for later comparison
	slt $t7, $zero, $t8		# $t7 = (0 < unit value), no collision at 0 < 0, which returns 0
	beq $t9, $t7, draw_type 	# $t7 == 1, then draw
	j draw_checkered
	
draw_type:
	addi $t9, $zero, 1
	beq $t8, $t9, draw_i
	addi $t9, $zero, 2
	beq $t8, $t9, draw_j
	addi $t9, $zero, 3
	beq $t8, $t9, draw_l
	addi $t9, $zero, 4
	beq $t8, $t9, draw_o
	addi $t9, $zero, 5
	beq $t8, $t9, draw_s
	addi $t9, $zero, 6
	beq $t8, $t9, draw_t
	addi $t9, $zero, 7
	beq $t8, $t9, draw_z
	
draw_i:
	addi $t5, $zero, 0x009edb	# light blue
	sw $t5, 0($t0)			# draw
	jr $ra

draw_j:
	addi $t5, $zero, 0x0000ff	# blue
	sw $t5, 0($t0)			# draw
	jr $ra

draw_l:
	addi $t5, $zero, 0xed872d	# orange
	sw $t5, 0($t0)			# draw
	jr $ra

draw_o:
	addi $t5, $zero, 0xffff00	# yellow
	sw $t5, 0($t0)			# draw
	jr $ra

draw_s:
	addi $t5, $zero, 0x00ff00	# green
	sw $t5, 0($t0)			# draw
	jr $ra

draw_t:
	addi $t5, $zero, 0x800080	# purple
	sw $t5, 0($t0)			# draw
	jr $ra

draw_z:
	addi $t5, $zero, 0xff0000	# red
	sw $t5, 0($t0)			# draw
	jr $ra
	
draw_checkered:
	# load value again since it was overwritten above
	addi $t3, $zero, 0x20		# load 32 for the divisor
	div $t1, $t3		# division
	mflo $t8		# $t8 = row in the display
	mfhi $t9		# $t9 = column in the display
	
	addi $t3, $zero, 0x2		# load 2 for the divisor
	div $t8, $t3			# division
	mfhi $t8			# remainder: $t9: 1 -> light grey, 0 -> grey
	div $t9, $t3			# division
	mfhi $t9			# remainder: $t9: 1 -> light grey, 0 -> grey
	# xor will give the checkered pattern
	xor $t3, $t8, $t9
	addi $t4, $zero, 0x1
	beq $t3, $t4, draw_grey
	# else draw light-grey
	addi $t5, $zero, 0xb0b0b0	# tile light-grey
	sw $t5, 0($t0)			# draw
	jr $ra

draw_grey:
	addi $t5, $zero, 0xd0d0d0	# tile grey
	sw $t5, 0($t0)			# draw
	jr $ra

background_tile:
	addi $t5, $zero, 0x808080	# background grey
	sw $t5, 0($t0)			# draw
	jr $ra

# 4. Sleep
sleep:
	addi $v0, $zero, 32		# sleep syscall
	addi $a0, $zero, 32		# 31.25 fps
	syscall

#5. Go back to 1
	addi $s0, $s0, 1		# increment
	j game_loop

############################################################
############################################################

# Collision function
# Precondition: $a0 to $a3 contains the offset of the address of the tetromino
# Precondition: $t0 is the value to be inserted if there is no collision
# Must be called with (jal collision).
# Returns: $t9 = (0 if there is no collision)
collision_unit:
	addi $t8, $zero, 1		# set $t8 = 1 for later comparison	
	# check for collision
	add $sp, $s1, $a0
	# check if there is a collision between itself (then no collision)
	beq $s2, $sp, col_next_one
	beq $s3, $sp, col_next_one
	beq $s4, $sp, col_next_one
	beq $s5, $sp, col_next_one
	# if not check if there is a collision with other units
	lw $t9, 0($sp)
	slt $t9, $zero, $t9		# $t9 = (0 < unit value), no collision at 0 < 0, which returns 0
	beq $t9, $t8, collision_return 	# $t9 == 1, then return

col_next_one:
	add $sp, $s1, $a1
	# check if there is a collision between itself (then no collision)
	beq $s2, $sp, col_next_two
	beq $s3, $sp, col_next_two
	beq $s4, $sp, col_next_two
	beq $s5, $sp, col_next_two
	# if not check if there is a collision with other units
	lw $t9, 0($sp)
	slt $t9, $zero, $t9		# $t9 = (0 < unit value), no collision at 0 < 0, which returns 0
	beq $t9, $t8, collision_return 	# $t9 == 1, then return

col_next_two:
	add $sp, $s1, $a2
	# check if there is a collision between itself (then no collision)
	beq $s2, $sp, col_next_three
	beq $s3, $sp, col_next_three
	beq $s4, $sp, col_next_three
	beq $s5, $sp, col_next_three
	# if not check if there is a collision with other units
	lw $t9, 0($sp)
	slt $t9, $zero, $t9		# $t9 = (0 < unit value), no collision at 0 < 0, which returns 0
	beq $t9, $t8, collision_return 	# $t9 == 1, then return

col_next_three:
	add $sp, $s1, $a3
	# check if there is a collision between itself (then no collision)
	beq $s2, $sp, col_next_four
	beq $s3, $sp, col_next_four
	beq $s4, $sp, col_next_four
	beq $s5, $sp, col_next_four
	# if not check if there is a collision with other units
	lw $t9, 0($sp)
	slt $t9, $zero, $t9		# $t9 = (0 < unit value), no collision at 0 < 0, which returns 0
	beq $t9, $t8, collision_return 	# $t9 == 1, then return
	
col_next_four:
	# if not early returned,then:
# 2b. Update locations
	# remove old units
	sw $zero, 0($s2)
	sw $zero, 0($s3)
	sw $zero, 0($s4)
	sw $zero, 0($s5)
	# draw units
	add $sp, $s1, $a0
	sw $t0, 0($sp)
	add $s2, $sp, $zero
	
	add $sp, $s1, $a1
	sw $t0, 0($sp)
	add $s3, $sp, $zero
	
	add $sp, $s1, $a2
	sw $t0, 0($sp)
	add $s4, $sp, $zero
	
	add $sp, $s1, $a3
	sw $t0, 0($sp)
	add $s5, $sp, $zero
	
collision_return:
	jr $ra

############################################################
############################################################

find_completed_line:
# Check for a completed line
	add $t1, $zero, $zero		# $t1 = index
	addi $t2, $zero, 800		# $t2: completed_line $t2 / 40 - 1 times\

search_line:
	beq $t1, $t2, finish_search_line	# end of loop
	add $t3, $zero, $zero		# $t3 = index
	addi $t4, $zero, 40		# $t4: draw_background repeated 10 times
	
check_line:
	beq $t3, $t4, end_check_line	# end loop
	add $sp, $t3, $t1
	sub $sp, $s1, $sp
	lw $t0, 0($sp)			# value of the address (type)
    
	beq $t0, $zero, end_check_line
	addi $t3, $t3, 4		# increment
	beq $t3, 40, remove_line	# conditions met for line removal
	j check_line

remove_line:
	add $t3, $zero, $zero		# $t3 = index
	addi $t4, $zero, 40		# $t4: draw_background repeated 10 times
	# animate prep (golden flash)
	lw $t5, ADDR_DSPL		# $t0 = base address for display
	addi $t6, $zero, 40
	div $t1, $t6
	mflo $t6			# row we are in 
	# (128 * $t6 + 136 gives us the address we are in in the display
	addi $t7, $zero, 128
	mult $t7, $t6
	mflo $t6
	addi $t6, $t6, 264
	add $t6, $t6, $t5
remove_units:
	beq $t3, $t4, pull_above	# end loop
	add $sp, $t3, $t1
	sub $sp, $s1, $sp
	add $t0, $zero, $zero
	sw  $t0, 0($sp)			# value of the address (type)
	# animate (golden flash)
	addi $t7, $zero, 0xffd700	# tile grey
	sw $t7, 0($t6)			# draw
	
	addi $t6, $t6, 4
	addi $t3, $t3, 4		# increment
	
	addi $v0, $zero, 32		# sleep syscall
	addi $a0, $zero, 100		# 1 second to delete the row
	syscall
	j remove_units

pull_above:
	addi $t3, $zero, 36		# $t3 = index
	add $t4, $zero, $t1
	addi $t4, $t4, -4
shift_down_by_one:
	beq $t3, $t4, end_check_line	# end loop
	sub $sp, $s1, $t4
	add $t0, $zero, $zero
	lw $t5, 0($sp)			# read from the current address
	sw  $t5, -40($sp)		# update it to the address below it
	sw  $t0, 0($sp)		# set the current address to empty
	addi $t4, $t4, -4		# count down
	j shift_down_by_one

end_check_line:
	addi $t1, $t1, 40		# increment
	j search_line

finish_search_line:
	jr $ra

############################################################
############################################################

game_over:
	# 3. Draw the Game Over Screen
	lw $t0, ADDR_DSPL		# $t0 = base address for display
	add $t1, $zero, $zero		# $t1 = index
	addi $t2, $zero, 1024		# $t2: draw_background repeated $t2 times

draw_background_go:
	beq $t1, $t2, write_game_over	# end of loop (index = 1024)
	jal draw_tile_go			# draw a tile
	addi $t1, $t1, 1		# increment index
	addi $t0, $t0, 4		# increment address
	addi $v0, $zero, 32		# sleep syscall
	addi $a0, $zero, 3		# 0.05 second delay
	syscall
	j draw_background_go

# Precondition: $t0 = address of the display of the index, $t1 = index of the loop
draw_tile_go:
	addi $t3, $zero, 0x20		# load 32 for the divisor
	div $t1, $t3		# division
	mflo $t8		# $t8 = row in the display
	mfhi $t9		# $t9 = column in the display
	j draw_checkered_go
	
draw_checkered_go:
	addi $t3, $zero, 0x2		# load 2 for the divisor
	div $t8, $t3			# division
	mfhi $t8			# remainder: $t9: 1 -> light grey, 0 -> grey
	div $t9, $t3			# division
	mfhi $t9			# remainder: $t9: 1 -> light grey, 0 -> grey
	# xor will give the checkered pattern
	xor $t3, $t8, $t9
	addi $t4, $zero, 0x1
	beq $t3, $t4, draw_light_black_2
	# else draw light-grey
	addi $t5, $zero, 0x191919	# tile light-black
	sw $t5, 0($t0)			# draw
	jr $ra
	
draw_light_black_2:
	addi $t5, $zero, 0x2f2f2f	# tile grey
	sw $t5, 0($t0)			# draw
	jr $ra
	
write_game_over:
	add $t1, $zero, $zero
	lw $t2, GAME_OVER_SIZE		# size of the array
	la $t3, GAME_OVER
	lw $t0, ADDR_DSPL		# $t0 = base address for display
	addi $t5, $zero, 0xffffff	# tile grey
	jal print
	j key_press_go

key_press_go:
	lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
	lw $t8, 0($t0)                  # Load first word from keyboard
	beq $t8, 1, key_pressed_game_over	# If key is pressed, go to key_pressed
	addi $v0, $zero, 32		# sleep syscall
	addi $a0, $zero, 10		# 0.01 second delay
	syscall
	j key_press_go		# else, skip checking for which key

key_pressed_game_over:
	lw $a0, 4($t0)			# load keybaord value to function param
	# Interface controls
	beq $a0, 0x7A, keypress_z	# key z (retry)
	beq $a0, 0x78, keypress_x	# key x (quit)
	# when reached, invalid key input
	j key_press_go
	
############################################################
############################################################

paused:
	add $t7, $ra, $zero		# copy return address
	add $t1, $zero, $zero
	lw $t2, PAUSE_SIZE		# size of the array
	la $t3, PAUSE
	lw $t0, ADDR_DSPL		# $t0 = base address for display
	addi $t5, $zero, 0x000000	# tile grey
	jal print
	jal wait_for_input
	jr $t7				# return
	

############################################################
############################################################

# Precondition: $t0 = display address, $t1 = 0, $t2 = size, $t3 = array list of offset,$t5 = color
# The function also uses $t6, so take note.
print:
	beq $t1, $t2, print_end
	lw $t4, 0($t3)
	addi $t6, $zero, 4
	mult $t4, $t6
	mflo $t4
	add $t6, $t0, $t4
	sw $t5, 0($t6)
	
	addi $t1, $t1, 1
	addi $t3, $t3, 4
	j print

print_end:
	jr $ra
	
############################################################
############################################################

wait_for_input:
	lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
	
wait_for_input_repeat:
	lw $t8, 0($t0)                  # Load first word from keyboard
	beq $t8, 1, paused_key_pressed	# If key is pressed, go to key_pressed
	addi $v0, $zero, 32		# sleep syscall
	addi $a0, $zero, 10		# 0.01 second delay
	syscall
	j wait_for_input_repeat		# else, check again
	
paused_key_pressed:
	lw $a0, 4($t0)			# load keybaord value to function param
	# Interface controls
	beq $a0, 0x70, stop_waiting	# key p
	# when reached, invalid key input
	j wait_for_input_repeat

stop_waiting:
	jr $ra
	
############################################################
############################################################
