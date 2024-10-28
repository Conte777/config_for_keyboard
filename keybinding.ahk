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

    ; Отключаем предыдущие подсказки
    Tip()

    ; Включаем скрипты
    isScriptActive := !isScriptActive
    ; Обнуляем флаг использование клавиш
    HotkeysUsed := false

    ; Показываем временное уведомление о статусе
    if (isScriptActive) {
        Tip("Включен")
        ShowGUI()
    }
    else {
        Tip("Отключен")
        HideGUI()
    }
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
        Tip("Отключен")
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

*sc035:: OwnSend("{Blind}{Backspace}")	; /?    BackSpace
*sc034:: OwnSend("{Blind}{Del}")	    ; .>    Del
*sc033:: OwnSend("{Blind}^{Backspace}") ; ,<    Control+Backspace

; ----------------------------------------------------------------
; Copy/Paste/Cut/Select_all/Undo
; ----------------------------------------------------------------

+c:: OwnSend("{Home}{Home}+{End}^c{Home}")	        ; C   copy whole line
+x:: OwnSend("{Home}{Home}+{End}^x{Del}")           ; .>  cut whole line
+v:: OwnSend("{Home}{Home}+{End}^c{End}{Enter}^v")  ; /?  duplicate current line

a:: OwnSend("{Blind}^a")    ; Control+a         Select all
c:: OwnSend("{Blind}^c")    ; Control+c         Copy
x:: OwnSend("{Blind}^x")    ; Control+x         Cut
v:: OwnSend("{Blind}^v")    ; Control+v         Past
z:: OwnSend("{Blind}^z")    ; Control+z         Undo
+z:: OwnSend("{Blind}+^z")  ; Control+Shift+z   Redo

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

#HotIf

; ----------------------------------------------------------------
; Aliases
; ----------------------------------------------------------------

::@@::
{
    email := EnvGet("email")
    OwnSend(email)
}
