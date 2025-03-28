; -----------------------------------------------
; CONSTANTES
; -----------------------------------------------

data_ptr   equ  20h    ; Ponteiro para número a ser exibido
data_len   equ  4h     ; Número de dígitos
CONTADOR_EX0 EQU 40H   ; Contador para EX0

; -------------------------------------------------
; Definição de flag de emergência
; -------------------------------------------------
EMERGENCY_FLAG  BIT  21h     ; Flag de emergência

; -------------------------------------------------
; Definição de flag de 5 carros
; -------------------------------------------------
FIVE_PEOPLE_FLAG  BIT  22h   ; Flag de 5 Carros

; ----------------------
; Tabela de números para o display de 7 segmentos
; ----------------------
numbers: db  11000000b ; 0
         db  11111001b ; 1
         db  10100100b ; 2
         db  10110000b ; 3
         db  10011001b ; 4
         db  10010010b ; 5
         db  10000010b ; 6
         db  11111000b ; 7
         db  10000000b ; 8
         db  10010000b ; 9

; ----------------------
; Vetores de interrupção
; ----------------------
ORG 0000h
    JMP start

ORG 0003h
EX0_ISR:
    JB P0.2, CHAMA_INCREMENTA
    
    RETI

CHAMA_INCREMENTA:
    CALL INCREMENTA_EX0
    RETI

ORG 0013h
EX1_ISR:
    SETB EMERGENCY_FLAG   ; Ativa a flag de emergência
    CLR P0.4              ; Acende quarto LED indicando que a interrupção ocorreu
    RETI

ORG 0070h   ; Programa principal começa aqui

; -----------------------------------------------
; Delay de 1 segundo utilizando Timer 0
; -----------------------------------------------
delay_1s:
    mov TMOD, #01h    ; Modo 1 para o Timer 0 (16 bits)
    mov TH0, #0FFh    ; Byte de maior peso (TH0)
    mov TL0, #084h    ; Byte de menor peso (TL0)
    setb TR0          ; Inicia o Timer 0
    

wait_1s:
    jnb TF0, wait_1s  ; Espera até o TF0 ser setado
    clr TF0           ; Limpa a flag de overflow do Timer 0
    SETB P0.4
    ;SETB P0.5
    ret

    
;-------------------------------------------------
; INCREMENTA_EX0
; Incrementa o valor armazenado em CONTADOR_EX0
;-------------------------------------------------
INCREMENTA_EX0:
    PUSH ACC             ; Salva o valor original de A (Acumulador)
    MOV A, CONTADOR_EX0  ; Carrega o valor atual do contador
    INC A                ; Incrementa o acumulador
    MOV CONTADOR_EX0, A  ; Armazena o valor incrementado de volta em CONTADOR_EX0
    POP ACC              ; Restaura o valor original de A
    RET
    
; -----------------------------------------------
; VERIFICA_EX0
; Verifica se CONTADOR_EX0 >= 5 e reseta se necessário
; -----------------------------------------------
VERIFICA_EX0:
    MOV A, CONTADOR_EX0   ; Copia o contador para A
    CLR C                 ; Limpa o carry para a subtração
    SUBB A, #5            ; A = CONTADOR_EX0 - 5; se CONTADOR_EX0 >= 5, não haverá borrow
    JC CONTINUA_EX0       ; Se houve borrow (carry = 1), então CONTADOR_EX0 < 5, pula o tratamento

    ; Se chegou aqui, CONTADOR_EX0 >= 5
    CLR P0.5              ; Acende o LED em P0.5 (assumindo LED ativo em 0)
    MOV CONTADOR_EX0, #0  ; Reseta o contador
    SETB FIVE_PEOPLE_FLAG ; Ativa a flag de 5 pessoas

CONTINUA_EX0:
    RET

    
; ----------------------
; Rotinas auxiliares
; ----------------------

; -----------------------------------------------
; DECREMENTA O NÚMERO EXIBIDO NO DISPLAY
; -----------------------------------------------
decrement_number:
    ; Decrementa a unidade (data_ptr+0)
    mov A, data_ptr+0
    cjne A, #00h, continue_decrement_unidade
    mov A, #09h         ; Quando a unidade chegar a 00h, reinicia para 09h
    mov data_ptr+0, A   ; Atualiza unidade
    ; Decrementa a dezena (data_ptr+1)
    inc R0
    mov A, data_ptr+1
    cjne A, #00h, continue_decrement_dezena
    mov A, #09h         ; Quando a dezena chegar a 00h, reinicia para 09h
    mov data_ptr+1, A   ; Atualiza dezena
    ; Decrementa a centena (data_ptr+2)
    inc R0
    mov A, data_ptr+2
    cjne A, #00h, continue_decrement_centena
    mov A, #09h         ; Quando a centena chegar a 00h, reinicia para 09h
    mov data_ptr+2, A   ; Atualiza centena
    ; Decrementa o milhar (data_ptr+3)
    inc R0
    mov A, data_ptr+3
    cjne A, #00h, decrement_end
    mov A, #09h         ; Quando o milhar chegar a 00h, reinicia para 09h
    mov data_ptr+3, A   ; Atualiza milhar
