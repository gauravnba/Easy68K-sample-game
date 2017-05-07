*The game has Boba Fett on Mustafar. You control his jetpack to get him around and collect      *
*the energy being released from the Force generators. Since Mustafar is a burning planet,       *
*Boba Fett can't land on the floor.                                                             *
*                                                                                               *
*Controls:                                                                                      *
*    Use Up arrow key to use Fett's jetpack                                                     *
*    Use Right and Left arrows keys to direct him laterally                                     *
*------------------------------------------------------------------------------------------------

FRACTIONAL_BITS             EQU 8

INITIAL_PLAYER_POSITION_X   EQU 365<<FRACTIONAL_BITS
INITIAL_PLAYER_POSITION_Y   EQU 265<<FRACTIONAL_BITS
PLAYER_WIDTH				EQU	60
PLAYER_HEIGHT				EQU	55
ADD_PLAYER_VELOCITY_X       EQU 1600
ADD_PLAYER_VELOCITY_Y       EQU 1400

PLAYER_SPRITE_LEFT_X        EQU 0
PLAYER_SPRITE_RIGHT_X       EQU 60
PLAYER_SPRITE_IDLE_Y        EQU 0
PLAYER_SPRITE_FLIGHT_Y      EQU 55
PLAYER_SPRITE_SHOOT_Y       EQU 110    

GRAVITY                     EQU 50

ENEMY_WIDTH                 EQU 30
ENEMY_HEIGHT                EQU 5
ENEMY_VELOCITY_X            EQU 1200

DOUBLE_BUFFER_DRAW_MODE     EQU 17
ONE_SECOND                  EQU 100
TWO_SECONDS                 EQU 200

KEY_LEFT_INPUT          EQU $25
KEY_UP_INPUT            EQU $26
KEY_RIGHT_INPUT         EQU $27
SPACEBAR_KEY_INPUT      EQU $20

DISPLAY_WINDOW_WIDTH    EQU 800
DISPLAY_WINDOW_HEIGHT   EQU 600

BACKGROUND_Y_IMAGE_OFFSET   EQU 60

FAIL_STATE_BLOCK_X1         EQU 80
FAIL_STATE_BLOCK_X2         EQU 720
FAIL_STATE_BLOCK_Y1         EQU 60
FAIL_STATE_BLOCK_Y2         EQU 540

RESTART_MESSAGE_X           EQU 320
RESTART_MESSAGE_Y           EQU 500

LOADING_MESSAGE_X           EQU 350
LOADING_MESSAGE_Y           EQU 300

SET_RESOLUTION_TRAP_CODE    EQU 33
SET_DOUBLE_BUFFER_TRAP_CODE EQU 92
DISPLAY_BUFFER_TRAP_CODE    EQU 94
SET_PEN_COLOR_TRAP_CODE		EQU	80
SET_FILL_COLOR_TRAP_CODE	EQU	81
SET_PEN_WIDTH_TRAP_CODE     EQU 93
DRAW_RECT_TRAP_CODE         EQU 87
GET_USER_INPUT_TRAP_CODE    EQU 19
DELAY_TRAP_CODE             EQU 23
GET_TIME_TRAP_CODE          EQU 8
PLAY_AUDIO_DX_TRAP_CODE     EQU 73
DRAW_ENEMY_TRAP_CODE        EQU 88
DRAW_STRING_TRAP_CODE       EQU 95

GREEN   EQU $00BB22
RED	    EQU	$0022FF
BLUE	EQU	$ED0001
WHITE   EQU $FFFFFF

    ORG    $1000
START:

Main    
    move.b  #0,FAIL_STATE    
    jsr     InitGame
    move.l  #ONE_SECOND,d1
    move.l  #DELAY_TRAP_CODE,d0
    trap    #15
        
gameLoop
  	move.l  #DISPLAY_BUFFER_TRAP_CODE,D0
	trap    #15
	
    jsr     UpdateEnemy
    jsr     DrawEnemy
	
    jsr     InputManager
    jsr     UpdatePlayerPosition
    jsr     DrawPlayer
        
    cmp.b   #0,FAIL_STATE    
    beq     gameLoop
    
