PANEL =

    Init: () =>
        @panelHeight = 90
        @forms = {}
        @CreatePanelList!            
        @CreateRoundForm(true)
        @CreateRolesForm!

    Paint: () =>
        -- NO-OP

    AddForm: (expand = false, formCreator) =>
        form = formCreator!
        form\SetExpanded(expand)
        @CreateFormToggleHook(form)
        @panelList\AddItem(form)
        table.insert(@forms, form)

    CreateFormToggleHook: (form) =>
        oldFormToggle = form.Toggle 
        form.Toggle = (forced) =>
            allowToggle = forced or form\OnToggle!
            if allowToggle
                oldFormToggle(self)
        form.OnToggle = (form) ->
            @OnFormToggle(form)

    OnFormToggle: (form) =>
        if form\GetExpanded! 
            return false
        for otherForm in *@forms
            if form != otherForm
                if otherForm\GetExpanded!
                    otherForm\Toggle(true)
        return true

    PerformLayout: (w, h) =>
        @\SetSize(w, 160)
        @panelList\StretchToParent(12, 5, 12, 0)
 
    CreatePanelList: () =>
        with @panelList = vgui.Create('DPanelList', self)
            \SetSpacing(7)

    CreateRoundForm: (expand) =>
        @AddForm expand, -> 
            with roundForm = vgui.Create('DForm')
                \SetName(dmglog.GetTranslation('round_selection'))
                with roundFormPanel = vgui.Create('DPanel')
                    \SetHeight(@panelHeight)
                    .Paint = ->
                    with roundSelection = vgui.Create('DamagelogRoundSelection', roundFormPanel)
                        \SetSize(500, 22)
                        \SetPos(0, 0)
                        .OnSelect = () ->
                            @OnSelectedRoundChanged(roundSelection\GetSelectedRound!) if @OnSelectedRoundChanged
                    with filters = vgui.Create('DButton', roundFormPanel)
                        \SetSize(85, 22)
                        \SetPos(505, 0)
                        \SetText(dmglog.GetTranslation('filters'))
                    with highlightPanel = vgui.Create('DamagelogHighlightPanel', roundFormPanel)
                        \SetSize(590, 60)
                        \SetPos(0, 30)
                    roundForm\AddItem(roundFormPanel)

    CreateRolesForm: (expand) =>
        @AddForm expand, ->
            with rolesForm = vgui.Create('DForm')
                \SetName(dmglog.GetTranslation('roles'))
                with @roles = vgui.Create('DamagelogRolesView')
                    \SetHeight(@panelHeight)
                    rolesForm\AddItem(@roles)
                with showInnocentRoles = vgui.Create('DCheckBoxLabel', rolesForm)
                    \SetPos(455, 3)
                    \SetText(dmglog.GetTranslation('show_innocent_roles'))
                    \SetTextColor(color_white)
                    \SetConVar('ttt_dmglogs_showinnocents')
                    \SizeToContents!

vgui.Register('DamagelogSelectionPanel', PANEL, 'DPanel')