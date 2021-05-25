      .486    
      .model flat, stdcall  
      option casemap :none 
    
      include \masm32\include\masm32rt.inc

      ; INCLUDES
      include \masm32\include\windows.inc
      include \masm32\include\user32.inc
      include \masm32\include\kernel32.inc
      include \MASM32\INCLUDE\gdi32.inc

      includelib \masm32\lib\user32.lib
      includelib \masm32\lib\kernel32.lib
      includelib \MASM32\LIB\gdi32.lib
; MACROS
 
    szText MACRO Name, Text:VARARG
    LOCAL lbl
          jmp lbl
            Name db Text,0
          lbl:
    ENDM

; PROCEDIMENTOS PROTO

     WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
     WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
     TopXY PROTO   :DWORD,:DWORD

.data
        szDisplayName db "Mouse TI 501",0
        CommandLine   dd 0
        hWnd          dd 0
        hInstance     dd 0
        buffer        db 128 dup(0)
        X             dd 0
        Y             dd 0
        escolha         dd 1


.data?

    hitpoint    POINT <>        
    hitpointEnd POINT <>

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

    LOCAL wc   :WNDCLASSEX
    LOCAL msg  :MSG

    LOCAL Wwd  :DWORD
    LOCAL Wht  :DWORD
    LOCAL Wtx  :DWORD
    LOCAL Wty  :DWORD

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


    invoke CreateWindowEx,WS_EX_OVERLAPPEDWINDOW, \
                          ADDR szClassName, \
                          ADDR szDisplayName,\
                          WS_OVERLAPPEDWINDOW,\
                          CW_USEDEFAULT,CW_USEDEFAULT, 400, 200, \
                          NULL,NULL,\
                          hInst,NULL

    mov   hWnd,eax 

    invoke LoadMenu,hInst,600        
    invoke SetMenu,hWnd,eax                

    invoke ShowWindow,hWnd,SW_SHOWNORMAL  
    invoke UpdateWindow,hWnd              


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

WndProc proc hWin   :DWORD,
             uMsg   :DWORD,
             wParam :DWORD,
             lParam :DWORD

    LOCAL hDC    :DWORD
    LOCAL Ps     :PAINTSTRUCT
    LOCAL hWin2  :DWORD

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
        invoke InvalidateRect,hWnd,NULL,FALSE

    .elseif uMsg == WM_DESTROY
        invoke PostQuitMessage,NULL
        return 0 
    .elseif uMsg == WM_PAINT
        invoke BeginPaint,hWin,ADDR Ps
        mov hDC, eax
        cmp escolha, 1
        je casoReta

        cmp escolha, 2
        je casoRetangulo

        cmp escolha, 3
        je desenharCirculo

        casoReta:     
            invoke MoveToEx, hDC, hitpoint.x,hitpoint.y,0
            invoke LineTo, hDC, X, Y
            jmp encerrar

        casoRetangulo: 
            invoke Rectangle, hDC, X, Y, hitpoint.x,hitpoint.y
            jmp encerrar
        
        desenharCirculo:  
            invoke Arc, hDC, X, Y, hitpoint.x,hitpoint.y, 0, 0, 0, 0

        encerrar: 
            invoke EndPaint,hWin,ADDR Ps
        return  0
    .endif   
    invoke DefWindowProc,hWin,uMsg,wParam,lParam 
    ret
WndProc endp

end start