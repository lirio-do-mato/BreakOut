      .386                   ; minimum processor needed for 32 bit
      .model flat, stdcall   ; FLAT memory model & STDCALL calling
      option casemap :none   ; set code to case sensitive

      ; ---------------------------------------------
      include \masm32\include\windows.inc

      include \masm32\include\user32.inc
      include \masm32\include\kernel32.inc

      include \MASM32\INCLUDE\gdi32.inc
	  include \Masm32\include\winmm.inc 


      includelib \masm32\lib\user32.lib
      includelib \masm32\lib\kernel32.lib
      includelib \MASM32\LIB\gdi32.lib

; Bibliotecas para MCI tocar o mp3
;
 
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

; #########################################################################


        WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
        WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
        TopXY PROTO   :DWORD,:DWORD
		
		PlaySound	PROTO	STDCALL :DWORD, :DWORD, :DWORD
		

    .data
        szDisplayName db "Tocando MP3",0
        CommandLine   dd 0
        hWnd          dd 0
        hInstance     dd 0
		msgtxt         db "Stop Playing",0
		msgtitle       db "Poor Player ver.0.0",0 
		FileName1      db "MonsterMash.mp3",0         
		FileName2      db "02 That's The Way.mp3",0         

		; - MCI_OPEN_PARMS Structure ( API=mciSendCommand ) -
		open_dwCallback     dd ?
		open_wDeviceID     dd ?
		open_lpstrDeviceType  dd ?
		open_lpstrElementName  dd ?
		open_lpstrAlias     dd ?

		; - MCI_GENERIC_PARMS Structure ( API=mciSendCommand ) -
		generic_dwCallback   dd ?

		; - MCI_PLAY_PARMS Structure ( API=mciSendCommand ) -
		play_dwCallback     dd ?
		play_dwFrom       dd ?
		play_dwTo        dd ?


; #########################################################################

; ------------------------------------------------------------------------
; This is the start of the code section where executable code begins. This
; section ending with the ExitProcess() API function call is the only
; GLOBAL section of code and it provides access to the WinMain function
; with the necessary parameters, the instance handle and the command line
; address.
; ------------------------------------------------------------------------

    .code

; -----------------------------------------------------------------------
; The label "start:" is the address of the start of the code section and
; it has a matching "end start" at the end of the file. All procedures in
; this module must be written between these two.
; -----------------------------------------------------------------------

start:
    invoke GetModuleHandle, NULL ; provides the instance handle
    mov hInstance, eax

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

        mov Wwd, 500
        mov Wht, 350

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

; #########################################################################

WndProc proc hWin   :DWORD,
             uMsg   :DWORD,
             wParam :DWORD,
             lParam :DWORD

    LOCAL hDC    :DWORD
    LOCAL Ps     :PAINTSTRUCT
    LOCAL X     :DWORD
    LOCAL Y     :DWORD
; -------------------------------------------------------------------------
; Message are sent by the operating system to an application through the
; WndProc proc. Each message can have additional values associated with it
; in the two parameters, wParam & lParam. The range of additional data that
; can be passed to an application is determined by the message.
; -------------------------------------------------------------------------

    .if uMsg == WM_COMMAND
    ;----------------------------------------------------------------------
    ; The WM_COMMAND message is sent by menus, buttons and toolbar buttons.
    ; Processing the wParam parameter of it is the method of obtaining the
    ; control's ID number so that the code for each operation can be
    ; processed. NOTE that the ID number is in the LOWORD of the wParam
    ; passed with the WM_COMMAND message. There may be some instances where
    ; an application needs to seperate the high and low words of wParam.
    ; ---------------------------------------------------------------------
    
    ;======== menu commands ========

        .if wParam == 1000
            invoke SendMessage,hWin,WM_SYSCOMMAND,SC_CLOSE,NULL
        .elseif wParam == 1900
            ;-----------------------------------------------------
			;MCI_Open prams;
			;-----------------------------------------------------
			mov   open_lpstrDeviceType, 0h         ;fill MCI_OPEN_PARMS structure
			mov   open_lpstrElementName,OFFSET FileName2
			invoke mciSendCommandA,0,MCI_OPEN, MCI_OPEN_ELEMENT,offset open_dwCallback 
			cmp   eax,0h                 
			
			jne   ErrorPrg1  
					
			;------------------------------------------------------------------------------
			; API "mciSendCommandA", MCI_PLAY command begins transmitting output data.
			;------------------------------------------------------------------------------
			invoke mciSendCommandA,open_wDeviceID,MCI_PLAY,MCI_FROM or MCI_NOTIFY,offset play_dwCallback
			;invoke mciSendCommand,open_wDeviceID,MCI_PLAY,MCI_NOTIFY,offset play_dwCallback
