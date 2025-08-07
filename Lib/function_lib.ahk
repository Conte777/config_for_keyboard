#Requires AutoHotkey v2.0+
#Include UIA.ahk
#Include UIA_Browser.ahk

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
    global gGui := Gui("-Caption +AlwaysOnTop +ToolWindow"), textElement

    ; Установка шрифта и добавление текстового элемента
    gGui.SetFont("q5 s12", "Verdana")
    textElement := gGui.AddText("cRed ", text)

    ; Настройка размеров окна под текст
    gGui.Show("x30 y1385 AutoSize")

    ; Установка прозрачности окна
    gGui.BackColor := "000000"
    WinSetTransColor("000000", gGui)

    ; Отключаем видимость до лучших времен
    HideGUI()
}

; Функция для обновления текста
UpdateGUI(newText) {
    global gGui, textElement
    textElement.Visible := true
    textElement.Text := newText
    gGui.Show("AutoSize")
}

; Функция для показа GUI
ShowGUI() {
    global gGui, textElement
    textElement.Visible := true
    gGui.Show()
}

; Функция для скрытия GUI
HideGUI() {
    global gGui, textElement
    textElement.Visible := false
    gGui.Hide()
}

; Корректное уничтожение GUI
DestroyGUI() {
    global gGui
    if IsSet(gGui) {
        try gGui.Destroy()
        gGui := ""
    }
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
        return Map()
    }

    envContent := FileRead(filePath)  ; Читаем содержимое .env файла
    envMap := Map()  ; Объект для хранения ключей и значений
    for line in StrSplit(envContent, "`n") {
        line := Trim(line)  ; Убираем пробелы и переносы строк
        if (line = "" || SubStr(line, 1, 1) = "#")  ; Пропускаем пустые и закомментированные строки
            continue

        ; Удаляем комментарий после символа #, если он вне кавычек
        commentPos := 0
        inSingle := false
        inDouble := false
        Loop Parse line {
            char := A_LoopField
            if (char = "'" && !inDouble) {
                inSingle := !inSingle
            } else if (char = '"' && !inSingle) {
                inDouble := !inDouble
            } else if (char = "#" && !inSingle && !inDouble) {
                commentPos := A_Index
                break
            }
        }
        if commentPos {
            line := Trim(SubStr(line, 1, commentPos - 1))
            if (line = "")
                continue
        }

        ; Разделяем строку по первому знаку "=" и убираем лишние пробелы
        envVar := StrSplit(line, "=", "", 2)
        if envVar.Length == 2 {
            key := Trim(envVar[1])  ; Убираем пробелы у ключа
            value := Trim(envVar[2])  ; Убираем пробелы у значения

            ; Удаляем обрамляющие одинарные или двойные кавычки
            if (value != "" && ((SubStr(value, 1, 1) = '"' && SubStr(value, -1) = '"')
                || (SubStr(value, 1, 1) = "'" && SubStr(value, -1) = "'"))) {
                value := SubStr(value, 2, StrLen(value) - 2)
            }

            EnvSet(key, value)  ; Устанавливаем переменную окружения
            envMap[key] := value  ; Сохраняем в объект
        }
    }
    return envMap
}

; GetTextAtCaret(unit)
; unit: "character" | "word" | "line" | "document" | "all"
GetTextAtCaret(unit := "word") {
    el := _GetFocusedElement()

    if (unit = "word" && _IsBrowserWindow())
        return _Browser_GetWordAtCaret()

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
    if (_IsBrowserWindow())
        return _Browser_GetCaretOffset()

    el := _GetFocusedElement()

    tp2 := TryGetTP2(el)
    tp := TryGetTP(el)

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

_IsBrowserWindow() {
    try {
        proc := WinGetProcessName("A")
        return RegExMatch(proc, "i)^(chrome|msedge|firefox|brave|opera|vivaldi)\.exe$")
    } catch {
        return false
    }
}

_Browser_GetCaretOffset() {
    browser := UIA_Browser("A")
    js := "
(LTrim Join
    (() => {
        const el = document.activeElement;
        if(!el) return -1;
        if (el.selectionStart !== undefined) {
            return el.selectionStart;
        } else {
            const sel = window.getSelection();
            if (!sel || sel.rangeCount === 0) return -1;
            const range = sel.getRangeAt(0);
            const pre = range.cloneRange();
            pre.selectNodeContents(el);
            pre.setEnd(range.startContainer, range.startOffset);
            return pre.toString().length;
        }
    })()
)"
    offset := browser.JSReturnThroughClipboard(js)
    return Integer(offset)
}

_Browser_GetWordAtCaret() {
    browser := UIA_Browser("A")
    js := "
(LTrim Join
    (() => {
        const el = document.activeElement;
        if(!el) return '';
        if (el.selectionStart !== undefined) {
            const v = el.value;
            const pos = el.selectionStart;
            let s = pos, e = pos;
            const re = /\\s/;
            while (s > 0 && !re.test(v[s-1])) s--;
            while (e < v.length && !re.test(v[e])) e++;
            return v.substring(s, e);
        } else {
            const sel = window.getSelection();
            if (!sel || sel.rangeCount === 0) return '';
            const text = sel.focusNode.textContent;
            let pos = sel.focusOffset;
            let s = pos, e = pos;
            const re = /\\s/;
            while (s > 0 && !re.test(text[s-1])) s--;
            while (e < text.length && !re.test(text[e])) e++;
            return text.substring(s, e);
        }
    })()
)"
    return browser.JSReturnThroughClipboard(js)
}
