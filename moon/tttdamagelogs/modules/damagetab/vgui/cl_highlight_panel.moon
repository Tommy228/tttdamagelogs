dmglog.HighlightedPlayers = dmglog.HighlightedPlayers or {}

highlightFont = dmglog.CreateFont 'DL_Highlight',
	font: 'Verdana'
	size: 13

borderColor = Color(40, 40, 40)

PANEL =

    Init: () =>
        @SetSize(590, 60)
        @CreateLabel!
        @CreatePlayerChoices!
        @CreateHighlightButton!
        dmglog.HighlightedPlayers = {}


    PaintOver: (w, h) =>
        surface.SetDrawColor(borderColor)
        surface.DrawLine(0, 0, w - 1, 0)
        surface.DrawLine(w - 1, 0, w - 1, h - 1)
        surface.DrawLine(w - 1, h - 1, 0, h - 1)
        surface.DrawLine(0, h - 1, 0, 0)

    CreateLabel: () =>
        with @label = vgui.Create('DLabel', self)
            do
                .baseText = dmglog.GetTranslation('currently_highlighted_players')
                .UpdateText = () =>
                    text = @baseText
                    if #dmglog.HighlightedPlayers == 0
                        text ..= ' ' .. dmglog.GetTranslation('none')
                    @SetText(text)
                    @SizeToContents!
            do
                \SetFont(highlightFont)
                \SetTextColor(color_black)
                \SetPos(5, 10)
                \UpdateText!

    CreatePlayerChoices: () =>
        with @playerChoices = vgui.Create('DComboBox', self)
            \SetPos(5, 30)
            \SetSize(490, 20)
            \AddChoice(dmglog.GetTranslation('no_players'))
            \SetEnabled(false)

    CreateHighlightButton: () =>
        with @highlightButton = vgui.Create('DButton', self)
            \SetPos(500, 30)
            \SetSize(80, 20)
            \SetText(dmglog.GetTranslation('highlight_action'))

vgui.Register('DamagelogHighlightPanel', PANEL, 'DPanel')