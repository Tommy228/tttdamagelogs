PANEL =

    forms: {}

    Init: (using nil) =>
        @CreatePanelList!            
        @CreateRoundForm!

    AddForm: (form using nil) =>
        @panelList\AddItem(form)
        table.insert(@forms, form)

    PerformLayout: (w, h using nil) =>
        @\SetSize(w, 195)
        @panelList\StretchToParent(12, 5, 12, 0)

    CreatePanelList: (using nil) =>
        with @panelList = vgui.Create('DPanelList', self)
            \SetSpacing(7)

    CreateRoundForm: (using nil) =>
        roundForm = vgui.Create('DForm')
        roundForm\SetName(dmglog.Translate('round_selection'))
        with roundFormPanel = vgui.Create('DPanel')
            \SetHeight(90)
            .Paint = ->
            with roundSelection = vgui.Create('DComboBox', roundFormPanel)
                \SetSize(500, 22)
                \SetPos(0, 0)
            with filters = vgui.Create('DButton', roundFormPanel)
                \SetSize(85, 22)
                \SetPos(505, 0)
                \SetText(dmglog.Translate('filters'))
            with playerSelect = vgui.Create('DPanel', roundFormPanel)
                \SetSize(590, 60)
                \SetPos(0, 30)
            roundForm\AddItem(roundFormPanel)
        @AddForm(roundForm)

vgui.Register('DamagelogSelectionPanel', PANEL, 'DPanel')