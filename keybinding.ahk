#SingleInstance Force
#Include function_lib.ahk
#Requires AutoHotkey v2.0+

; Инициализация глобальных переменных
isScriptActive := false
HotkeysUsed := false
CapsLockHandled := false
textElement := 0

main()

main() {
    ; Создаем объект GUI
    CreateGui()
    ; Загружаем переменные окружения
    LoadEnvVars()
}

; Capslock down
*F14::
{
    ; Инициализация глобальных переменных
    global isScriptActive
    global HotkeysUsed
    global CapsLockHandled

    ; Если капслок обрабатывается
    if (CapsLockHandled) {
        return
    }
    ; Помечаем, что начали обрабатывать нажатие
    CapsLockHandled := true

    ; Включаем скрипты
    isScriptActive := !isScriptActive
    ; Обнуляем флаг использование клавиш
    HotkeysUsed := false

    ; Показываем временное уведомление о статусе
    if (isScriptActive)
        ShowGUI()
    else
        HideGUI()
}

; Capslock up
*F14 up::
{
    ; Инициализация глобальных переменных
    global isScriptActive
    global HotkeysUsed
    global CapsLockHandled

    ; Помечаем, что перестали обрабатывать капслок
    CapsLockHandled := false

    ; Проверяем, были ли использованы горячие клавиши
    if (HotkeysUsed) {
        isScriptActive := false
        HideGUI()
    }
}

; Reload script
^+F5:: Reload()

#HotIf isScriptActive or CapsLockHandled

; ----------------------------------------------------------------
; Cursor control keys
; ----------------------------------------------------------------

*j:: OwnSend("{Blind}{Left}")	    ; j     Left
*k:: OwnSend("{Blind}{Down}")	    ; k     Down
*l:: OwnSend("{Blind}{Right}")	    ; l     Right
*i:: OwnSend("{Blind}{Up}")         ; i     Up
*u:: OwnSend("{Blind}{Home}")       ; u     Home
*o:: OwnSend("{Blind}{End}")        ; o     End
*sc027:: OwnSend("{Blind}^{Enter}")	; ;:    New line under this one
*p:: OwnSend("{Blind}+^{Enter}")	; p     New line above this one
*n:: OwnSend("{Blind}^{Left}")      ; n     Word left
*m:: OwnSend("{Blind}^{Right}")     ; m     Word right

; ----------------------------------------------------------------
; General Purpose Keys
; ----------------------------------------------------------------

*h:: OwnSend("{Blind}{Backspace}")	; /?    BackSpace
*sc035:: OwnSend("{Blind}{Del}")	    ; .>    Del
*sc033:: OwnSend("{Blind}^{Backspace}") ; ,<    Control+Backspace

; ----------------------------------------------------------------
; Copy/Paste/Cut/Select_all/Undo
; ----------------------------------------------------------------

+c:: OwnSend("{Home}{Home}+{End}^c{Home}")  ; C   copy whole line
+x:: OwnSend("{Home}{Home}+{End}^x{Del}")   ; .>  cut whole line

a:: OwnSend("{Blind}^a")    ; a         Select all
c:: OwnSend("{Blind}^c")    ; c         Copy
x:: OwnSend("{Blind}^x")    ; x         Cut
v:: OwnSend("{Blind}^v")    ; v         Past
z:: OwnSend("{Blind}^z")    ; z         Undo
+z:: OwnSend("{Blind}+^z")  ; Shift+z   Redo

; ----------------------------------------------------------------
; Punctuation marks
; ----------------------------------------------------------------

s:: OwnSend("{Blind};")
+s:: OwnSend("{Blind}:")
d:: OwnSend("{Blind}.")
+d:: OwnSend("{Blind}{,}")
e:: OwnSend("{Blind}'")
+e:: OwnSend("{Blind}`"")
q:: OwnSend("{Blind}/")
+q:: OwnSend("{Blind}?")
w:: OwnSend("{Blind}{#}")
+w:: OwnSend("{Blind}{@}")
*Esc:: OwnSend("{Blind}``")

; ----------------------------------------------------------------
; Brackets
; ----------------------------------------------------------------

f:: OwnSend("{Blind}(")
g:: OwnSend("{Blind})")
r:: OwnSend("{Blind}[")
t:: OwnSend("{Blind}]")
+r:: OwnSend("{Blind}{{}")
+t:: OwnSend("{Blind}{}}")

; ----------------------------------------------------------------
; Black list
; ----------------------------------------------------------------

*y:: return
*b:: return
*sc028:: return
*sc01a:: return
*sc01b:: return
*sc034:: return
*sc02b:: return
*1:: return
*2:: return
*3:: return
*4:: return
*5:: return
*6:: return
*7:: return
*8:: return
*9:: return
*0:: return
*-:: return
*=:: return

#HotIf

; ----------------------------------------------------------------
; Aliases
; ----------------------------------------------------------------

::@@::
{
    email := EnvGet("email")
    OwnSend(email)
}

; ----------------------------------------------------------------
; Keyboard code
; ----------------------------------------------------------------

/*

Key  `   1   2   3   4   5   6   7   8   9   0   -   =   \  BS
VK  C0  31  32  33  34  35  36  37  38  39  30  BD  BB  DC  08
SC 029 002 003 004 005 006 007 008 009 00A 00B 00C 00D 02B 00E
sc  41   2   3   4   5   6   7   8   9  10  11  12  13  43  14

Key Tab   q   w   e   r   t   y   u   i   o   p   [   ]
VK   09  51  57  45  52  54  59  55  49  4F  50  DB  DD
SC  00F 010 011 012 013 014 015 016 017 018 019 01A 01B
sc   15  16  17  18  19  20  21  22  23  24  25  26  27

Key Caps   a   s   d   f   g   h   j   k   l   ;   ' Enter
VK    14  41  53  44  46  47  48  4A  4B  4C  BA  DE    0D
SC   03A 01E 01F 020 021 022 023 024 025 026 027 028   01C
sc    58  30  31  32  33  34  35  36  37  38  39  40    28

Key LShift   z   x   c   v   b   n   m   ,   .   / RShift
VK      A0  5A  58  43  56  42  4E  4D  BC  BE  BF     A1
SC     02A 02C 02D 02E 02F 030 031 032 033 034 035    136
sc      42  44  45  46  47  48  49  50  51  52  53    310

Key LCtrl LWin LAlt Space RAlt RWin Menu RCtrl
VK     A2   5B   A4    20   A5   5C   5D    A3
SC    01D  15B  038   039  138  15C  15D   11D
sc     29  347   56    57  312  348  349   285

VK A6  SC 16A	 	Browser_Back
VK A7  SC 169	 	Browser_Forward

Key between Short Left Shift and Z (ISO keyboard) - SC 056

*/
