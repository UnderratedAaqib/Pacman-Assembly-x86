include Irvine32.inc

.386
.model flat, stdcall
.stack 4096

ExitProcess PROTO, dwExitCode:DWORD

.data

menuText BYTE "WELCOME TO PACMAN .<", 0
menuOption1 BYTE "1. Start Game!", 0
menuOption2 BYTE "2. Exit", 0
menuPrompt BYTE "Enter your choice: ", 0

menuChoice BYTE ?


movementFunctions dd OFFSET movePCL, OFFSET movePCUp, OFFSET movePCR, OFFSET movePCDo
    mapSize dd 3719

fixRightTube db 0 ; set to 0FFh when right tube is traversed through, used to make tube traversal look nice
fixLeftTube db 0
    column dw 1
    pacmanChar db 'C'
gameClock dd 0
    pacmanPosition DWORD 100
dotsEaten db 0
    pacChar1 db ">" ; byte used to hold the leftmost character of pacman's face
pacChar2 db "'"
    XCoordPacMan db 28 ; byte used to hold the X-coordinate of PacMan
YCoordPacMan db 23
moveInst dd movePCL
; holds address of movePacman instruction to execute
moveCache dd movePCL
score dd 0
G1XCoord db 6 ; byte used to hold the X-coordinate of G1
G1YCoord db 17
flag db 0
G1LeftLimit dd ?
G1RightLimit dd ?
; G1moveCache dd MoveG1Left
G2XCoord db 28
G2YCoord db 11
G3XCoord db 28
G3YCoord db 11
G4XCoord db 28
G4YCoord db 11
wallCoordinatesXArray DB 56 DUP(0)
    wallCoordinatesYArray DB 56 DUP(0)
    wallCoordinatesCount DWORD ?
    maze    db "#######################################################", 0
db "# . . . . . . . . . . . . # # . . . . . . . . . . . . #", 0
db "# . ####### . ######### . # # . ######### . ####### . #", 0
db "# o #     # . #       # . # # . #       # . #     # o #", 0
db "# . ####### . ######### . ### . ######### . ####### . #", 0
db "# . . . . . . . . . . . . . . . . . . . . . . . . . . #", 0
db "# . ####### . ### . ############### . ### . ####### . #", 0
db "# . ####### . # # . ####### ####### . # # . ####### . #", 0
db "# . . . . . . # # . . . . # # . . . . # # . . . . . . #", 0
db "########### . # #######   # #   ####### # . ########## ", 0
db "          # . # #######   ###   ####### # . #          ", 0
db "          # . # #                     # # . #          ", 0
db "          # . # #   #####_____#####   # # . #          ", 0
db "########### . ###   #             #   ### . ###########", 0
db "#           .       #             #       .           #", 0
db "########### . ###   #             #   ### . ###########", 0
db "          # . # #   ###############   # # . #          ", 0
db "          # . # #                     # # . #          ", 0
db "          # . # #   ###############   # # . #          ", 0
db "########### . ###   ####### #######   ### . ###########", 0
db "# . . . . . . . . . . . . # # . . . . . . . . . . . . #", 0
db "# . ####### . ######### . # # . ######### . ####### . #", 0
db "# . ##### # . ######### . ### . ######### . # ##### . #", 0
db "# ~ . . # # . . . . . . .     . . . . . . . # # . . ~ #", 0
db "##### . # # . ### . ############### . ### . # # . #####", 0
db "##### . ### . # # . ####### ####### . # # . ### . #####", 0
db "# . . . . . . # # . . . . # # . . . . # # . . . . . . #", 0
db "# . ########### ####### . # # . ####### ########### . #", 0
db "# . ################### . ### . ################### . #", 0
db "# . . . . . . . . . . . . . . . . . . . . . . . . . . #", 0
db "#######################################################", 0


.code


  call ShowMenu
  jmp menuLoop

menuLoop:
    ; get user choice from menu
    call ReadChar
    mov menuChoice, al

    cmp menuChoice, "1"
    je startGame
    cmp menuChoice, "2"
    je exitGame

    jmp menuLoop

startGame:

    call Clrscr

 ;:: InitializeGame ::