*FailState------------    
    move.l  #GREEN,d1
    move.l  #SET_PEN_COLOR_TRAP_CODE,d0
    trap    #15
    
    move.l  #SET_FILL_COLOR_TRAP_CODE,d0
    trap    #15
    
    move.l  #FAIL_STATE_BLOCK_X1,d1
    move.l  #FAIL_STATE_BLOCK_Y1,d2
    move.l  #FAIL_STATE_BLOCK_X2,d3
    move.l  #FAIL_STATE_BLOCK_Y2,d4
    
    move.l  #DRAW_RECT_TRAP_CODE,d0
    trap  #15
    
    lea     RESTART_MESSAGE,a1
    move.l  #RESTART_MESSAGE_X,d1
    move.l  #RESTART_MESSAGE_Y,d2
    
    move.l  #DRAW_STRING_TRAP_CODE,d0
    trap    #15
   
    move.l  #403,SEVEN_SEGMENT_REGION_X
    move.l  #303,SEVEN_SEGMENT_REGION_Y
    
    sub.l   #4,sp
    move.l  SCORE,(sp)
    jsr     DrawSevenSegment
    add.l   #4,sp
    
   	move.l  #DISPLAY_BUFFER_TRAP_CODE,D0
	trap    #15
	
    lea     FAIL_STATE_AUDIO,a1
    move.l  #PLAY_AUDIO_DX_TRAP_CODE,d0
    trap    #15

checkRestart
    move.l  #SPACEBAR_KEY_INPUT,d1
    move.l  #GET_USER_INPUT_TRAP_CODE,d0
    trap    #15
    
    cmp.b   #$FF,d1
    beq     Main
    
    bra     checkRestart
   
    STOP    #$2000

*-------------------------------------------------------  
InitGame
    move.l  #0,SCORE
    move.b  #0,HAVE_HAD_NO_INPUT
    move.l  #0,PLAYER_VELOCITY_X
    move.l  #0,PLAYER_VELOCITY_Y
*    move.b  #0,WAIT_ONE_SECOND
    move.b  #0,IS_PLAYER_LEFT
    move.b  #0,ENEMY_ON_SCREEN
    move.b  #0,ENEMY_MOVING_LEFT
    move.l  #803,PREVIOUS_ENEMY_POSITION_X
    move.l  #INITIAL_PLAYER_POSITION_X,PLAYER_POSITION_X
    move.l  #INITIAL_PLAYER_POSITION_Y,PLAYER_POSITION_Y
    move.l  #INITIAL_SEVEN_SEGMENT_REGION_X,SEVEN_SEGMENT_REGION_X
    move.l  #INITIAL_SEVEN_SEGMENT_REGION_Y,SEVEN_SEGMENT_REGION_Y
    
    move.l  #INITIAL_PLAYER_POSITION_X>>FRACTIONAL_BITS,PREVIOUS_PLAYER_POSITION_X
    move.l  #INITIAL_PLAYER_POSITION_Y>>FRACTIONAL_BITS,PREVIOUS_PLAYER_POSITION_Y
    
    move.l  #DISPLAY_WINDOW_WIDTH,d1
    swap    d1
    move.w  #DISPLAY_WINDOW_HEIGHT,d1
    move.l  #SET_RESOLUTION_TRAP_CODE,d0
    trap    #15
    
    lea     LOADING_MESSAGE,a1
    move.l  #LOADING_MESSAGE_X,d1
    move.l  #LOADING_MESSAGE_Y,d2
    
    move.l  #DRAW_STRING_TRAP_CODE,d0
    trap    #15
    
    move.l  #DISPLAY_BUFFER_TRAP_CODE,d0
    trap    #15
    
    move.b  #3,d1
    move.l  #SET_PEN_WIDTH_TRAP_CODE,d0
    trap    #15
    
    move.l  #DOUBLE_BUFFER_DRAW_MODE,d1
    move.l  #SET_DOUBLE_BUFFER_TRAP_CODE,d0
    trap    #15

	jsr     LoadBackground
	
	jsr     LoadPlayerSpriteSheet

    jsr     seedRandomNumber

    sub.l   #4,sp                               ;prepare stack
    
    move.l  #0,(sp)
    jsr     DrawSevenSegment
    
    add.l   #4,sp                               ;fix stack   
	
    sub.l   #8,sp

    move.l  #0,(sp)
    move.l  #BACKGROUND_Y_IMAGE_OFFSET,4(sp)
    move.l  #0,d3                               ;load arguments into data registers d3 onwards, since registers d0, d1 and d2 will be used for trap codes
    move.l  #BACKGROUND_Y_IMAGE_OFFSET,d4
    move.l  BACKGROUND_WIDTH,d5
    move.l  BACKGROUND_HEIGHT,d2
    sub.l   #BACKGROUND_Y_IMAGE_OFFSET,d2
	
	jsr     DrawBackground
	
    jsr     DrawPlayer
	
    move.l  #DISPLAY_BUFFER_TRAP_CODE,D0
	trap    #15
	
    add.l   #8,sp
	
	rts

