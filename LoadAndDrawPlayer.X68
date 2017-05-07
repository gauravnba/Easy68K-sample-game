*-----------------------------------------------------------
* Description:Loads the player sprite sheets and draws the
*             Player sprites
* Written by :Gaurav Nanda
*-----------------------------------------------------------
SEEK_IMAGE_OFFSET       EQU     $A
SEEK_DIB_HEADER_SIZE    EQU     $E
SEEK_WIDTH              EQU     $12
SEEK_HEIGHT             EQU     $16

PEN_COLOR_TRAP_CODE     EQU     80
DRAW_PIXEL_TRAP_CODE    EQU     82

*-------------------------------------------------------------

;This subroutine reads the image and saves it as a 32-bit pixel array in memory
    ;argument list:
    ;a0 is start of file
    
    ;local variables:
    ;a1 is width of image
    ;a2 is height of image
    ;a3 is index 0 of color table
    ;a4 is used once to calculate the start of pixel array and push it into a0
    
LoadPlayerSpriteSheet
    lea     PlayerSpriteSheet,a0
    lea     PLAYER_SPRITE_SHEET,a5  
;This snippet stores the width of the image in PLAYER_SHEET_WIDTH
    move.l  a0,a1
    add.l   #SEEK_WIDTH,a1
    move.l  (a1),d0
    jsr     ByteSwap
    move.l  d0,PLAYER_SHEET_WIDTH
    
;This snippet stores the height of the image in PLAYER_SHEET_HEIGHT 
    move.l  a0,a2
    add.l   #SEEK_HEIGHT,a2
    move.l  (a2),d0
    jsr     ByteSwap
    move.l  d0,PLAYER_SHEET_HEIGHT
    
;This snippet sets a3 as index 0 of color table
    move.l  a0,a3
    add.l   #SEEK_DIB_HEADER_SIZE,a3            ;a3 has the position of DIB header size      
    move.l  (a3),d0
    jsr     ByteSwap
    add.l   d0,a3                               ;by adding the value of the DIB header to a3, we move it to point to the start of the color table

;This snippet puts the address of the start of the pixel array into a0
    move.l  a0,a4
    add.l   #SEEK_IMAGE_OFFSET,a4               ;a4 is now the location of the value of offset to pixel array
    move.l  (a4),d0
    jsr     ByteSwap
    add.l   d0,a0                               ;adding value of a4 to a0 will result in a0 moving to the address of the start of the pixel array    

;This snippet calculates the padding bits of each row in the image
    move.l  PLAYER_SHEET_WIDTH,d7                             ;store width of image in d7
    and.l   #3,d7                               ;AND last three bits of width to get remainder of division by #4
    
    move.l  PLAYER_SHEET_HEIGHT,d2
    
.newRow
    move.l  PLAYER_SHEET_WIDTH,d5
.continue
    move.l  #0,d0
    move.b  (a0)+,d0                            ;set index of pixel color to be obtained from the color table
    lsl.l   #2,d0                               ;the color value stored in the color table is a longword, in BBGGRRAA format. Hence, we multiply index value by #4 to seek address of color in color table
    move.l  (a3,d0),d1                          ;store pixel value to d1, to be used by trap
    ror.l   #8,d1                               ;convert BBGGRRAA value to 00BBGGRR value
    move.l  d1,(a5)+
    
    sub.l   #1,d5                               ;decrement x counter
    bne     .continue                        ;branch end of row hasn't yet been traversed
    
    add.l   d7,a0                               ;apply padding to move the address of current pixel to point to the pixel in next row

    sub.l   #1,d2                               ;decrement y value (row) to move to the new row.
    bne     .newRow                              ;branch if last row is yet to complete

    rts
*------------------------------------

*-------------------------------------------------------------
;This subroutine reads and draws the chunk from the loaded image.
;arguments-
    ;a0 is the start of the image in memory, as it traversed the whole pixel array in loadImage.
    ;4(sp) includes X offset from the left side of screen that the chunk is to be drawn on
    ;8(sp) includes Y offset from the top of the screen.
    ;
    ;d3 is the starting x value of chunk to be drawn
    ;d4 is the starting y value of chunk to be drawn
    ;d5 is the width of the chunk
    ;d2 is the height of the chunk
    
;    values used in code that were already set in LoadImage
       ;a0 to store the value of current pixel
       ;a1 to store width of image
       ;a2 to store height of image       
       
DrawPlayerSprite
    lea     PLAYER_SPRITE_SHEET,a0
;This snippet offsets the a0 to starting pixel of chunk to display 
    move.l  d2,d1  
    add.l   d4,d1                               ;add the y value of chunk to its height, to get the difference between the bottom row and the working row
    move.l  PLAYER_SHEET_HEIGHT,d0                ;put height of image into d0, so that we can subtract the y position of first pixel of chunk from it
    sub.l   d1,d0
    move.l  PLAYER_SHEET_WIDTH,d1                 ;multiply width to d0 to get the value of the corresponding byte to the start of row to print
    mulu    d1,d0
    lsl.l   #2,d0                               ;logical shift left by 2 bits to multiply d0 by 4, since the pixel is 4 bytes long.
    add.l   d0,a0
    move.l  d3,d0                               ;push x offset into d0. d0 is then multiplied by 4, because each pixel is 4 bytes long.
    lsl.l   #2,d0
    add.l   d0,a0                               ;add x value to a0 to get the position of the first pixel of chunk
        
;This snippet sets d7 to hold the padding between end of chunk and start of chunk of next row
    move.l  PLAYER_SHEET_WIDTH,d7                 ;move width of image into d7
    sub.w   d5,d7                               ;adding value of x to d7 will give the traversal to start of next row to print in chunk
    lsl.w   #2,d7

    add.l   8(sp),d2                            ;initialize d2 to the y-offset from the top of the screen
    add.l   4(sp),d5

.newRow
    move.l  4(sp),d6                            ;initialize x value to x-offset from the left of screen into d6. d1 will be used to set the value of the color pixel, so we will use d6 to manipulate the values.
.continue
    move.l  (a0)+,d1
    beq     .dontDraw                            ;if the value of pixel is #$00000000, then don't draw it.
    
    move.l  #PEN_COLOR_TRAP_CODE,d0
    trap    #15

    move.l  d6,d1                               ;move value of x to d1, to be used by trap code
    move.l  #DRAW_PIXEL_TRAP_CODE,d0
    trap    #15

.dontDraw    
    add.w   #1,d6                               ;increment value of x by 1
    cmp.l   d6,d5                               ;decrement x counter
    bne     .continue                           ;branch if end of row hasn't yet been traversed
    
    add.l   d7,a0                               ;apply padding to move the address of current pixel to point to the pixel in next row

    sub.w   #1,d2                               ;decrement y value (row) to move to the new row.
    cmp.l   8(sp),d2
    bne     .newRow                             ;branch if last row is yet to complete
    
    rts
    
    
*------------------------------------

PLAYER_SHEET_WIDTH        ds.l    1
PLAYER_SHEET_HEIGHT       ds.l    1
PLAYER_SHEET_COLOR_TABLE_ADDRESS  ds.l    1

PlayerSpriteSheet   INCBIN  "assets\BobbaFett_SpriteSheet.bmp"

PLAYER_SPRITE_SHEET    ds.l    98000










*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