; Called when pacman dies, or when the player reaches the next level
; Only called after map has been drawn or re-drawn
;
; Resets Pacman, G1, G2, G3 and G4 to starting positions
; Pacman: Where pacman would start in actual pacman
; G1: just outside of ghost pen
; G2, G3, G4: evenly spaced inside ghost pen

InitializeGame PROC

mov moveInst, OFFSET movePCL ; Start pacman off moving left
mov moveCache, OFFSET movePCL ; and make sure he stays moving left
mov gameClock, 0

mov XCoordPacMan, 28
mov YCoordPacMan, 23

mov pacChar1, ">" ; make pacman look like he is facing left, like his moveInst
mov pacChar2, "'"

mov G1XCoord, 13
mov G1YCoord, 20

mov G2XCoord, 22
mov G2YCoord, 14

mov G3XCoord, 26
mov G3YCoord, 14

mov G4XCoord, 30
mov G4YCoord, 14

call ShowPacman


; invoke sndPlaySound, offset beginSound, 0000 ; Play the start level jingle

call UnShowReady ; get rid of the red "R E A D Y" text
ret

InitializeGame ENDP


;:: ShowPacman ::
; shows pacman at the x and y coordinates stored in XCoordPacMan and YCoordPacMan respectively

ShowPacman PROC uses edx

mov eax, black+(yellow*16)
call SetTextColor ; set the text color to black with a yellow background

mov dl, XCoordPacMan
mov dh, YCoordPacMan
call Gotoxy ; move cursor to desired X and Y coordinate

movzx eax, pacChar1 ; for direction
call WriteChar ; SHOW ME THE MANS
movzx eax, pacChar2
call WriteChar

mov eax, 0Fh
call SetTextColor ; reset text color

ret

ShowPacman ENDP

;:: UNShowPacman ::
; un-shows pacman by printing two spaces at the x and y coordinates stored in XCoordPacMan and YCoordPacMan respectively

UnShowPacman PROC

mov dl, XCoordPacMan
mov dh, YCoordPacMan
call Gotoxy ; move cursor to desired X and Y coordinate

mov eax, 32 ; move the ascii code for space into eax to be printed
call WriteChar ; UNSHOW ME THE MANS
call WriteChar

ret

UnShowPacman ENDP

;:: movePCUp ::
; moves pacman up one space, if possible
; if that is not possible, do nothing and return a 1 in ebx

movePCUp PROC
    push edx
    movzx eax, YCoordPacMan   ;Y coordinate of pacman is in eax
    movzx ebx, XCoordPacMan  ;X coordinate of pacman is in ebx
    call CheckAbove
    call BoundaryCheck
    cmp ebx, 1
    je ENDUP
    call UnShowPacman
    mov pacChar1, 'v'
    mov pacChar2, ':'
    dec YCoordPacMan
    call ShowPacman
    ENDUP:
        pop edx
        ret
movePCUp ENDP


;:: movePCDo ::
; moves pacman down one space, if possible
; if that is not possible, do nothing and return a 1 in ebx
; see movePCUp for a more detailed instruction by instruction description

movePCDo PROC uses edx

movzx eax, YCoordPacMan
movzx ebx, XCoordPacMan
call CheckBelow

call BoundaryCheck
cmp ebx, 1
je ENDDOWN

KEEPMOVINGDOWN:
call UnShowPacman

mov pacChar1, 239
mov pacChar2, ':'
inc YCoordPacMan ; move down 1 Y-coordinate

call ShowPacman

ENDDOWN:
ret

movePCDo ENDP

;:: movePCL ::
; moves pacman left one space, if possible
; if that is not possible, do nothing and return a 1 in ebx
; see movePCUp for a more detailed instruction by instruction description

movePCL PROC uses edx

movzx eax, YCoordPacMan
movzx ebx, XCoordPacMan
call CheckLeft

call BoundaryCheck
cmp ebx, 1
je ENDLEFT

KEEPMOVINGLEFT:
call UnShowPacman

mov pacChar1, '>'
mov pacChar2, "'"
sub XCoordPacMan, 2 ; move left 1 X-coordinate

call ShowPacman

ENDLEFT:
ret

movePCL ENDP

;:: movePCR ::
; moves pacman right one space, if possible
; if that is not possible, do nothing and return a 1 in ebx
; see movePCUp for a more detailed instruction by instruction description

