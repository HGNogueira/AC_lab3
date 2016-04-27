;===============================================================================
; Programa prog.as
; Laborat�rio 3 de Arquitectura de Computadores
; 
; Alunos:
;     Henrique Nogueira 78927
;     Jo�o Martins      -----
;
; Professor Paulo Pontes
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

INICIAL_AST     EQU     0C28h

;===============================================================================
; ZONA II: Definicao de variaveis
;          Pseudo-instrucoes : WORD - palavra (16 bits)
;                              STR  - sequencia de caracteres.
;          Cada caracter ocupa 1 palavra
;===============================================================================

                ORIG    8000h
VarTexto1       STR     'Jogo:',FIM_TEXTO
POSICAO_AST     WORD    INICIAL_AST       ; posi��o actual do asterisco, inicializada
					  ;	em (12, 40)
CURSOR_POSITION WORD    004Fh             ; posi��o actual do cursor NumberWrite

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
; NumberWrite: Escrever um n�mero dado em R1 na posi��o CURSOR_POSITION
;               Entradas: R1 - n�mero a escrever
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

		MOV     R4, 0006h        ; subrotina para limpar espa�o a escrever
					 ; limpa 6 caracteres (-65537)
numberclean:   	MOV     M[IO_CURSOR], R5
		MOV     R1, ' '
		CALL    EscCar
		DEC     R5
		DEC     R4
		BR.NZ   numberclean
		
		MOV     R5, M[CURSOR_POSITION]
		CMP     R3, 0000h        ; caso o n�mero seja negativo, usar m�dulo
		BR.NN   Divloop
		NEG     R3

Divloop:        MOV     R2, 000Ah	
		DIV     R3, R2        ; resto da divis�o em R2, divisao inteira em R3
		MOV     R1, R2
		ADD     R1, '0'
		MOV     M[IO_CURSOR], R5
		DEC     R5
		CALL    EscCar
		CMP     R3, 0000h
		BR.NZ   Divloop

		POP     R1
		PUSH    R1

		CMP     R1, 0000h     ; caso n�mero negativo, escrever sinal -
		BR.NN   ENDnumwrite
		MOV     M[IO_CURSOR], R5
		MOV     R1, '-'
		CALL    EscCar
ENDnumwrite:	POP     R1
		POP     R4
		POP     R5
		POP     R3
		POP     R2
                RET

;===============================================================================
;                                Programa prinicipal
;===============================================================================
inicio:         MOV     R1, SP_INICIAL
                MOV     SP, R1

                CALL    LimpaJanela
                PUSH    VarTexto1           ; Passagem de parametros pelo STACK
                PUSH    XY_INICIAL          ; Passagem de parametros pelo STACK
                CALL    EscString

		MOV     R1, INICIAL_AST
		MOV     M[IO_CURSOR], R1
		MOV     R1, '*'
		CALL    EscCar
		MOV     R5, INICIAL_AST

		MOV     R1, M[POSICAO_AST]
		CALL    NumberWrite
	
mainloop:       MOV     R2, M[IO_PRESSED]        ; verificar se existem caracteres por ler
		CMP     R2, 0001h
		BR.NZ   mainloop

		MOV     R2, M[FFFFh]             ; qual a tecla pressed

		CMP     R2, 's'
		BR.NZ   nots
		ADD     R5, 0100h
		BR      writechanges
nots:           CMP     R2, 'w'
		BR.NZ   notw
		SUB     R5, 0100h
		BR      writechanges
notw:           CMP     R2, 'd'
		BR.NZ   notd
		ADD     R5, 0001h 
		BR      writechanges
notd:           CMP     R2, 'a'
		BR.NZ   mainloop
		SUB     R5, 0001h

writechanges:   MOV     R6, M[POSICAO_AST]       	
		MOV     M[IO_CURSOR], R6         ; apagar posicao actual 
		MOV     R1, ' ' 
		CALL    EscCar
		CMP     R5, 0005h                ; evitar colis�o com jogo
		BR.NN   nocolision
		CMP     R5, FFFFh
		BR.N    nocolision
		MOV     R5, M[POSICAO_AST]

nocolision:     MOV     R1, R5                   ; escrever posicao linha
		SHR     R1, 2
		AND     R1, 00FFh
		MOV     R7, 004Fh
		MOV     M[CURSOR_POSITION], R7
		CALL    NumberWrite
		MOV     R1, R5
		AND     R1, 00FFh                ; escrever posicao coluna
		MOV     R7, 014Fh
		MOV     M[CURSOR_POSITION], R7
		CALL    NumberWrite

		MOV     M[IO_CURSOR], R5
		MOV     M[POSICAO_AST], R5
		MOV     R1, '*'
		CALL    EscCar
		POP     R2                       ; evitar incremento infinito do stack
                CALL    mainloop
		

Fim:            BR Fim
;===============================================================================


