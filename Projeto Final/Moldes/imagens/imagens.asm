    .386                   ; minimum processor needed for 32 bit
    .model flat, stdcall   ; FLAT memory model & STDCALL calling
    option casemap :none   ; set code to case sensitive
      ; ---------------------------------------------
      include \masm32\include\windows.inc
      ; -------------------------------------------------------------
      include \masm32\include\user32.inc
      include \masm32\include\kernel32.inc
      include \MASM32\INCLUDE\gdi32.inc
	    include \Masm32\include\winmm.inc 

      INCLUDE \Masm32\Include\msimg32.inc
      INCLUDE \Masm32\Include\oleaut32.inc

      includelib \masm32\lib\user32.lib
      includelib \masm32\lib\kernel32.lib
      includelib \MASM32\LIB\gdi32.lib
    INCLUDELIB \Masm32\Lib\msimg32.lib
    INCLUDELIB \Masm32\Lib\oleaut32.lib	  
      includelib \Masm32\lib\winmm.lib

   szText MACRO Name, Text:VARARG
        LOCAL lbl
          jmp lbl
            Name db Text,0
          lbl:
        ENDM


      m2m MACRO M1, M2
        push M2
        pop  M1
      ENDM

      return MACRO arg
        mov eax, arg
        ret
      ENDM

  RGB macro red,green,blue
        xor eax,eax
        mov ah,blue
        shl eax,8
        mov ah,green
        mov al,red
	endm

    WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
    WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
    TopXY PROTO   :DWORD,:DWORD      

    PlaySound	PROTO	STDCALL :DWORD, :DWORD, :DWORD

    Paint_Proc   PROTO :DWORD,:DWORD

	  CbTimer      PROTO :DWORD,:DWORD,:DWORD,:DWORD


    .const		
		WM_FINISH equ WM_USER+100h  ; o numero da mensagem é a ultima + 100h
		WM_EVENTO equ WM_FINISH+1   ; o numero da mensagem é a ultima + 1
    WM_DESENHO equ WM_FINISH+2
	  b2			equ		111

	  CREF_TRANSPARENT  EQU 0FF00FFh
  	CREF_TRANSPARENT2 EQU 0FF0000h

    ID_TIMER    EQU   2
    MS          EQU   50 

    .data
        szDisplayName db "Tocando Sons",0
        CommandLine   dd 0
        hWnd          dd 0
        hInstance     dd 0
		msgtxt         db "Stop Playing",0
		msgtitle       db "Poor Player ver.0.0",0 

        Play	  db "Meow.wav",0		; Sound file
        Play1	  db "02explosion_nave.wav",0		; Sound file
		Play2	  db "03game_over.wav",0		; Sound file
		Play3	  db "04laser_shot.wav",0		; Sound file

      hBmp1   dd 0
      hBmp2   dd 0

      missilAtual   dd 0
      missilPos     POINT <>
; dados para texto na tela
      format db 'Posicao  %d', 0 ; formatando string e inteiro
	    buffer db  20 dup (0)

      posicao POINT <>


    .data?
        threadID    DWORD ?  
        hEventStart HANDLE ?

        threadID1    DWORD ?          		
		hEventP1 HANDLE ?
		hEventP2 HANDLE ?
		hEventP3 HANDLE ? 

.code

start:
    invoke GetModuleHandle, NULL ; provides the instance handle
    mov hInstance, eax

    invoke LoadBitmap,hInstance, b2
    mov hBmp2, eax


    invoke GetCommandLine        ; provides the command line address
    mov CommandLine, eax

    invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
    
    invoke ExitProcess,eax       ; cleanup & return to operating system

; #########################################################################

