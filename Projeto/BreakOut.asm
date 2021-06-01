;*********************************************************************;
;---------------------------------------------------------------------; 
;  ___    ___    ____   ___             ___          _____            ;
; |   |  |   |  |      /   \  |  /     /   \  |   |    |    |  |  |   ;
; |__/   |__/   |__    |___|  | /      |   |  |   |    |    |  |  |   ;
; |  \   |  \   |      |   |  | \      |   |  |   |    |    |  |  |   ;
; |___|  |   |  |____  |   |  |  \     \___/  \___/    |    O  O  O   ;
;---------------------------------------------------------------------;
; Por Ian de Almeida Pinheiro,      19179;  z  2021, COTUCA,          :
;     Beatriz Gregório de Olivera,  19163;  z  Linguagem de Montagem, ;
;     Marcelo Gouvêa Sícoli,        19185.  z  Prof. Sérgio Luiz.     ;
;*********************************************************************; INÍCIO DO CÓDIGO!
.486                                                                       ; Declaracão da arquitetura mínima para o projeto.
.model flat, stdcall                                                       ; Definição do modelo de aquitetura como plano, sem segmentos.
option casemap :none                                                       ; Opção pelo uso padrão de sensibilidade capital.
; - INCLUDES - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ; -
include \masm32\include\masm32rt.inc                                       ; Parte do código em que incluiremos
include \masm32\include\windows.inc                                        ; as bibliotecas do MASM32 (montador
include \masm32\include\user32.inc                                         ; Assembly) que auxiliarão no 
include \masm32\include\kernel32.inc                                       ; desenvolvimento da interface 
include \MASM32\INCLUDE\gdi32.inc                                          ; gráfica e que contêm
includelib \masm32\lib\user32.lib                                          ; os recursos necessários ao
includelib \masm32\lib\kernel32.lib                                        ; suporte do nosso programa
includelib \MASM32\LIB\gdi32.lib                                           ; em Windows.
; - MACROS - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ; -
szText MACRO Name, Text:VARARG                                             ;
    LOCAL lbl                                                              ;
    jmp lbl                                                                ;
    Name db Text, 0                                                        ;
    lbl:                                                                   ;
ENDM                                                                       ;
; - PROTO PROCEDIMENTOS - - - - - - - - - - - - - - - - - - - - - - - - - -;
WinMain          PROTO :DWORD, :DWORD, :DWORD, :DWORD                      ;
WndProc          PROTO :DWORD, :DWORD, :DWORD, :DWORD                      ;
TopXY            PROTO :DWORD, :DWORD                                      ;
DesenhaRetangulo PROTO :DWORD, :DWORD, :DWORD, :DWORD                      ;
DesenhaTexto     PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD              ;
; - DATA - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ;
.data
    szDisplayName db "Mouse TI 501",0
    CommandLine   dd 0
    hWnd          dd 0
    hInstance     dd 0
    buffer        db 128 dup(0)
    X             dd 0
    Y             dd 0
    escolha       dd 1
; - DATA? - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;
.data?
    hitpoint    POINT <>        
    hitpointEnd POINT <>
