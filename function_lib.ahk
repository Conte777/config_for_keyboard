#Requires AutoHotkey v2.0+

; Функция отправки клавиш
OwnSend(message := "") {
    ; Помечаем, что горячая клавиша была использована
    global HotkeysUsed
    HotkeysUsed := true

    ; Заглушаем другие hotkeys, чтобы они не активировались
    Suspend(1)
    SendInput(message)
    Suspend(0)
}

; Создание GUI
CreateGui(text := "MovMod") {
    ; Инициализация глобальных переменных
    global textElement

    ; Создание окна без заголовка и кнопок
    mygui := Gui("-Caption +AlwaysOnTop +ToolWindow")

    ; Установка шрифта и добавление текстового элемента
    mygui.SetFont("q5 s12", "Verdana")
    textElement := mygui.AddText("cRed ", text)

    ; Настройка размеров окна под текст
    mygui.Show("x30 y1385 AutoSize")

    ; Установка прозрачности окна
    mygui.BackColor := "000000"
    WinSetTransColor("000000", mygui)

    ; Отключаем видимость до лучших времен
    HideGUI()
}

; Функция для обновления текста
UpdateGUI(newText) {
    global textElement
    textElement.Visible := true
    textElement.Text := newText
}

; Функция для показа GUI
ShowGUI() {
    global textElement
    textElement.Visible := true
}

; Функция для скрытия GUI
HideGUI() {
    global textElement
    textElement.Visible := false
}

; Показ временной подсказки
Tip(text := "", TimeDelay := -1000) {
    ToolTip()
    ToolTip(text)
    if (text != "")
        SetTimer(ToolTip, TimeDelay)
}

; Функция для загрузки переменных из .env файла
LoadEnvVars(filePath := ".env") {
    if !FileExist(filePath) {
        MsgBox "Файл .env не найден: " filePath
        return
    }

    envContent := FileRead(filePath)  ; Читаем содержимое .env файла
    for line in StrSplit(envContent, "`n") {
        line := Trim(line)  ; Убираем пробелы и переносы строк
        if (line = "" || SubStr(line, 1, 1) = "#")  ; Пропускаем пустые и закомментированные строки
            continue

        ; Разделяем строку по первому знаку "=" и убираем лишние пробелы
        envVar := StrSplit(line, "=", "", 2)
        if envVar.Length == 2 {
            key := Trim(envVar[1])  ; Убираем пробелы у ключа
            value := Trim(envVar[2])  ; Убираем пробелы у значения
            EnvSet(key, value)  ; Устанавливаем переменную окружения
        }
    }
}

; GetTextAtCaret(unit)
; unit: "character" | "word" | "line" | "document" | "all"
GetTextAtCaret(unit := "word") {
    el := _GetFocusedElement()

    ; Весь текст
    if (unit = "document" || unit = "all") {
        tp := TryGetTP(el)
        if (tp)
            return tp.DocumentRange.GetText(0x7FFFFFFF)
        vp := TryGetValue(el)
        if (vp)
            return vp.Value
        throw Error("Элемент не отдаёт текст целиком (нет TextPattern/ValuePattern)")
    }

    ; Однострочные поля: "line" = Value
    if (unit = "line") {
        vp := TryGetValue(el)
        if (vp && !_HasTextPattern(el))
            return vp.Value
    }

    ; 1) Попробуем каретку через TextPattern2
    tp2 := TryGetTP2(el)
    if (tp2) {
        tr := tp2.GetCaretRange(&isActive)
        if (tr)
            return _ExpandSafeAndGetText(tr, el, unit)
    }

    ; 2) Через TextPattern — selection как каретка
    tp := TryGetTP(el)
    if (tp) {
        sels := tp.GetSelection()
        if (sels.Length > 0) {
            tr := sels[1]
            return _ExpandSafeAndGetText(tr, el, unit)
        }
        ; Если selection пуст, но просили строку — попробуем документ
        if (unit = "line")
            return tp.DocumentRange.GetText(0x7FFFFFFF)
    }

    ; 3) Хоть что-то — ValuePattern
    vp := TryGetValue(el)
    if (vp) {
        if (unit = "line")
            return vp.Value
        if (unit = "word") {
            ; Без TextPattern слово точно не выделим — вернём весь текст поля
            return vp.Value
        }
        if (unit = "character") {
            ; Без TextPattern позицию символа не узнать — вернём пусто
            return ""
        }
        return vp.Value
    }

    throw Error("Контрол не отдаёт текст через UIA (нет TextPattern(2)/ValuePattern)")
}