*-------------------------------------------------------   
DrawPlayer

    sub.l   #8,sp

    move.l  PREVIOUS_PLAYER_POSITION_X,(sp)
    move.l  PREVIOUS_PLAYER_POSITION_Y,4(sp)
    
    move.l  PREVIOUS_PLAYER_POSITION_X,d3
    
    move.l  PREVIOUS_PLAYER_POSITION_Y,d4
    
    move.l  #PLAYER_WIDTH,d5
    move.l  #PLAYER_HEIGHT,d2
	
	jsr     DrawBackground
	
   	add.l   #8,sp
   	
   	
    clr.l   d3
    cmp.b   #1,IS_PLAYER_LEFT
    beq     .playerIsLeft
    
    move.w  #PLAYER_SPRITE_RIGHT_X,d3
    bra     .playerIsRight
    
.playerIsLeft
    move.w  #PLAYER_SPRITE_LEFT_X,d3
  
.playerIsRight
    clr.l   d4
        
    cmp.l   #0,PLAYER_VELOCITY_Y
    blt     flightOn
    
    move.l  #PLAYER_SPRITE_IDLE_Y,d4
    bra     flightOff
    
flightOn
    move.l  #PLAYER_SPRITE_FLIGHT_Y,d4
    
flightOff   	
    move.l  PLAYER_POSITION_X,d0
    lsr.l   #FRACTIONAL_BITS,d0
    move.l  d0,PREVIOUS_PLAYER_POSITION_X
    
    move.l  PLAYER_POSITION_Y,d1
    lsr.l   #FRACTIONAL_BITS,d1
    move.l  d1,PREVIOUS_PLAYER_POSITION_Y
    
   	sub.l   #8,sp
   	
    move.l  d0,(sp)                   ;load arguments into data registers d3 onwards, since registers d0, d1 and d2 will be used for trap codes
    move.l  d1,4(sp)
    
    move.l  #PLAYER_WIDTH,d5
	move.l  #PLAYER_HEIGHT,d2
	
    jsr     DrawPlayerSprite
    
    add.l   #8,sp
	
	rts

*-------------------------------------------------------
;Base function to get the inputs from Player	
InputManager
    jsr     UpdateUp
    jsr     UpdateRight
    jsr     UpdateLeft
    rts

*-------------------------------------------------------
;Updates Player position by adding the updated velocities obtained via the InputManager
UpdatePlayerPosition
*    cmp.b   #1,WAIT_ONE_SECOND
*    beq     checkWaitTimer
    
    move.l  PLAYER_VELOCITY_X,d0
    add.l   d0,PLAYER_POSITION_X
    move.l  #0,PLAYER_VELOCITY_X

    move.l  PLAYER_VELOCITY_Y,d0
    add.l   d0,PLAYER_POSITION_Y
    jsr     ApplyGravity
    jsr     CheckCollisions
    
.return    
    rts
*------------------------------   
ApplyGravity
    add.l   #GRAVITY,PLAYER_VELOCITY_Y
    rts

*------------------------------
UpdateUp
    move.l  #KEY_UP_INPUT,d1
    move.b  #GET_USER_INPUT_TRAP_CODE,d0
    trap    #15
    andi.l  #$FF,d1
    beq     noInput
    
    move.b  HAVE_HAD_NO_INPUT,d0
    beq     aroundNoInput
    move.b  #0,HAVE_HAD_NO_INPUT
    
    move.l  #0,PLAYER_VELOCITY_Y
    sub.l   #ADD_PLAYER_VELOCITY_Y,PLAYER_VELOCITY_Y
    
*Play audio when jetpack is on
    lea     JETPACK_AUDIO,a1
    move.l  #PLAY_AUDIO_DX_TRAP_CODE,d0
    trap    #15

    bra     aroundNoInput

noInput
    move.b  #1,HAVE_HAD_NO_INPUT
aroundNoInput
    rts
*------------------------------   
UpdateRight
    move.l  #KEY_RIGHT_INPUT,d1
    move.b  #GET_USER_INPUT_TRAP_CODE,d0
    trap    #15
    andi.l  #$FF,d1
    beq     .return
    add.l   #ADD_PLAYER_VELOCITY_X,PLAYER_VELOCITY_X
    move.b  #0,IS_PLAYER_LEFT
    
.return
    rts

*------------------------------
UpdateLeft
    move.l  #KEY_LEFT_INPUT,d1
    move.b  #GET_USER_INPUT_TRAP_CODE,d0
    trap    #15
    andi.l  #$FF,d1
    beq     .return
    sub.l   #ADD_PLAYER_VELOCITY_X,PLAYER_VELOCITY_X
    move.b  #1,IS_PLAYER_LEFT
    
