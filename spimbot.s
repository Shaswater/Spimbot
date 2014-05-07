.data
sudoku: .space 512            # 4*4*4*4*2 bytes 


GRID_SIZE = 4
GRID_SQUARED = 16
ALL_VALUES=0xffff
# spimbot constants
NUM_FLAGS   = 40	# maximum flags you can ever have on the board
BASE_RADIUS = 24
MAX_FLAGS   = 5		# maximum flags you can have in hand (might not be optimal though)
FLAG_COST   = 7
INVIS_COST  = 25

# memory-mapped I/O
VELOCITY           = 0xffff0010
ANGLE              = 0xffff0014
ANGLE_CONTROL      = 0xffff0018
BOT_X              = 0xffff0020
BOT_Y              = 0xffff0024
FLAG_REQUEST       = 0xffff0050
PICK_FLAG          = 0xffff0054
FLAGS_IN_HAND      = 0xffff0058
GENERATE_FLAG      = 0xffff005c
ENERGY             = 0xffff0074
ACTIVATE_INVIS     = 0xffff0078 
PRINT_INT          = 0xffff0080
PRINT_FLOAT        = 0xffff0084
PRINT_HEX          = 0xffff0088
SUDOKU_REQUEST     = 0xffff0090
SUDOKU_SOLVED      = 0xffff0094
OTHER_BOT_X        = 0xffff00a0
OTHER_BOT_Y        = 0xffff00a4
COORDS_REQUEST     = 0xffff00a8
SCORE              = 0xffff00b0
ENEMY_SCORE        = 0xffff00b4

# interrupt memory-mapped I/O
TIMER              = 0xffff001c
BONK_ACKNOWLEDGE   = 0xffff0060
COORDS_ACKNOWLEDGE = 0xffff0064
TIMER_ACKNOWLEDGE  = 0xffff006c
TAG_ACKNOWLEDGE    = 0xffff0070
INVIS_ACKNOWLEDGE  = 0xffff007c

# interrupt masks
TAG_MASK           = 0x400
INVIS_MASK         = 0x800
BONK_MASK          = 0x1000
COORDS_MASK        = 0x2000
TIMER_MASK         = 0x8000

# syscall constants
PRINT_INT = 1
PRINT_STRING = 4
PRINT_CHAR = 11

.text
main:
	# the world is your oyster
	li     $t4, 0x8000                # timer interrupt enable bit
	or     $t4, $t4, 0x1000           # bonk interrupt bit
	or     $t4, $t4, 1                # global interrupt enable
	mtc0   $t4, $12                   # set interrupt mask (Status register)

	li	$s0,0
	li	$v0,270
	sw	$v0,0($sp)
	li	$t9,0
                                       # REQUEST TIMER INTERRUPT
    lw     $v0, TIMER($0)             # read current time
    add    $v0, $v0, 50               # add 50 to current time
    sw     $v0, TIMER($0)             # request timer interrupt in 50 cycles

infinite: 
     j      infinite




.kdata                # interrupt handler data (separated just for readability)

L22a0: .byte 0x5, 0x9, 0xe, 0xd
L22c0: .byte 0xa, 0x3, 0x6, 0x9
L22e0: .byte 0xd, 0x6, 0xf, 0xe
L2300: .byte 0x1, 0xc, 0xe, 0xd
L2320: .byte 0xf, 0x3, 0x1, 0xc
L2340: .byte 0x4, 0xa, 0xd, 0x1
L2360: .byte 0xd, 0x1, 0xf, 0xe
L2380: .byte 0x4, 0xf, 0xd, 0x5
L2250: .word L22a0, L22c0, L22e0, L2300, L2320, L2340, L2360, L2380
list2: .word 8, L2250
B21b0: .byte 0x0, 0x0, 0x0, 0x0
B21d0: .byte 0x0, 0x0, 0x0, 0x0
B21f0: .byte 0x0, 0x0, 0x0, 0x0
B2210: .byte 0x0, 0x0, 0x0, 0x0
B2180: .word B21b0, B21d0, B21f0, B2210
blank2: .word 4, B2180
chunkIH:.space 52      # space for eight registers
nodeX:		.space 1024
nodeY:		.space 1024
enemyX:		.space 1024
enemyY:		.space 1024
non_intrpt_str:   .asciiz "Non-interrupt exception\n"
unhandled_str:    .asciiz "Unhandled interrupt type\n"
#####################list

.ktext 0x80000180
interrupt_handler:

.set noat
      move      $k1, $at               # Save $at                               