movePCR PROC uses edx

movzx eax, YCoordPacMan
movzx ebx, XCoordPacMan
call CheckRight

call BoundaryCheck
cmp ebx, 1
je ENDRIGHT

KEEPMOVINGRIGHT:
call UnShowPacman

mov pacChar1, "'"
mov pacChar2, '<'
add XCoordPacMan, 2 ; move right 1 X-coordinate

call ShowPacman

ENDRIGHT:
ret

movePCR ENDP

ShowCherry PROC

mov dh, 17
mov dl, 28
call GotoXY
; call PrintCherry

mov eax, 17
mov esi, OFFSET maze
mov ebx, LENGTHOF maze
mul ebx
mov ebx, 28
add eax, ebx
add esi, eax
mov bl, "%"
mov [esi], bl

mov eax, 17
mov ebx, 28
call CheckPos

ret

ShowCherry ENDP

;:: SHOWREADY ::
; Shows "R E A D Y" in red right under the ghost pen

SHOWREADY PROC

mov dh, 17
mov dl, 23
call GotoXY
mov eax, 12
call SetTextColor
;mov edx, OFFSET ready
call WriteString

mov eax, 8
call SetTextColor

ret

SHOWREADY ENDP

;:: UNSHOWREADY ::
; Prints 9 spaces under the ghost pen where "R E A D Y" would be

UNSHOWREADY PROC

mov dh, 17
mov dl, 23
call GotoXY
mov eax, " "
mov ecx, 9
UNSHOWTHEREADY:
call WriteChar
loop UNSHOWTHEREADY

ret

UNSHOWREADY ENDP

;:: CHECKABOVE ::
; returns the character above coordinate (x, y) in the map in eax
; eax = y coordinate
; ebx = x coordinate

CheckAbove PROC uses esi

dec eax
call CheckPos

ret

CheckAbove ENDP

;:: CHECKBELOW ::
; returns the character below coordinate (x, y) in the map in eax
; eax = y coordinate
; ebx = x coordinate

CheckBelow PROC

inc eax
call CheckPos

ret

CheckBelow ENDP

;:: CHECKLEFT ::
; returns the character to the left of coordinate (x, y) in the map in eax
; eax = y coordinate
; ebx = x coordinate

CheckLeft PROC

sub ebx, 2
call CheckPos

ret

CheckLeft ENDP

;:: CHECKRIGHT ::
; returns the character to the right of coordinate (x, y) in the map in eax
; eax = y coordinate
; ebx = x coordinate

CheckRight PROC

add ebx, 2
call CheckPos

ret

CheckRight ENDP

;:: CHECKPOS ::
; returns the character at coordinate (x, y) in the map in eax
; eax = y coordinate
; ebx = x coordinate

CheckPos PROC

mov esi, OFFSET maze
push ebx
mov ebx, LENGTHOF maze
mul ebx
pop ebx
add eax, ebx
add esi, eax
mov al, [esi]

ret

CheckPos ENDP

;:: BoundaryCheck ::
; eax = character to check
; checks to see if the character in eax is a character that can be moved across

BoundaryCheck PROC

cmp al, ' '
je ValidMove

cmp al, '.'
je ValidMove

cmp al,'o'
je ValidMove

cmp al, '#'
je InvalidMove

cmp al, '_'
je InvalidMove

InvalidMove:

mov ebx, 1

ValidMove:

ret

BoundaryCheck ENDP

;;GHOST 1 logic
; G1 ROW
G1Row equ 17  ; Set the row number for G1

;:: SHOWG1 ::
ShowG1 PROC
    mov eax, white + (lightred * 16) ; G1 has white eyes with a light red background
    call SetTextColor

    mov dl, G1XCoord
    mov dh, G1YCoord
    call Gotoxy ; move cursor to G1's x and y coordinate

    mov eax, 248 ; Ghost eyes are degree symbols
    call WriteChar ; Most living things have 2 eyes
    call WriteChar ; Although the ghosts are ghosts, so technically they're no longer living

    mov eax, 0Fh ; reset text color
    call SetTextColor

    ret
ShowG1 ENDP