.return
    rts
    
*-------------------------------
UpdateEnemy
    cmp.b   #0,ENEMY_ON_SCREEN
    beq     spawnEnemy
    
    cmp.b   #0,ENEMY_MOVING_LEFT
    bne     moveLeft
    add.l   #ENEMY_VELOCITY_X,ENEMY_POSITION_X

    bra     spawnOnRight
    
moveLeft
    sub.l   #ENEMY_VELOCITY_X,ENEMY_POSITION_X
    cmp.l   #0,ENEMY_POSITION_X
    bgt     spawnOnRight
    
    move.l  #0,ENEMY_POSITION_X
    bra     spawnOnRight
   
spawnEnemy
    jsr     getRandomByteIntoD6
    lsl.w   #1,d6
    add.l   #BACKGROUND_Y_IMAGE_OFFSET,d6
    move.l  d6,ENEMY_POSITION_Y
    
    jsr     getRandomByteIntoD6
    cmp.l   #$FF,d6
    blt     spawnOnLeft
    
    move.l  BACKGROUND_WIDTH,d0
    sub.l   #ENEMY_WIDTH+3,d0
    lsl.l   #FRACTIONAL_BITS,d0
    move.l  d0,ENEMY_POSITION_X
    move.b  #1,ENEMY_MOVING_LEFT
    bra     spawnOnRight

spawnOnLeft
    move.l  #1<<FRACTIONAL_BITS,d0
    move.l  d0,ENEMY_POSITION_X
    move.b  #0,ENEMY_MOVING_LEFT
    
spawnOnRight
*.return
    rts

*--------------------------------
DrawEnemy    
    sub.l   #8,sp
    
    move.l  PREVIOUS_ENEMY_POSITION_X,d3
    sub.l   #3,d3

    move.l  ENEMY_POSITION_Y,d4
    sub.l   #3,d4
    move.l  #ENEMY_WIDTH+6,d5
    move.l  #ENEMY_HEIGHT+6,d2
    
    cmp.l   #0,d3
    bgt     skipNextCommand
    
    move.l  #0,d3
    
skipNextCommand    
    move.l  d3,(sp)
    move.l  d4,4(sp)
    
    jsr     DrawBackground
    
    add.l   #8,sp
    
    move.l  #BLUE,d1
    move.l  #SET_PEN_COLOR_TRAP_CODE,d0
    trap    #15
    
    move.l  ENEMY_POSITION_X,d1
    lsr.l   #FRACTIONAL_BITS,d1
    move.l  d1,PREVIOUS_ENEMY_POSITION_X
    
dontStoreZero
    move.l  ENEMY_POSITION_Y,d2

    move.l  d1,d3
    move.l  d2,d4

    add.l   #ENEMY_WIDTH,d3
    add.l   #ENEMY_HEIGHT,d4

    move.l  #DRAW_ENEMY_TRAP_CODE,d0
    trap    #15
    
    cmp.l   #$321,d1
    bgt     destroyEnemy
    
    add.l   #PLAYER_WIDTH,d1
    cmp.l   #0,d1
    ble     destroyEnemy
    
    move.b  #1,ENEMY_ON_SCREEN
    bra     finishRoutine
   
destroyEnemy
*    jsr     DestroyEnemy
    move.b  #0,ENEMY_ON_SCREEN
*
*    lea     LASER_SHOT_AUDIO,a1
*    move.l  #PLAY_AUDIO_DX_TRAP_CODE,d0
*    trap    #15
*
*    jsr     UpdateScore
    
finishRoutine
    rts

*-------------------------------------- 

UpdateScore
    sub.l   #4,sp                               ;prepare stack
    
    move.l  #1,d1
    move.l  SCORE,d0
    abcd    d1,d0
    move.l  d0,(sp)
    move.l  d0,SCORE
    jsr     DrawSevenSegment
    
    add.l   #4,sp                               ;fix stack
    
    sub.l   #8,sp
    
    move.l  PREVIOUS_ENEMY_POSITION_X,d3
    sub.l   #3,d3
    
    move.l  ENEMY_POSITION_Y,d4
    sub.l   #3,d4
    move.l  #ENEMY_WIDTH+6,d5
    move.l  #ENEMY_HEIGHT+6,d2
    
    move.l  d3,(sp)
    move.l  d4,4(sp)
    
    jsr     DrawBackground
    
    add.l   #8,sp
    
    rts

*---------------------------------------

