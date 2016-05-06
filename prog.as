;===============================================================================
; Programa prog.as
; Laboratório 3 de Arquitectura de Computadores
; 
; Alunos:
;     Henrique Nogueira 78927
;     João Martins      84092
;
; Professor Paulo Lopes
;===============================================================================

;===============================================================================
; ZONA I: Definicao de constantes
;         Pseudo-instrucao : EQU
;===============================================================================

; TEMPORIZACAO
DELAYVALUE      EQU     F000h

; STACK POINTER
SP_INICIAL      EQU     FDFFh

; I/O a partir de FF00H
IO_CURSOR       EQU     FFFCh
IO_WRITE        EQU     FFFEh
IO_PRESSED      EQU     FFFDh
IO_READ         EQU     FFFFh

LIMPAR_JANELA   EQU     FFFFh
XY_INICIAL      EQU     0000h
FIM_TEXTO       EQU     '@'

INICIAL_AST     EQU     0C28h             ; posicao inicial asterisco (12,40)

;===============================================================================
; ZONA II: Definicao de variaveis
;          Pseudo-instrucoes : WORD - palavra (16 bits)
;                              STR  - sequencia de caracteres.
;          Cada caracter ocupa 1 palavra
;===============================================================================

                ORIG    8000h
VarTexto1       STR     'Jogo:',FIM_TEXTO
POSICAO_AST     WORD    INICIAL_AST       ; posição actual do asterisco, inicializada
					  ;	em (12, 40)
CURSOR_POSITION WORD    004Fh             ; posição actual do cursor NumberWrite

;===============================================================================
; ZONA III: Codigo
;           conjunto de instrucoes Assembly, ordenadas de forma a realizar
;           as funcoes pretendidas
;===============================================================================
                ORIG    0000h
                JMP     inicio

;===============================================================================
; LimpaJanela: Rotina que limpa a janela de texto.
;               Entradas: --
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

LimpaJanela:    PUSH    R2
                MOV     R2, LIMPAR_JANELA
		MOV     M[IO_CURSOR], R2
                POP     R2
                RET

;===============================================================================
; EscString: Rotina que efectua a escrita de uma cadeia de caracter, terminada
;            pelo caracter FIM_TEXTO, na janela de texto numa posicao 
;            especificada. Pode-se definir como terminador qualquer caracter 
;            ASCII. 
;               Entradas: pilha - posicao para escrita do primeiro carater 
;                         pilha - apontador para o inicio da "string"
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

EscString:      PUSH    R1
                PUSH    R2
		PUSH    R3
                MOV     R2, M[SP+6]   ; Apontador para inicio da "string"
                MOV     R3, M[SP+5]   ; Localizacao do primeiro carater
Ciclo:          MOV     M[IO_CURSOR], R3
                MOV     R1, M[R2]
                CMP     R1, FIM_TEXTO
                BR.Z    FimEsc
                CALL    EscCar
                INC     R2
                INC     R3
                BR      Ciclo
FimEsc:         POP     R3
                POP     R2
                POP     R1
                RETN    2                ; Actualiza STACK

;===============================================================================
; EscCar: Rotina que efectua a escrita de um caracter para o ecran.
;         O caracter pode ser visualizado na janela de texto.
;               Entradas: R1 - Caracter a escrever
;               Saidas: ---
;               Efeitos: alteracao da posicao de memoria M[IO]
;===============================================================================

EscCar:         MOV     M[IO_WRITE], R1
                RET                     

;===============================================================================
; Delay: Rotina que permite gerar um atraso
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

Delay:          PUSH    R1
                MOV     R1, DELAYVALUE
DelayLoop:      DEC     R1
                BR.NZ   DelayLoop
                POP     R1
                RET
;===============================================================================
; NumberWrite: Escrever um número dado em R1 na posição CURSOR_POSITION
;               Entradas: R1 - número a escrever
;               Saidas: ---
;               Efeitos: Alteracao da posicao de memoria M[IO]
;===============================================================================
NumberWrite:    PUSH    R2
                PUSH    R3
                PUSH    R5
                PUSH    R4
                PUSH    R1

                MOV     R3, R1
                MOV     R5, M[CURSOR_POSITION]

                MOV     R4, 0006h        ; subrotina para limpar espaço a escrever
					 ; limpa 6 caracteres (-65537)