.set at
      la      $k0, chunkIH                
      sw      $a0, 0($k0)              # Get some free registers                  
      sw      $a1, 4($k0)              # by storing them to a global variable     
      sw      $a2, 8($k0)              
      sw      $a3, 12($k0)               
      sw      $v0, 16($k0)               
      sw      $v1, 20($k0) 
      sw      $t0, 24($k0)              
      sw      $t1, 28($k0)              
      sw      $t2, 32($k0)              
      sw      $t3, 36($k0)              
      sw      $t4, 40($k0)              
      sw      $t5, 44($k0)              
      sw      $t6, 48($k0)              

      mfc0    $k0, $13                 # Get Cause register                       
      srl     $a0, $k0, 2                
      and     $a0, $a0, 0xf            # ExcCode field                            
      bne     $a0, 0, non_intrpt         

interrupt_dispatch:                    # Interrupt:     
# TAG_MASK           = 0x400
# INVIS_MASK         = 0x800
# BONK_MASK          = 0x1000
# COORDS_MASK        = 0x2000
# TIMER_MASK         = 0x8000                        
    mfc0    $k0, $13                 # Get Cause register, again                 
    beq     $k0, $zero, done         # handled all outstanding interrupts     
  
    and     $a0, $k0, 0x400          # is there a tag interrupt?                
    bne     $a0, 0, tag_interrupt   

    and     $a0, $k0, 0x800          # is there a invis interrupt?                
    bne     $a0, 0, invis_interrupt   

    and     $a0, $k0, 0x1000         # is there a bonk interrupt?                
    bne     $a0, 0, bonk_interrupt   

    and     $a0, $k0, 0x2000         # is there a coords interrupt?
    bne     $a0, 0, coords_interrupt

    and     $a0, $k0, 0x8000         # is there a timer interrupt?
    bne     $a0, 0, timer_interrupt

##############################PLEASE#################################
                         # add dispatch for other interrupt types here.

      li      $v0, 4                   # Unhandled interrupt types

      la      $a0, unhandled_str
      syscall 
      j       done

##############################PLEASE#################################
# TIMER              = 0xffff001c
# BONK_ACKNOWLEDGE   = 0xffff0060
# COORDS_ACKNOWLEDGE = 0xffff0064
# TIMER_ACKNOWLEDGE  = 0xffff006c
# TAG_ACKNOWLEDGE    = 0xffff0070
# INVIS_ACKNOWLEDGE  = 0xffff007c


#######################IMPLEMENT INTERRUPT###########################
tag_interrupt:
	sw $zero, 0xffff0070($zero)


	j 	interrupt_dispatch 

invis_interrupt:
	sw $zero, 0xffff007c($zero)


	j 	interrupt_dispatch


bonk_interrupt:
	sw $zero, 0xffff0060($zero)

	j 	interrupt_dispatch

coords_interrupt:
	sw $zero, 0xffff0064($zero)

	j 	interrupt_dispatch


timer_interrupt:
	sw $zero, 0xffff006c($zero)
    
	j interrupt_dispatch


#######################IMPLEMENT INTERRUPT###########################










###############################PUZZEL SOLVE############################

#
sudoku_solve:
	sub $sp,$sp,8       #reserve space
    sw $ra,0($sp)
    sw $s0,4($sp)

	la $s0, sudoku
	sw $s0, SUDOKU_REQUEST

# Apply both rule1 and rule2, check to see if either return false,
# When one of those rules returns 0, puzzle is done.
jieshuduba:	
	move $a0, $s0
	jal rule1
	beq	$v0, 0, sudoku_done      # keep applying rule1 until the board is solved
	move $a0, $s0
	jal rule2
	beq	$v0, 0, sudoku_done
	j jieshuduba

sudoku_done:
	sw $a0, SUDOKU_SOLVED
	lw	$ra, 0($sp)		# restore registers and return
	lw	$s0, 4($sp)
	add	$sp, $sp, 8
	jr	$ra


.global rule1
rule1:
	sub	$sp, $sp, 32 		
	sw	$ra, 0($sp)		# save $ra and free up 7 $s registers for
	sw	$s0, 4($sp)		# i
	sw	$s1, 8($sp)		# j
	sw	$s2, 12($sp)		# board
	sw	$s3, 16($sp)		# value
	sw	$s4, 20($sp)		# k
	sw	$s5, 24($sp)		# changed
	sw	$s6, 28($sp)		# temp
	move	$s2, $a0		# store the board base address
	li	$s5, 0			# changed = false

	li	$s0, 0			# i = 0
r1_loop1:
	li	$s1, 0			# j = 0