;push    OFFSET play_dwCallback                  ;dwParam, MCI_PLAY_PARMS struc.
;push    0h                                      ;fdwCommand, MCI_FROM
;push    0806h                                   ;uMsg, command msg. , MCI_PLAY
;push    open_wDeviceID                          ;IDDevice, given from MCI_OPEN
;call    mciSendCommandA                         ;- API Function -
			
			cmp   eax,0h         
			jne   ErrorPrg2 
	
			jmp fim	
		ErrorPrg1:
			szText TheMsg2,"Error1 ---- "
			invoke MessageBox,hWin,ADDR TheMsg2,ADDR szDisplayName,MB_OK			
			jmp sai
		ErrorPrg2:			
            szText TheMsg3,"Error2 ---- "
            invoke MessageBox,hWin,ADDR TheMsg3,ADDR szDisplayName,MB_OK			
			jmp sai
		fim:
            szText TheMsg,"Terminou ---- "
            invoke MessageBox,hWin,ADDR TheMsg,ADDR szDisplayName,MB_OK			
		sai:
		
		.elseif wParam == 1901			
			szText TheMsg2a,"Error1 ---- "
			szText TheMsg3a,"Error2 ---- "
			mov   open_lpstrDeviceType, 0h         ;fill MCI_OPEN_PARMS structure
			mov   open_lpstrElementName,OFFSET FileName1
			invoke mciSendCommandA,0,MCI_OPEN, MCI_OPEN_ELEMENT,offset open_dwCallback 
			cmp   eax,0h                 	
			je    next
			invoke MessageBox,hWin,ADDR TheMsg2a,ADDR szDisplayName,MB_OK			
			jmp    sai1
		next:	
			;invoke mciSendCommandA,open_wDeviceID,MCI_PLAY,MCI_FROM,offset play_dwCallback
			invoke mciSendCommandA,open_wDeviceID,MCI_PLAY,MCI_NOTIFY,offset play_dwCallback			
			cmp   eax,0h                 	
			je    next2
			invoke MessageBox,hWin,ADDR TheMsg3a,ADDR szDisplayName,MB_OK			
		next2:		
		
		sai1:
		.elseif wParam == 1902
			invoke mciSendCommandA,open_wDeviceID,MCI_CLOSE,0,offset generic_dwCallback		



        
		.elseif wParam == 1903
			invoke mciSendCommandA,open_wDeviceID,MCI_PAUSE,MCI_NOTIFY,offset play_dwCallback		

		.elseif wParam == 1904
			invoke mciSendCommandA,open_wDeviceID,MCI_RESUME,MCI_NOTIFY,offset play_dwCallback		
		.endif  
	.elseif uMsg == MM_MCINOTIFY
	
			szText TheMsg3B,"pODE FECHAR AGORA "
            invoke MessageBox,hWin,ADDR TheMsg3B,ADDR szDisplayName,MB_OK			
		
    ;====== end menu commands ======
    .elseif uMsg == WM_LBUTTONDOWN

    .elseif uMsg == WM_PAINT

            invoke BeginPaint,hWin,ADDR Ps
            mov     hDC, eax
            
            invoke EndPaint,hWin,ADDR Ps
            return  0

    .elseif uMsg == WM_LBUTTONDOWN
            

    .elseif uMsg == WM_CREATE
    ; --------------------------------------------------------------------
    ; This message is sent to WndProc during the CreateWindowEx function
    ; call and is processed before it returns. This is used as a position
    ; to start other items such as controls. IMPORTANT, the handle for the
    ; CreateWindowEx call in the WinMain does not yet exist so the HANDLE
    ; passed to the WndProc [ hWin ] must be used here for any controls
    ; or child windows.
    ; --------------------------------------------------------------------
        mov     X,100
        mov     Y,100
    
    .elseif uMsg == WM_CLOSE
    ; -------------------------------------------------------------------
    ; This is the place where various requirements are performed before
    ; the application exits to the operating system such as deleting
    ; resources and testing if files have been saved. You have the option
    ; of returning ZERO if you don't wish the application to close which
    ; exits the WndProc procedure without passing this message to the
    ; default window processing done by the operating system.
    ; -------------------------------------------------------------------

    .elseif uMsg == WM_DESTROY
    ; ----------------------------------------------------------------
    ; This message MUST be processed to cleanly exit the application.
    ; Calling the PostQuitMessage() function makes the GetMessage()
    ; function in the WinMain() main loop return ZERO which exits the
    ; application correctly. If this message is not processed properly
    ; the window disappears but the code is left in memory.
    ; ----------------------------------------------------------------
        invoke PostQuitMessage,NULL
        return 0 
    .endif

    invoke DefWindowProc,hWin,uMsg,wParam,lParam
    ; --------------------------------------------------------------------
    ; Default window processing is done by the operating system for any
    ; message that is not processed by the application in the WndProc
    ; procedure. If the application requires other than default processing
    ; it executes the code when the message is trapped and returns ZERO
    ; to exit the WndProc procedure before the default window processing
    ; occurs with the call to DefWindowProc().
    ; --------------------------------------------------------------------

    ret

WndProc endp

; ########################################################################

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

; ########################################################################

end start