; - CODE - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ;
.code
    start:
        invoke GetModuleHandle, NULL
        mov    hInstance, eax
        invoke GetCommandLine        
        mov    CommandLine, eax
        invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT    
        invoke ExitProcess,eax   
        ; CRIAÇÃO DA JANELA
        WinMain proc hInst     :DWORD,
                     hPrevInst :DWORD,
                     CmdLine   :DWORD,
                     CmdShow   :DWORD
            LOCAL wc  :WNDCLASSEX
            LOCAL msg :MSG
    
            LOCAL Wwd :DWORD
            LOCAL Wht :DWORD
            LOCAL Wtx :DWORD
            LOCAL Wty :DWORD
            
    
            szText szClassName,"Generic_Class"
            ; CORES AQUI
            mov wc.cbSize,         sizeof WNDCLASSEX
            mov wc.style,          CS_HREDRAW or CS_VREDRAW \
                                   or CS_BYTEALIGNWINDOW
            mov wc.lpfnWndProc,    offset WndProc     
            mov wc.cbClsExtra,     NULL
            mov wc.cbWndExtra,     NULL
            m2m wc.hInstance,      hInst             
            mov wc.hbrBackground,  COLOR_BTNFACE+1    
            mov wc.lpszMenuName,   NULL
            mov wc.lpszClassName,  offset szClassName  
    
            invoke LoadIcon,hInst, IDI_APPLICATION
            mov wc.hIcon,          eax
            invoke LoadCursor,NULL,IDC_ARROW       
            mov wc.hCursor,        eax
            mov wc.hIconSm,        0
    
            invoke RegisterClassEx, ADDR wc     
    
    
            invoke CreateWindowEx, WS_EX_OVERLAPPEDWINDOW, \
                                   ADDR szClassName, \
                                   ADDR szDisplayName,\
                                   WS_OVERLAPPEDWINDOW,\
                                   CW_USEDEFAULT,CW_USEDEFAULT, 800, 600, \
                                   NULL,NULL,\
                                   hInst,NULL
            mov   hWnd,eax 
    
            invoke LoadMenu,hInst,600        
            invoke SetMenu, hWnd, eax                
    
            invoke ShowWindow,  hWnd,SW_SHOWNORMAL  
            invoke UpdateWindow,hWnd                  
            
            invoke DesenhaRetangulo, 0, 0, 100, 540
            invoke DesenhaRetangulo, 700, 0, 800, 540
            invoke DesenhaRetangulo, 0, 0, 800, 120

            szText pontos1,"Pontos: 0"

            invoke DesenhaTexto, 300, 10, 400, 50, ADDR pontos1

            StartLoop:
                invoke GetMessage,ADDR msg,NULL,0,0     
                cmp eax, 0                                
                je ExitLoop                               
                invoke TranslateMessage, ADDR msg         
                invoke DispatchMessage,  ADDR msg       
                jmp StartLoop
            ExitLoop:
                return msg.wParam
        WinMain endp
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
        WndProc proc hWin   :DWORD,
                     uMsg   :DWORD,
                     wParam :DWORD,
                     lParam :DWORD
            LOCAL hDC    :DWORD
            LOCAL Ps     :PAINTSTRUCT
            LOCAL hWin2  :DWORD
            LOCAL rect   :RECT

            .if uMsg == WM_COMMAND 
                .if wParam == 1000       
                    mov escolha, 1
                .elseif wParam == 2000    
                    mov escolha, 2
                .elseif wParam == 3000  
                    mov escolha, 3
                .elseif wParam == 4000    
                    invoke SendMessage, hWin, WM_SYSCOMMAND, SC_CLOSE, NULL            
                .endif
            .elseif uMsg == WM_LBUTTONDOWN
                mov eax, lParam
                and eax, 0FFFFh 
                mov X, eax
                mov eax, lParam    
                shr eax, 16     
                mov Y, eax
            .elseif uMsg == WM_LBUTTONUP
                mov eax, lParam
                and eax, 0FFFFh
                mov hitpoint.x, eax
                mov eax, lParam    
                shr eax, 16      
                mov hitpoint.y, eax

            .elseif uMsg == WM_DESTROY
                invoke PostQuitMessage,NULL
                return 0 
            .elseif uMsg == WM_PAINT
                invoke BeginPaint,hWin,ADDR Ps
                jmp encerrar
                encerrar: 
                    invoke EndPaint,hWin,ADDR Ps
                return  0
            .endif   
            invoke DefWindowProc,hWin,uMsg,wParam,lParam 
            ret
        WndProc endp

        ;Procedimento para desenhar um retângulo
        DesenhaRetangulo proc x1:DWORD, 
                              y1:DWORD,
                              x2:DWORD,
                              y2:DWORD
            LOCAL hDC    :DWORD

            invoke GetDC, hWnd
            mov    hDC, eax

            invoke Rectangle, hDC, x1, y1, x2, y2

            invoke ReleaseDC, hWnd, hDC
            invoke InvalidateRect,hWnd,NULL,FALSE

            return 0
        DesenhaRetangulo endp

        DesenhaTexto proc x1:DWORD, 
                          y1:DWORD,
                          x2:DWORD,
                          y2:DWORD,
                         txt:DWORD
            LOCAL hDC  :DWORD
            LOCAL rect :RECT

            invoke GetDC, hWnd
            mov hDC, eax

            mov eax, x1
            mov rect.left, eax
            mov eax, y1
            mov rect.top, eax
            mov eax, x2
            mov rect.right, eax
            mov eax, y2
            mov rect.bottom, eax

            invoke DrawText, hDC, txt, -1, ADDR rect, \
            DT_SINGLELINE or DT_CENTER
            
            invoke ReleaseDC, hWnd, hDC
            invoke InvalidateRect,hWnd,NULL,FALSE
           ;invoke InvalidateRect,hWnd,rect,TRUE
            return 0
        DesenhaTexto endp
    end start