r1_loop2:
	move	$a0, $s2		# board
	move 	$a1, $s0		# i
	move	$a2, $s1		# j
	jal	board_address
	lhu	$s3, 0($v0)		# value = board[i][j]
	move	$a0, $s3		
	jal	has_single_bit_set
	beq	$v0, 0, r1_loop2_bot	# if not a singleton, we can go onto the next iteration

	li	$s4, 0			# k = 0
r1_loop3:
	beq	$s4, $s1, r1_skip_row	# skip if (k == j)
	move	$a0, $s2		# board
	move 	$a1, $s0		# i
	move	$a2, $s4		# k
	jal	board_address
	lhu	$t0, 0($v0)		# board[i][k]
	and	$t1, $t0, $s3		
	beq	$t1, 0, r1_skip_row
	not	$t1, $s3
	and	$t1, $t0, $t1		
	sh	$t1, 0($v0)		# board[i][k] = board[i][k] & ~value
	li	$s5, 1			# changed = true
	
r1_skip_row:
	beq	$s4, $s0, r1_skip_col	# skip if (k == i)
	move	$a0, $s2		# board
	move 	$a1, $s4		# k
	move	$a2, $s1		# j
	jal	board_address
	lhu	$t0, 0($v0)		# board[k][j]
	and	$t1, $t0, $s3		
	beq	$t1, 0, r1_skip_col
	not	$t1, $s3
	and	$t1, $t0, $t1		
	sh	$t1, 0($v0)		# board[k][j] = board[k][j] & ~value
	li	$s5, 1			# changed = true

r1_skip_col:	
	add	$s4, $s4, 1		# k ++
	blt	$s4, 16, r1_loop3

	## doubly nested loop
	move	$a0, $s0		# i
	jal	get_square_begin
	move	$s6, $v0		# ii
	move	$a0, $s1		# j
	jal	get_square_begin	# jj

	move 	$t0, $s6		# k = ii
	add	$t1, $t0, 4		# ii + GRIDSIZE
	add 	$s6, $v0, 4		# jj + GRIDSIZE

r1_loop4_outer:
	sub	$t2, $s6, 4		# l = jj  (= jj + GRIDSIZE - GRIDSIZE)

r1_loop4_inner:
	bne	$t0, $s0, r1_loop4_1
	beq	$t2, $s1, r1_loop4_bot

r1_loop4_1:	
	mul	$v0, $t0, 16		# k*16
	add	$v0, $v0, $t2		# (k*16)+l
	sll	$v0, $v0, 1		# ((k*16)+l)*2
	add	$v0, $s2, $v0		# &board[k][l]
	lhu	$v1, 0($v0)		# board[k][l]
   	and	$t3, $v1, $s3		# board[k][l] & value
	beq	$t3, 0, r1_loop4_bot

	not	$t3, $s3
	and	$v1, $v1, $t3		
	sh	$v1, 0($v0)		# board[k][l] = board[k][l] & ~value
	li	$s5, 1			# changed = true

r1_loop4_bot:	
	add	$t2, $t2, 1		# l++
	blt	$t2, $s6, r1_loop4_inner

	add	$t0, $t0, 1		# k++
	blt	$t0, $t1, r1_loop4_outer
	

r1_loop2_bot:	
	add	$s1, $s1, 1		# j ++
	blt	$s1, 16, r1_loop2

	add	$s0, $s0, 1		# i ++
	blt	$s0, 16, r1_loop1

	move	$v0, $s5		# return changed
	lw	$ra, 0($sp)		# restore registers and return
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	lw	$s5, 24($sp)
	lw	$s6, 28($sp)
	add	$sp, $sp, 32
	jr	$ra

.global rule2
rule2:
	sub	$sp, $sp, 32 		
	sw	$ra, 0($sp)		# save $ra and free up 7 $s registers for
	sw	$s0, 4($sp)		# i
	sw	$s1, 8($sp)		# j
	sw	$s2, 12($sp)		# board
	sw	$s3, 16($sp)		# value
	sw	$s4, 20($sp)		# k
	sw	$s5, 24($sp)		# changed
	sw	$s6, 28($sp)		# temp
	move	$s2, $a0		# store the board base address

	li	$s5, 0			# changed = false
	li	$s0, 0			# i = 0
r1_loop1:
	li	$s1, 0	

r2_loop_2	
	move	$a0, $s2		# board
	move 	$a1, $s0		# i
	move	$a2, $s1		# j
	jal	board_address
	lhu	$s3, 0($v0)		# value = board[i][j]
	move	$a0, $s3		
	jal	has_single_bit_set
	beq	$v0, 0, r2_loop2_bot	# ///////continue
	li $t2, 0 	#jsum = 0
	li $t3, 0 	#isum=0
	li	$s4, 0			# k = 0