WinMain proc hInst     :DWORD,
             hPrevInst :DWORD,
             CmdLine   :DWORD,
             CmdShow   :DWORD

        ;====================
        ; Put LOCALs on stack
        ;====================

        LOCAL wc   :WNDCLASSEX
        LOCAL msg  :MSG

        LOCAL Wwd  :DWORD
        LOCAL Wht  :DWORD
        LOCAL Wtx  :DWORD
        LOCAL Wty  :DWORD

        szText szClassName,"Generic_Class"

        ;==================================================
        ; Fill WNDCLASSEX structure with required variables
        ;==================================================

        mov wc.cbSize,         sizeof WNDCLASSEX
        mov wc.style,          CS_HREDRAW or CS_VREDRAW \
                               or CS_BYTEALIGNWINDOW
        mov wc.lpfnWndProc,    offset WndProc      ; address of WndProc
        mov wc.cbClsExtra,     NULL
        mov wc.cbWndExtra,     NULL
        m2m wc.hInstance,      hInst               ; instance handle
        mov wc.hbrBackground,  COLOR_BTNFACE+1     ; system color
        mov wc.lpszMenuName,   NULL
        mov wc.lpszClassName,  offset szClassName  ; window class name
          invoke LoadIcon,hInst,500    ; icon ID   ; resource icon
        mov wc.hIcon,          eax
          invoke LoadCursor,NULL,IDC_ARROW         ; system cursor
        mov wc.hCursor,        eax
        mov wc.hIconSm,        0

        invoke RegisterClassEx, ADDR wc     ; register the window class

        ;================================
        ; Centre window at following size
        ;================================

        mov Wwd, 300
        mov Wht, 235

        invoke GetSystemMetrics,SM_CXSCREEN ; get screen width in pixels
        invoke TopXY,Wwd,eax
        mov Wtx, eax

        invoke GetSystemMetrics,SM_CYSCREEN ; get screen height in pixels
        invoke TopXY,Wht,eax
        mov Wty, eax

        ; ==================================
        ; Create the main application window
        ; ==================================
        invoke CreateWindowEx,WS_EX_OVERLAPPEDWINDOW,
                              ADDR szClassName,
                              ADDR szDisplayName,
                              WS_OVERLAPPEDWINDOW,
                              Wtx,Wty,Wwd,Wht,
                              NULL,NULL,
                              hInst,NULL

        mov   hWnd,eax  ; copy return value into handle DWORD

        invoke LoadMenu,hInst,600                 ; load resource menu
        invoke SetMenu,hWnd,eax                   ; set it to main window

        invoke ShowWindow,hWnd,SW_SHOWNORMAL      ; display the window
        invoke UpdateWindow,hWnd                  ; update the display

      ;===================================
      ; Loop until PostQuitMessage is sent
      ;===================================

    StartLoop:
      invoke GetMessage,ADDR msg,NULL,0,0         ; get each message
      cmp eax, 0                                  ; exit if GetMessage()
      je ExitLoop                                 ; returns zero
      invoke TranslateMessage, ADDR msg           ; translate it
      invoke DispatchMessage,  ADDR msg           ; send it to message proc
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
    LOCAL X     :DWORD
    LOCAL Y     :DWORD


    .if uMsg == WM_COMMAND
        .if wParam == 1000
            invoke SendMessage,hWin,WM_SYSCOMMAND,SC_CLOSE,NULL
        .elseif wParam == 1905 ; play sound thread
            invoke SetEvent, hEventStart
        .elseif wParam == 1906 ; play sound thread
            invoke SetEvent, hEventP1
        .elseif wParam == 1907 ; play sound thread
            invoke SetEvent, hEventP2
        .elseif wParam == 1908 ; play sound thread
            invoke SetEvent, hEventP3


        .endif
    
    .elseif uMsg == WM_PAINT
        invoke BeginPaint,hWin,ADDR Ps
        mov     hDC, eax
        
        invoke Paint_Proc, hWin, hDC

        invoke EndPaint,hWin,ADDR Ps
        return  0        
    
    .elseif uMsg == WM_CREATE
        mov posicao.x, 40
        mov posicao.y, 0

        ;cria o evento 
        invoke CreateEvent, NULL, FALSE, FALSE, NULL
        mov     hEventStart, eax

        invoke CreateEvent, NULL, FALSE, FALSE, NULL
        mov     hEventP1, eax
        invoke CreateEvent, NULL, FALSE, FALSE, NULL
        mov     hEventP2, eax
        invoke CreateEvent, NULL, FALSE, FALSE, NULL
        mov     hEventP3, eax

        ;cria a thread
        mov     eax, offset ThreadProc  ; obtem endereco do procedimento thread
        invoke  CreateThread, NULL, NULL, eax, \
                              NULL, NORMAL_PRIORITY_CLASS, \
                              ADDR threadID

        mov     eax, offset ThreadSomProc  ; obtem endereco do procedimento thread
        invoke  CreateThread, NULL, NULL, eax, \
                              NULL, NORMAL_PRIORITY_CLASS, \
                              ADDR threadID1
        ; criar imagens e associados
        ; cria timer para repintura da janela
        invoke SetTimer ,hWnd, ID_TIMER, MS , CbTimer


    .elseif uMsg == WM_CLOSE
        invoke KillTimer, hWnd, ID_TIMER
    .elseif uMsg == WM_DESTROY
        invoke PostQuitMessage,NULL
        return 0 
    .endif

    invoke DefWindowProc,hWin,uMsg,wParam,lParam

    ret