decrement_end:
    ret

continue_decrement_unidade:
    dec data_ptr+0      ; Decrementa a unidade
    ret

continue_decrement_dezena:
    dec data_ptr+1      ; Decrementa a dezena
    ret

continue_decrement_centena:
    dec data_ptr+2      ; Decrementa a centena
    ret


; -----------------------------------------------
; Exibe o número no display de 7 segmentos
; -----------------------------------------------
display_number:
    CALL VERIFICA_EX0
    dec R0
    mov A, B
    rr A
    mov B, A
    mov A, @R0
    movc A, @A+DPTR
    mov P2, #0ffh
    mov P1, A
    mov P2, B
    cjne R0, #data_ptr, display_number
;    ACALL EX0_HANDLER
    SETB P0.5
    
    ret


; -----------------------------------------------
; Controle dos LEDs
; -----------------------------------------------
turn_off_leds:
    SETB P0.0			; DESLIGA O LED VERDE
    SETB P0.1			; DESLIGA O LED AMARELO
    SETB P0.2			; DESLIGA O LED VERMELHO
    ret

turn_on_green_led_10s:
    CLR P0.0			; LIGA O VERDE
    call countdown_10_seconds   ; Contagem regressiva de 10 segundos
    SETB P0.0			; DESLIGA O LED VERDE
    ret

turn_on_yellow_led_3s:
    CLR P0.1			; LIGA O LED AMARELO
    call countdown_3_seconds    ; Contagem regressiva de 3 segundos
    SETB P0.1			; DESLIGA O LED AMARELO
    ret

turn_on_red_led_7s:
    CLR P0.2			; LIGA O LED VERMELHO
    call countdown_7_seconds    ; Contagem regressiva de 7 segundos
    SETB P0.2			; DESLIGA O LED VERMELHO
    ret

turn_on_green_led_15s:
    CLR P0.0			; LIGA O LED VERDE
    call countdown_15_seconds   ; Contagem regressiva de 15 segundos
    SETB P0.0			; DESLIGA O LED VERDE
    ret

turn_on_red_led_15s:
    CLR P0.2			; LIGA O LED VERMELHO
    call countdown_15_seconds    ; Contagem regressiva de 15 segundos
    SETB P0.2			; DESLIGA O LED VERMELHO
    ret

; ----------------------
; Contador regressivo de 3 segundos
; ----------------------
countdown_3_seconds:
    mov data_ptr+0, #3  			; Inicializa como 3 segundos
    mov data_ptr+1, #0
    mov data_ptr+2, #0
    mov data_ptr+3, #0

countdown_3_loop:
    JB EMERGENCY_FLAG, emergency_mode 		; Verifica emergência primeiro
    mov R0, #data_ptr+data_len
    call display_number   			; Exibe o número
    call delay_1s        			; Atraso de 1 segundo
    mov R0, #data_ptr
    call decrement_number 			; Decrementa o número
    mov A, data_ptr+0
    orl A, data_ptr+1
    orl A, data_ptr+2
    orl A, data_ptr+3
    jnz countdown_3_loop 			; Continua até chegar a 0000
    ret 

; -------------------------------------------------
; Função que controla o sinal verde
; Se a flag de 5 pessoas estiver ativa, o sinal fica 15 segundos;
; caso contrário, 10 segundos.
; -------------------------------------------------
turn_on_green_led:
    SETB P3.2   ; Garante que P3.3 é configurado corretamente

    JB FIVE_PEOPLE_FLAG, five_people_mode  	; Verifica 5 pessoas primeiro
    CLR P0.0
    CALL turn_on_green_led_10s
    SJMP finish_green_led

five_people_mode:
    CLR P0.0
    CALL turn_on_green_led_15s
    CLR FIVE_PEOPLE_FLAG   			;  Flag limpa depois da contagem

finish_green_led:
    SETB P0.0
    RET
    
; -------------------------------------------------
; Função que controla o sinal vermelho
; Se a flag de emergência estiver ativa, o sinal fica 15 segundos;
; caso contrário, 7 segundos.
; -------------------------------------------------
turn_on_red_led:
    SETB P3.3   ; Garante que P3.3 é configurado corretamente

    JB EMERGENCY_FLAG, emergency_mode 		 ; Verifica emergência primeiro
    CLR P0.2
    CALL turn_on_red_led_7s
    SJMP finish_red_led