ShowMenu PROC
    mov eax, 3
    call setTextColor

    ; Display menu
    mov edx, OFFSET menuText
    call WriteString
    call crlf

    mov edx, OFFSET menuOption1
    call WriteString
    call crlf

    mov edx, OFFSET menuOption2
    call WriteString
    call crlf

    ; Prompt user for choice
    mov edx, OFFSET menuPrompt
    call WriteString
    ret
ShowMenu ENDP

;:: UNSHOWG1 ::
UnShowG1 PROC
    mov dl, G1XCoord
    mov dh, G1YCoord
    call Gotoxy ; move cursor to desired X and Y coordinate

 
    ; Check if the current position is in G1's row (G1Row)
mov al,' '
call WriteChar
call WriteChar
    ret
UnShowG1 ENDP

;:: G1THINK ::
G1Think PROC
   
    mov G1YCoord, G1Row ; Set G1's row

G1ThinkLoop:

cmp flag,1
je G1ReverseDirection
   

call ShowG1 ; Show G1 at the current position
    call Delay ; Introduce a delay for visibility

    ;call UnShowG1 ; Unshow G1 at the current position
    ; Move G1 to the right in its row
cmp flag,1
call UnShowG1
je G1ReverseDirection

    inc G1XCoord
call ShowG1
    cmp G1XCoord, 36; Check if G1 reached the rightmost position
    je G1ReverseDirection ; If yes, reverse the direction

ret
G1ReverseDirection:
    ; Move G1 to the left in its row

mov flag,1
;call unShowG1
call showG1
call Delay
call unShowG1
    dec G1XCoord

call ShowG1
call Delay
    cmp G1XCoord, 13 ; Check if G1 reached the leftmost position
je fla
je G1ThinkLoop ; If yes, go back to moving to the right

ret
fla:
mov flag,0
ret
G1Think ENDP

ControlLoop PROC uses eax

mov edx, 0141h
call Gotoxy
mov eax, score
call WriteDec ; show the score in the top right corner of the screen

cmp gameClock, 150 ; if the gameClock is at 150, show the cherry where it should be
; jne DONTSHOWCHERRY
call ShowCherry

call ReadKey ; read from keyboard input buffer

cmp eax, 4B00h ; on left arrow key press
je MOVELEFT

cmp eax, 4800h ; on up arrow key press
je MOVEUP

cmp eax, 4D00h ; on right arrow key press
je MOVERIGHT

cmp eax, 5000h ; on down arrow key press
je MOVEDOWN

jmp TRYMOVE

MOVELEFT:
    mov esi,offset movementFunctions     ; Load the base address of the array
    mov ecx, [esi]                 ; Get the address of movePCL
    mov moveInst, ecx              ; Store the address in moveInst
    jmp TRYMOVE

MOVEUP:
    mov esi,offset movementFunctions     ; Load the base address of the array
    mov ecx, [esi + 4]             ; Get the address of movePCUp
    mov moveInst, ecx              ; Store the address in moveInst
    jmp TRYMOVE

    MOVERIGHT:
    mov esi,offset movementFunctions     ; Load the base address of the array
    mov ecx, [esi + 8]             ; Get the address of movePCR
    mov moveInst, ecx              ; Store the address in moveInst
    jmp TRYMOVE

    MOVEDOWN:
    mov esi,offset movementFunctions     ; Load the base address of the array
    mov ecx, [esi + 12]            ; Get the address of movePCDo
    mov moveInst, ecx              ; Store the address in moveInst
   
jmp TRYMOVE
TRYMOVE:
mov eax, moveInst
call NEAR PTR eax ; Try executing moveInst
cmp ebx, 1 ; If moveInst failed
je PACCANTGOTHERE ; Pacman can't go there

mov eax, moveInst ; Move desired instruction back into eax
mov moveCache, eax ; Movement succeeded, store the movement we just made in moveCache
jmp ENDMOVEMENT ; you did it

PACCANTGOTHERE:
mov eax, moveCache ; move the cached movement into eax (we know it will execute because it was stored in the cache in the first place, see above)
call NEAR PTR eax ; DOIT

ENDMOVEMENT:

; call IsPacKill ; Check to see if Pacman is dead

; call G1Think ; make all of the ghosts think once
; call G2Think
; call G3Think
; call G4Think

cmp gameClock, 50 ; if gameClock = 50, summon G2
jne DONTSUMMONG2
; call SummonG2