; Позиция каретки (0-based). Требуется TextPattern2 или TextPattern.
GetCaretOffset() {
    el := _GetFocusedElement()

    tp2 := TryGetTP2(el)
    tp  := TryGetTP(el)

    if (tp2 && tp) {
        caret := tp2.GetCaretRange(&isActive)
        if !caret
            throw Error("Каретка недоступна через TextPattern2")
        doc := tp.DocumentRange.Clone()
        doc.MoveEndpointByRange(UIA.TextPatternRangeEndpoint.End
            , caret, UIA.TextPatternRangeEndpoint.Start)
        return StrLen(doc.GetText(0x7FFFFFFF))
    }

    if (tp) {
        sels := tp.GetSelection()
        if (sels.Length = 0)
            throw Error("Нет каретки/выделения в TextPattern")
        caret := sels[1]
        doc := tp.DocumentRange.Clone()
        doc.MoveEndpointByRange(UIA.TextPatternRangeEndpoint.End
            , caret, UIA.TextPatternRangeEndpoint.Start)
        return StrLen(doc.GetText(0x7FFFFFFF))
    }

    throw Error("Позиция каретки недоступна: нет TextPattern(2)")
}

; Координаты каретки на экране
GetCaretRect() {
    el := _GetFocusedElement()
    tp2 := TryGetTP2(el)
    if !tp2
        return 0
    tr := tp2.GetCaretRange(&isActive)
    if !tr
        return 0
    rects := tr.GetBoundingRectangles()
    return rects.Length ? rects[1] : 0  ; {x,y,w,h} или 0
}

; ================== ВНУТРЕННИЕ ХЕЛПЕРЫ ==================

_GetFocusedElement() {
    el := UIA.GetFocusedElement()
    if !el
        throw Error("Нет сфокусированного элемента")
    return el
}

; Мягкое расширение TextRange до unit и чтение текста
_ExpandSafeAndGetText(tr, el, unit) {
    try {
        switch unit {
            case "character":
                tr.ExpandToEnclosingUnit(UIA.TextUnit.Character)
            case "word":
                tr.ExpandToEnclosingUnit(UIA.TextUnit.Word)
            case "line":
                tr.ExpandToEnclosingUnit(UIA.TextUnit.Line)
            default:
                tr.ExpandToEnclosingUnit(UIA.TextUnit.Word)
        }
        return tr.GetText(0x7FFFFFFF)
    } catch as e {
        ; В Chromium часто E_NOTIMPL (0x80004001) на Line/Word
        if (unit = "line") {
            vp := TryGetValue(el)
            if (vp)
                return vp.Value
        }
        if (unit = "word") {
            ; Попробуем сузиться до символа
            try {
                tr2 := tr.Clone()
                tr2.ExpandToEnclosingUnit(UIA.TextUnit.Character)
                return tr2.GetText(1)
            } catch {
                vp := TryGetValue(el)
                if (vp)
                    return vp.Value
            }
        }
        throw e
    }
}

; ===== Безопасные геттеры паттернов (никогда не бросают) =====
TryGetTP2(el) {
    try {
        ; сначала проверка «доступно ли», она обычно безопасна
        if (el.IsTextPattern2Available) {
            ; а вот сам геттер TextPattern2 в некоторых контролах бросает — ловим
            return el.TextPattern2
        }
    } catch {
        return 0
    }
    return 0
}

TryGetTP(el) {
    try {
        if (el.IsTextPatternAvailable)
            return el.TextPattern
    } catch {
        return 0
    }
    return 0
}

TryGetValue(el) {
    try {
        if (el.IsValuePatternAvailable)
            return el.ValuePattern
    } catch {
        return 0
    }
    return 0
}

_HasTextPattern(el) {
    try {
        return el.IsTextPatternAvailable
    } catch {
        return false
    }
}