emergency_mode:
    SETB P0.0
    SETB P0.1
    CLR P0.2
    CALL turn_on_red_led_15s
    CLR EMERGENCY_FLAG   			;  Flag limpa depois da contagem

finish_red_led:
    SETB P0.2
    RET
    
; ----------------------
; Contador regressivo de 15 segundos
; ----------------------
countdown_15_seconds:
    mov data_ptr+0, #5  ; Unidade: 5 (15 segundos)
    mov data_ptr+1, #1  ; Dezena: 1 (15 segundos)
    mov data_ptr+2, #0  ; Centena: 0
    mov data_ptr+3, #0  ; Milhar: 0

countdown_15_loop:
    mov R0, #data_ptr+data_len
    call display_number   			; Exibe o número
    call delay_1s         			; Atraso de 1 segundo
    mov R0, #data_ptr
    call decrement_number 			; Decrementa o número
    mov A, data_ptr+0
    orl A, data_ptr+1
    orl A, data_ptr+2
    orl A, data_ptr+3
    jnz countdown_15_loop 			; Continua até chegar a 0000
    ret

; ----------------------
; Contador regressivo de 10 segundos
; ----------------------
countdown_10_seconds:
    mov data_ptr+0, #0  			; Inicializa como 10 segundos
    mov data_ptr+1, #1
    mov data_ptr+2, #0
    mov data_ptr+3, #0

countdown_10_loop:
    ;call verifica_ex0
    JB EMERGENCY_FLAG, emergency_mode  		; Verifica emergência primeiro
    JB FIVE_PEOPLE_FLAG, five_people_mode  	; Verifica 5 pessoas primeiro
    mov R0, #data_ptr+data_len
    call display_number   			; Exibe o número
    call delay_1s         			; Atraso de 1 segundo
    mov R0, #data_ptr
    call decrement_number 			; Decrementa o número
    mov A, data_ptr+0
    orl A, data_ptr+1
    orl A, data_ptr+2
    orl A, data_ptr+3 
    jnz countdown_10_loop 			; Continua até chegar a 0000
    ret

; ----------------------
; Contador regressivo de 7 segundos
; ----------------------
countdown_7_seconds:
    mov data_ptr+0, #7                 		; Inicializa como 7 segundos
    mov data_ptr+1, #0
    mov data_ptr+2, #0
    mov data_ptr+3, #0

countdown_7_loop:
    JB EMERGENCY_FLAG, emergency_mode  		; Verifica emergência primeiro
    mov R0, #data_ptr+data_len
    call display_number                		; Exibe o número
    call delay_1s                      		; Atraso de 1 segundo
    mov R0, #data_ptr
    call decrement_number              		; Decrementa o número
    mov A, data_ptr+0
    orl A, data_ptr+1
    orl A, data_ptr+2
    orl A, data_ptr+3
    jnz countdown_7_loop     		        ; Continua até chegar a 0000
    ret
    
; ----------------------
; Configuração Inicial
; ----------------------
start:

    MOV SP, #60h     ; Configura a pilha em um endereço seguro
    
    ; Configuração de pinos
    MOV P0, #0FFh    ; Inicializa P0 (LEDs)
    MOV P1, #0FFh    ; Inicializa P1
    MOV P2, #0FFh    ; Inicializa P2
    MOV P3, #0FFh    ; Inicializa P3

    ; Configurações de interrupção
    SETB EA          ; Habilita interrupções globais
    SETB EX1         ; Habilita interrupção externa 1
    SETB EX0         ; Habilita interrupção externa 0
    
    ; Configuração de tipo de borda
    SETB IT1         ; Configura interrupção para borda de descida
    SETB IT0         ; INT0 - borda de descida
    SETB PX1         ; Define interrupção externa 1 como alta prioridade
    CLR PX0          ; EX0 - BAIXA PRIORIDADE

    ; Inicializa contador
    MOV CONTADOR_EX0, #0

    mov data_ptr+0, #0  ; Unidade: 0
    mov data_ptr+1, #0  ; Dezena: 0
    mov data_ptr+2, #0  ; Centena: 0
    mov data_ptr+3, #0  ; Milhar: 0

    ; Configura pinos de entrada e saída
    SETB P3.3            ; Configura P3.3 como saída
    SETB P3.2            ; Configura P3.2 como saída

    mov B, #0EEh
    mov DPTR, #numbers

main:
    call turn_off_leds   	; Desliga todos os 3 LEDs
    call turn_on_green_led      ; Liga o LED verde por 3 segundos e depois desliga (se o modo de emergência não for acionado)
    call turn_on_yellow_led_3s  ; Liga o LED amarelo por 3 segundos e depois desliga
    call turn_on_red_led        ; Liga o LED vermelho por 7 segundos e depois desliga (se o modo de emergência não for acionado)
    jmp main
end