DONTSUMMONG2:

cmp gameClock, 100 ; if gameClock = 100, summon G3
jne DONTSUMMONG3
; call SummonG3

DONTSUMMONG3:

cmp gameClock, 150 ; if gameClock = 150, summon G4
jne DONTSUMMONG4
; call SummonG4

DONTSUMMONG4:

movzx eax, YCoordPacMan
movzx ebx, XCoordPacMan
call CheckPos ; it's time to do some scoring
mov edx, " "

cmp al, "." ; if pacman is on top of a dot
je SCOREDOT

cmp al, "o" ; if pacman is on top of a power pellet
je SCOREBIGDOT



cmp al, "%" ; if pacman is on top of a cherry
je SCORECHERRY


jmp ENDCHARCHECK

SCOREDOT : ; DOT SCORING
add score, 10 ; add 10 to score
inc dotsEaten ; increment dots eaten
mov [esi], dl ; put a space where the dot was in theMap
; cmp shouldWaka, 1 ; if ShouldWaka is 1
je doTheWaka ; waka
; inc shouldWaka ; increment shouldWaka
jmp ENDCHARCHECK

doTheWaka :
; invoke sndPlaySound, offset wakaSound, 0001 ; play a waka
; dec shouldWaka
jmp ENDCHARCHECK
 
SCOREBIGDOT :
add score, 50 ; add 50 to score
inc dotsEaten ; increment dots eaten
mov [esi], dl ; put a space where the power pellet was in theMap
; mov shouldWaka, -2 ; don't waka
; invoke sndPlaySound, offset bigDotSound, 0001 ; play power pellet sound
jmp ENDCHARCHECK
 
SCORECHERRY :
add score, 100 ; add 100 to score
mov [esi], dl ; put a space where the cherry was in theMap
; mov shouldWaka, 1 ; don't waka
; invoke sndPlaySound, offset cherrySound, 0001 ; play cherry sound
jmp ENDCHARCHECK



ENDCHARCHECK:

; call IsPacKill ; check to see if pacman is dead

; cmp dotsEaten, 244 ; if pacman atw 244 pellets
; jne KEEPEATING
mov eax, 1000
call Delay ; pause for emphasis
; call NextLevel ; start the next level

KEEPEATING:

inc gameClock ; increment the game clock with every iteration of ControlLoop
ret

ControlLoop ENDP


main PROC
   call Clrscr
   mov eax, 3
   call setTextColor
   mov esi, offset maze
   l3:
   mov ecx, 56 ; Number of rows in the maze
   
    mov dx,1

    L1:
        ; Display maze background
        mov eax, 0
        mov al, [esi]  ; Load the current character
        cmp dx,57        ; Check if the character is the null terminator
        je LineBreak      ; If it is, move to the next line

        call WriteChar
        inc esi
        inc dx
       
        mov bx,column
        cmp bx,32
        je exit1
        loop L1
    LineBreak:
        call crlf
        inc column
        jmp l3
    exit1:      
         
       
         mov eax, 7
        call setTextColor
        mov dl, 0
        mov dh, 30
        call Gotoxy
       
call InitializeGame
LOOPP:
call G1Think
call ControlLoop
mov eax, 10
call Delay
jmp LOOPP

       
        jmp ExitGame
       
 

    ; Display menu title
    mov edx, OFFSET menuTitle
    call WriteString
    call Crlf

    ; Display menu options
    mov edx, OFFSET option1
    call WriteString
    call Crlf

    mov edx, OFFSET option2
    call WriteString
    call Crlf

    mov edx, OFFSET option3
    call WriteString
    call Crlf

    mov eax, 7
    call setTextColor

    ; Get user choice
    mov edx, OFFSET choice
    call ReadInt

    ; Process user choice
    cmp dword ptr [choice], 1
    je  startGame
    cmp dword ptr [choice], 2
    je  showInstructions
    cmp dword ptr [choice], 3
    je  exitGame

    ; Invalid choice
    jmp main



startGame:

    jmp main

showInstructions:
    ; Display game instructions
    ; Replace this with your actual instructions
    ; ...

    ; After displaying instructions, return to the menu
    jmp main

ExitGame:

main ENDP

END main