numberclean:   	MOV     M[IO_CURSOR], R5
                MOV     R1, ' '
                CALL    EscCar
                DEC     R5
                DEC     R4
                BR.NZ   numberclean
		
                MOV     R5, M[CURSOR_POSITION]
                CMP     R3, 0000h        ; caso o número seja negativo, usar módulo
                BR.NN   divloop
                NEG     R3

divloop:        MOV     R2, 000Ah	
                DIV     R3, R2        ; resto da divisão em R2, divisao inteira em R3
                MOV     R1, R2
                ADD     R1, '0'
                MOV     M[IO_CURSOR], R5
                DEC     R5
                CALL    EscCar
                CMP     R3, 0000h
                BR.NZ   divloop

                POP     R1
                PUSH    R1

                CMP     R1, 0000h     ; caso número negativo, escrever sinal -
                BR.NN   endNumwrite
                MOV     M[IO_CURSOR], R5
                MOV     R1, '-'
                CALL    EscCar
endNumwrite:	POP     R1
                POP     R4
                POP     R5
                POP     R3
                POP     R2
                RET

;===============================================================================
; ColunaLinha:  Decompõe o número dado por R1 em coluna/linha e escreve
;               Entradas: R1 - número com a posição
;               Saidas: ---
;               Efeitos: Alteracao da posicao de memoria M[IO]
;===============================================================================
ColunaLinha:    PUSH    R7
                PUSH    R5
                MOV     R5, R1

                SHRA    R1, 8
                MOV     R7, 004Fh
                MOV     M[CURSOR_POSITION], R7
                CALL    NumberWrite

                MOV     R1, R5
                AND     R1, 00FFh            ; isolar bits coluna

                AND     R5, 0080h            ; verificar se coluna positiva
                CMP     R5, 0080h
                BR.NZ   colWrite
                OR      R1, FF00h

colWrite:    MOV     R7, 014Fh
                MOV     M[CURSOR_POSITION], R7
                CALL    NumberWrite

                POP     R5
                POP     R7
                RET

;===============================================================================
; MoveAsterisco: Rotina responsável por mover o caracter asterisco com base
;                no input do teclado
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================
MoveAsterisco:  PUSH    R2 
                PUSH    R1
                PUSH    R5
                PUSH    R6
                PUSH    R7

                MOV     R5, M[POSICAO_AST]

                MOV     R2, M[IO_READ]             ; qual a tecla primida
                CMP     R2, 's'
                BR.NZ   nots
                ADD     R5, 0100h
                BR      testcolision
nots:           CMP     R2, 'w'
                BR.NZ   notw
                SUB     R5, 0100h
                BR      testcolision
notw:           CMP     R2, 'd'
                BR.NZ   notd
                ADD     R5, 0001h 
                BR      testcolision
notd:           CMP     R2, 'a'
                BR.NZ   ignoreMove
                SUB     R5, 0001h

testcolision:   CMP     R5, 0005h                ; evitar colisão com jogo
                BR.NN   nocolision
                CMP     R5, FFFFh
                BR.N    nocolision
                BR      ignoreMove

nocolision:     MOV     R6, M[POSICAO_AST]       	
                MOV     M[IO_CURSOR], R6         ; apagar posicao actual 
                MOV     R1, ' ' 
                CALL    EscCar

                MOV     R1, R5                   ; escrever posicao linha
                Call    ColunaLinha

                MOV     M[IO_CURSOR], R5
                MOV     M[POSICAO_AST], R5
                MOV     R1, '*'
                CALL    EscCar

ignoreMove:     POP     R7
                POP     R6
                POP     R5
                POP     R1
                POP     R2

                RET

;===============================================================================
;                                Programa prinicipal
;===============================================================================
inicio:         MOV     R1, SP_INICIAL
                MOV     SP, R1

                CALL    LimpaJanela
                PUSH    VarTexto1           
                PUSH    XY_INICIAL          
                CALL    EscString               ; escrever string "Jogo:"

                MOV     R1, M[POSICAO_AST]
                MOV     M[IO_CURSOR], R1
                MOV     R1, '*'
                CALL    EscCar                  ; escrever asterico pos. ini.

                MOV     R1, M[POSICAO_AST]
                CALL    ColunaLinha             ; escrever posição, (linha,coluna) 
        
mainloop:       MOV     R2, M[IO_PRESSED]       ; verificar se existem caracteres por ler
                CMP     R2, 0001h
                BR.NZ   mainloop                ; chamar MoveAsterisco se tecla primida
                
                CALL    MoveAsterisco
                BR      mainloop
		

Fim:            BR Fim
;===============================================================================


