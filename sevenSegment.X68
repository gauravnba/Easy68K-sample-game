*-----------------------------------------------------------
* Title      :7-segment Display
* Written by :Gaurav Nanda
* Date       :9 OCTOBER, 2016
* Description:Writes a number in seven segment format to
*             display
*-----------------------------------------------------------
NUMBER_TO_PRINT     EQU $20

SEVEN_SEGMENT_X1    EQU 5
SEVEN_SEGMENT_X2    EQU 25
SEVEN_SEGMENT_Y1    EQU 5
SEVEN_SEGMENT_Y2    EQU 27
SEVEN_SEGMENT_Y3    EQU 50

INITIAL_SEVEN_SEGMENT_REGION_X  EQU 720
INITIAL_SEVEN_SEGMENT_REGION_Y  EQU 5
TENS_DIGIT_OFFSET_X     EQU 35

SEGMENT_PEN_WIDTH       EQU 3
SET_PEN_WIDTH_TRAP_CODE EQU 93
SET_POINT_XY_TRAP_CODE  EQU 86
DRAW_LINE_TRAP_CODE     EQU 85

BLACK       EQU $000000

DrawSevenSegment
*    move.b  #SEGMENT_PEN_WIDTH,d1
*    move.b  #SET_PEN_WIDTH_TRAP_CODE,d0
*    trap    #15
    move.l  #BLACK,d1
    move.l  #SET_PEN_COLOR_TRAP_CODE,d0
    trap    #15
    
    move.l  #BLACK,d1
    move.l  #SET_FILL_COLOR_TRAP_CODE,d0
    trap    #15
    
    move.l  #INITIAL_SEVEN_SEGMENT_REGION_X-TENS_DIGIT_OFFSET_X-SEGMENT_PEN_WIDTH,d1
    move.l  #INITIAL_SEVEN_SEGMENT_REGION_Y-SEGMENT_PEN_WIDTH,d2
    move.l  #INITIAL_SEVEN_SEGMENT_REGION_X+SEVEN_SEGMENT_X2+SEGMENT_PEN_WIDTH,d3
    move.l  #INITIAL_SEVEN_SEGMENT_REGION_Y+SEVEN_SEGMENT_Y3+SEGMENT_PEN_WIDTH,d4
    move.l  #DRAW_RECT_TRAP_CODE,d0
    trap    #15
    
    move.l  #WHITE,d1
    move.l  #SET_PEN_COLOR_TRAP_CODE,d0
    trap    #15
    
    lea     Digits,a0
    lea     SevenSegmentX,a1
    lea     SevenSegmentY,a2
    
    move.l  4(sp),d0
    move.l  d0,d7
    and.l   #$F,d0
    
    move.l  SEVEN_SEGMENT_REGION_X,d5
    move.l  SEVEN_SEGMENT_REGION_Y,d6
    
    jsr     DrawDigit
    
    sub.l   #TENS_DIGIT_OFFSET_X,d5
    
    move.l  d7,d0
    lsr.l   #4,d0
    jsr     DrawDigit
    
    rts
    
DrawDigit
    move.b  (a0,d0),d4
    
    lsr.b   #1,d4
    bcc     checkSegmentF
    
    move.l  #12,d3
    jsr     DrawSegment
    
checkSegmentF
    lsr.b   #1,d4
    bcc     checkSegmentE
    
    move.l  #10,d3
    jsr     DrawSegment

checkSegmentE
    lsr.b   #1,d4
    bcc     checkSegmentD
    
    move.l  #8,d3
    jsr     DrawSegment

checkSegmentD
    lsr.b   #1,d4
    bcc     checkSegmentC
    
    move.l  #6,d3
    jsr     DrawSegment

checkSegmentC
    lsr.b   #1,d4
    bcc     checkSegmentB
    
    move.l  #4,d3
    jsr     DrawSegment
    
checkSegmentB
    lsr.b   #1,d4
    bcc     checkSegmentA
    
    move.l  #2,d3
    jsr     DrawSegment

checkSegmentA
    lsr.b   #1,d4
    bcc     endChecking
    
    move.l  #0,d3
    jsr     DrawSegment
    
endChecking
    rts
    
DrawSegment
    clr.l   d1
    clr.l   d2
    move.b  (a1,d3),d1
    add.l   d5,d1
    move.b  (a2,d3),d2
    add.l   d6,d2
    
    add.l   #1,d3
    
    move.l  #SET_POINT_XY_TRAP_CODE,d0
    trap    #15
    
    clr.l   d1
    clr.l   d2
    move.b  (a1,d3),d1
    add.l   d5,d1
    move.b  (a2,d3),d2
    add.l   d6,d2
    
    move.l  #DRAW_LINE_TRAP_CODE,d0
    trap    #15
    
    rts
        
Digits          dc.b    %1111110                                ;digit 0
                dc.b    %0110000                                ;digit 1
                dc.b    %1101101                                ;digit 2
                dc.b    %1111001                                ;digit 3
                dc.b    %0110011                                ;digit 4
                dc.b    %1011011                                ;digit 5
                dc.b    %1011111                                ;digit 6
                dc.b    %1110000                                ;digit 7
                dc.b    %1111111                                ;digit 8
                dc.b    %1111011                                ;digit 9

;$7E,$30,$6D,$79,$33,$5B,$5F,$50,$7F,$7B ;0,1,2,3,4,5,6,7,8,9 digits represented as corresponnding bits in the seven segment.

SevenSegmentX   dc.b    SEVEN_SEGMENT_X1,SEVEN_SEGMENT_X2       ;segment a
                dc.b    SEVEN_SEGMENT_X2,SEVEN_SEGMENT_X2       ;segment b
                dc.b    SEVEN_SEGMENT_X2,SEVEN_SEGMENT_X2       ;segment c
                dc.b    SEVEN_SEGMENT_X1,SEVEN_SEGMENT_X2       ;segment d
                dc.b    SEVEN_SEGMENT_X1,SEVEN_SEGMENT_X1       ;segment e
                dc.b    SEVEN_SEGMENT_X1,SEVEN_SEGMENT_X1       ;segment f
                dc.b    SEVEN_SEGMENT_X1,SEVEN_SEGMENT_X2       ;segment g
                
SevenSegmentY   dc.b    SEVEN_SEGMENT_Y1,SEVEN_SEGMENT_Y1       ;segment a
                dc.b    SEVEN_SEGMENT_Y1,SEVEN_SEGMENT_Y2       ;segment b
                dc.b    SEVEN_SEGMENT_Y2,SEVEN_SEGMENT_Y3       ;segment c
                dc.b    SEVEN_SEGMENT_Y3,SEVEN_SEGMENT_Y3       ;segment d
                dc.b    SEVEN_SEGMENT_Y2,SEVEN_SEGMENT_Y3       ;segment e
                dc.b    SEVEN_SEGMENT_Y1,SEVEN_SEGMENT_Y2       ;segment f
                dc.b    SEVEN_SEGMENT_Y2,SEVEN_SEGMENT_Y2       ;segment g
                
                
SEVEN_SEGMENT_REGION_X  ds.l    1 ;INITIAL_SEVEN_SEGMENT_REGION_X
SEVEN_SEGMENT_REGION_Y  ds.l    1 ;INITIAL_SEVEN_SEGMENT_REGION_Y















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