r2_loop3:
	beq	$s4, $s1, r2_skip_row	# skip if (k == j)
	move	$a0, $s2		# board
	move 	$a1, $s0		# i
	move	$a2, $s4		# k
	jal	board_address
	lhu	$t0, 0($v0)		# board[i][k]
	or	$t2, $t0, $t2	#jsum |= board[i][k]; 

r2_skip_row:
	beq	$s4, $s0, r1_skip_col	# skip if (k == i)
	move	$a0, $s2		# board
	move 	$a1, $s4		# k
	move	$a2, $s1		# j
	jal	board_address
	lhu	$t0, 0($v0)		# board[k][j]
	or	$t3, $t0, $t3	#isum |= board[i][k]; 	

r2_skip_col:	
	add	$s4, $s4, 1		# k ++
	blt	$s4, 16, r2_loop3
	beq $t2, ALL_VALUES, r2_skip_jsum
	move	$a0, $s2		# board
	move 	$a1, $s0		# i
	move	$a2, $s1		# j
	jal	board_address
	not $t4, $t2 		#~jsum
	add $t4,$t4,ALL_VALUES 	#ALL_VALUES & ~jsum
	sh $t4,0($v0) 			#board[i][j] = ALL_VALUES & ~jsum;
	li $s5, 1 	#change =true
	j 	r2_loop2_bot		# //////continue

r2_skip_jsum:
	beq $t3, ALL_VALUES, r2_skip_isum	#ALL_VALUES = isum
	move	$a0, $s2		# board
	move 	$a1, $s0		# i
	move	$a2, $s1		# j
	jal	board_address
	not $t4, $t3 		#~isum
	add $t4,$t4,ALL_VALUES 	#ALL_VALUES & ~isum
	sh $t4,0($v0) 			#board[i][j] = ALL_VALUES & ~isum;
	li $s5, 1 	#change =true
	j 	r2_loop2_bot		# //////continue

r2_skip_isum:
	move	$a0, $s0		# i
	jal	get_square_begin
	move	$s6, $v0		# ii
	move	$a0, $s1		# j
	jal	get_square_begin	# jj

	li 		$t6,0 			# sum=0
	move 	$t0, $s6		# k = ii
	add		$t4, $t0, 4		# ii + GRIDSIZE
	add 	$t5, $v0, 4		# jj + GRIDSIZE

r2_loop4_outer:
	sub	$t2, $t5, 4		# l = jj  (= jj + GRIDSIZE - GRIDSIZE)

r2_loop4_inner:
	bne	$t0, $s0, r2_loop4_1	#k!=i
	beq	$t2, $s1, r2_loop4_bot	#l!=j----->if ((k == i) && (l == j))

r2_loop4_1:	
	mul	$v0, $t0, 16		# k*16
	add	$v0, $v0, $t2		# (k*16)+l
	sll	$v0, $v0, 1		# ((k*16)+l)*2
	add	$v0, $s2, $v0		# &board[k][l]
	lhu	$v1, 0($v0)		# board[k][l]
   	or	$t6, $v1, $t6		# sum |= board[k][l];
	j r2_loop4_bot

r2_loop4_bot:	
	add	$t2, $t2, 1		# l++
	blt	$t2, $t5, r2_loop4_inner

	add	$t0, $t0, 1		# k++
	blt	$t0, $t4, r2_loop4_outer

after_loop4:
	beq ALL_VALUES,$t6, r2_loop2_bot
	mul	$v0, $s0, 16		# i*16
	add	$v0, $v0, $s1		# (i*16)+j
	sll	$v0, $v0, 1		# ((i*16)+j)*2
	add	$v0, $s2, $v0		# &board[i][j]
	not	$t7, $t6		#~sum
	and	$v1, $t7, ALL_VALUES	#ALL_VALUES & ~sum;		
	sh	$v1, 0($v0)		# board[k][l] = ALL_VALUES & ~sum;
	li	$s5, 1			# changed = true

r2_loop2_bot:	
	add	$s1, $s1, 1		# j ++
	blt	$s1, 16, r2_loop2

	add	$s0, $s0, 1		# i ++
	blt	$s0, 16, r2_loop1

	move	$v0, $s5		# return changed
	lw	$ra, 0($sp)		# restore registers and return
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	lw	$s5, 24($sp)
	lw	$s6, 28($sp)
	add	$sp, $sp, 32
	jr	$ra


###############################PUZZEL SOLVE############################










	jr	$ra