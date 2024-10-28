#Requires AutoHotkey v2.0

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
    mygui.Show("x3735 y1175 AutoSize")

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
        envVar := StrSplit(line, "=", 2)
        if envVar.Length == 2 {
            key := Trim(envVar[1])  ; Убираем пробелы у ключа
            value := Trim(envVar[2])  ; Убираем пробелы у значения
            EnvSet(key, value)  ; Устанавливаем переменную окружения
        }
    }
}