WndProc endp    

TopXY proc wDim:DWORD, sDim:DWORD

    ; ----------------------------------------------------
    ; This procedure calculates the top X & Y co-ordinates
    ; for the CreateWindowEx call in the WinMain procedure
    ; ----------------------------------------------------

    shr sDim, 1      ; divide screen dimension by 2
    shr wDim, 1      ; divide window dimension by 2
    mov eax, wDim    ; copy window dimension into eax
    sub sDim, eax    ; sub half win dimension from half screen dimension

    return sDim

TopXY endp
; thread de tocar o som uma vez
ThreadProc PROC USES ecx Param: DWORD

    invoke WaitForSingleObject, hEventStart, INFINITE ; 500
    .if eax == WAIT_TIMEOUT
        nop 
    .elseif eax == WAIT_OBJECT_0
        invoke PlaySound, ADDR Play, NULL, SND_FILENAME or SND_ASYNC; 
    .endif
    jmp ThreadProc
    ret
ThreadProc ENDP        

ThreadSomProc PROC USES ecx Param: DWORD
    .while TRUE
       invoke WaitForMultipleObjects,3, ADDR hEventP1, FALSE, INFINITE 
       .if eax == WAIT_TIMEOUT
          nop
       .elseif eax == WAIT_OBJECT_0
           invoke PlaySound, ADDR Play1, NULL, SND_FILENAME or SND_ASYNC;
           invoke ResetEvent, hEventP1
       .elseif eax == 1
           invoke PlaySound, ADDR Play2, NULL, SND_FILENAME or SND_ASYNC;
           invoke ResetEvent, hEventP2
       .elseif eax == 2
           invoke PlaySound, ADDR Play3, NULL, SND_FILENAME or SND_ASYNC;
           invoke ResetEvent, hEventP3
       .else
         nop
       .endif    
    .endw 
    ret   
ThreadSomProc ENDP

CbTimer proc hwnd:DWORD, uMsg:DWORD, PMidEvent:DWORD, dwTime:DWORD

  LOCAL buffer1[260]:BYTE 

  invoke GetTimeFormat, LOCALE_USER_DEFAULT, \
                  NULL, NULL, NULL, ADDR buffer1, 260
  invoke SetWindowText, hWnd, ADDR buffer1

  inc posicao.y
  .if posicao.y > 200
    mov posicao.y ,0
  .endif


  invoke InvalidateRect, hWnd, NULL, TRUE

CbTimer endp


Paint_Proc proc hWin:DWORD, hDC:DWORD

    LOCAL hOld:DWORD
    LOCAL memDC :DWORD
    LOCAL rect:RECT
   	LOCAL hfont:HFONT
  

    mov   eax, 20 ; valor de teste para impressao  
    invoke  wsprintf, offset buffer, offset format, eax
	  invoke  GetClientRect, hWin, ADDR rect 
	  invoke  DrawText, hDC, ADDR buffer, -1, ADDR rect, \
		          	DT_SINGLELINE or DT_CENTER or DT_VCENTER

    invoke CreateCompatibleDC,hDC
    mov memDC, eax
    invoke SelectObject, memDC, hBmp2
    mov hOld, eax 

  

    invoke TransparentBlt, hDC, posicao.x, posicao.y,32,23, \
                           memDC, 0,256,32,32, \
                           CREF_TRANSPARENT

    invoke SelectObject, hDC, hOld
    invoke DeleteDC, memDC
    return 0
Paint_Proc endp


end start
