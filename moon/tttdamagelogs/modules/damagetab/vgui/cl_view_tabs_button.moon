PANEL = 

    Init: () =>
        @SetIcon('icon16/tick.png')
        @SetText('')
        @SetCursor('hand')
        @SetSelected(false)

    OnMousePressed: (mouseCode) =>     
        if mouseCode == MOUSE_LEFT and @DoClick
            @DoClick!

    SetIcon: (icon) =>
        @icon = Material(icon)

    SetSelected: (selected) =>
        @selected = selected

    SetText: (text) =>
        @text = text

    OnCursorEntered: () =>
        @cursorEntered = true

    OnCursorExited: () =>
        @cursorEntered = false

    GetBackgroundColor: () =>
        return @cursorEntered and Color(250, 250, 250) or Color(245, 245, 245)

    GetBorderColor: () =>
        return @selected and Color(93, 144, 201) or color_black

    GetTextColor: () =>
        return @cursorEntered and Color(42, 115, 180) or Color(0, 0, 0)

    Paint: (w, h) =>

        draw.RoundedBox(4, 0, 0, w, h, @GetBorderColor!)
        draw.RoundedBox(4, 1, 1, w - 2, h - 2, @GetBackgroundColor!)

        iconSize = 16
        spacing = 3

        surface.SetFont('DermaDefault')
        textWidth, textHeight = surface.GetTextSize(@text)
        iconX, iconY = w/2 - (textWidth + iconSize + spacing) / 2, h/2 - iconSize/2
        surface.SetMaterial(@icon)
        surface.DrawTexturedRect(iconX, iconY, iconSize, iconSize)

        surface.SetTextPos(iconX + iconSize + spacing, h/2 - textHeight/2)
        surface.SetTextColor(@GetTextColor!)
        surface.DrawText(@text)
 
vgui.Register('DamagelogViewTabsButton', PANEL, 'DPanel')