CheckCollisions
;Block of code to check Player collisions with screen edges
    move.l  PLAYER_VELOCITY_X,d1
    
    move.l  PLAYER_POSITION_X,d0
    lsr.l   #FRACTIONAL_BITS,d0
    
    cmp.l   #0,d0
    bgt     dontBouncePlayerToRight

    move.l  #1,PLAYER_POSITION_X
    
dontBouncePlayerToRight
    cmp.l   #DISPLAY_WINDOW_WIDTH-PLAYER_WIDTH,d0
    blt     dontBouncePlayerToLeft
    
    move.l  #(DISPLAY_WINDOW_WIDTH-PLAYER_WIDTH-1)<<FRACTIONAL_BITS,PLAYER_POSITION_X
    
dontBouncePlayerToLeft
    move.l  PLAYER_POSITION_Y,d1
    lsr.l   #FRACTIONAL_BITS,d1
    
    cmp.l   #BACKGROUND_Y_IMAGE_OFFSET,d1
    bgt     dontStopPlayerY_Up
    
    move.l  #(BACKGROUND_Y_IMAGE_OFFSET+1)<<FRACTIONAL_BITS,PLAYER_POSITION_Y    
    move.l  #0,PLAYER_VELOCITY_Y
    
dontStopPlayerY_Up
    cmp.l   #(DISPLAY_WINDOW_HEIGHT-PLAYER_HEIGHT),d1
    blt     dontStopPlayerY_Down
    
*    move.l  #(DISPLAY_WINDOW_HEIGHT-PLAYER_HEIGHT-1)<<FRACTIONAL_BITS,PLAYER_POSITION_Y
*    move.l  #0,PLAYER_VELOCITY_Y
    move.b  #1,FAIL_STATE
    
dontStopPlayerY_Down

;Block of code for Enemy and player collisions
    move.l  ENEMY_POSITION_Y,d0
    lsl.l   #FRACTIONAL_BITS,d0
    move.l  PLAYER_POSITION_Y,d1
    
    cmp.l   d0,d1
    bgt     playerNotInRange
    
    add.l   #PLAYER_HEIGHT<<FRACTIONAL_BITS,d1
    cmp.l   d0,d1
    blt     playerNotInRange
    
    move.l  ENEMY_POSITION_X,d0
    move.l  PLAYER_POSITION_X,d1
    
    add.l   #(ENEMY_WIDTH/2)<<FRACTIONAL_BITS,d0
    
    cmp.l   d0,d1
    bgt     playerNotInRange

    add.l   #PLAYER_WIDTH<<FRACTIONAL_BITS,d1
    cmp.l   d0,d1
    blt     playerNotInRange

*    move.l  #0,PLAYER_VELOCITY_X
*    move.l  #0,PLAYER_VELOCITY_Y

    move.l  #0,ENEMY_ON_SCREEN
    
    lea     LASER_SHOT_AUDIO,a1
    move.l  #PLAY_AUDIO_DX_TRAP_CODE,d0
    trap    #15

    jsr     UpdateScore
    
playerNotInRange    
    rts
    
*----------------------------------------------------------------------------------------

HAVE_HAD_NO_INPUT   ds.b    1
*WAIT_ONE_SECOND     dc.b    1
*WAIT_TIMER          ds.l    1

IS_PLAYER_LEFT      ds.b    1

PREVIOUS_PLAYER_POSITION_X  ds.l    1
PREVIOUS_PLAYER_POSITION_Y  ds.l    1

PLAYER_VELOCITY_X   ds.l    1
PLAYER_VELOCITY_Y   ds.l    1
PLAYER_POSITION_X   ds.l    1
PLAYER_POSITION_Y   ds.l    1

SCORE               ds.l    1

ENEMY_ON_SCREEN   ds.b    1

ENEMY_MOVING_LEFT   ds.b    1
ENEMY_POSITION_X    ds.l    1
ENEMY_POSITION_Y    ds.l    1
PREVIOUS_ENEMY_POSITION_X   ds.l    1

JETPACK_AUDIO       dc.b	'Jetpack.wav',0
LASER_SHOT_AUDIO    dc.b    'Laser_Shoot.wav',0
FAIL_STATE_AUDIO    dc.b    'round_end.wav',0

FAIL_STATE          ds.b    1

LOADING_MESSAGE     dc.b    'Loading...',0
RESTART_MESSAGE     dc.b    'Press Space to Restart',0

MAGIC_BYTE          ds.b    1

    INCLUDE "LoadAndDrawBackground.x68"
    INCLUDE "LoadAndDrawPlayer.x68"
    INCLUDE "RandomNumberGenerator.x68"
    INCLUDE "sevenSegment.x68"

    END    START











*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
