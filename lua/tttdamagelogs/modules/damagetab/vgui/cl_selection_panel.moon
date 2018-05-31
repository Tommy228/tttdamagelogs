PANEL =

    forms: {}

    Init: (using nil) =>
        table.Empty(@forms)    
        @CreatePanelList!            
        @CreateRoundForm(true)
        @CreateDamageInfoForm!
        @CreateRolesForm!

    AddForm: (expand = false, formCreator using nil) =>
        with form = formCreator!
            \SetExpanded(expand)
            @CreateFormToggleHook(form)
            @panelList\AddItem(form)
            table.insert(@forms, form)

    CreateFormToggleHook: (form using nil) =>
        oldFormToggle = form.Toggle 
        form.Toggle = (forced using nil) =>
            allowToggle = forced or form\OnToggle!
            if allowToggle
                oldFormToggle(self)
        form.OnToggle = (form using nil) ->
            @OnFormToggle(form)

    OnFormToggle: (form using nil) =>
        print(form, form.GetExpanded)
        if form\GetExpanded! 
            return false
        for otherForm in *@forms
            if form != otherForm
                if otherForm\GetExpanded!
                    otherForm\Toggle(true)
        true

    PerformLayout: (w, h using nil) =>
        @\SetSize(w, 195)
        @panelList\StretchToParent(12, 5, 12, 0)
 
    CreatePanelList: (using nil) =>
        with @panelList = vgui.Create('DPanelList', self)
            \SetSpacing(7)

    CreateRoundForm: (expand using nil) =>
        @AddForm expand, -> 
            with roundForm = vgui.Create('DForm')
                \SetName(dmglog.Translate('round_selection'))
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

    CreateDamageInfoForm: (expand using nil) =>
        @AddForm expand, ->
            damageInfoTitle = dmglog.Translate('damage_information') 
            with damageInfoForm = vgui.Create('DForm')
                \SetName(damageInfoTitle)
                with damageInformation = vgui.Create('DListView', damageInfoForm)
                    \SetHeight(90)
                    \AddColumn(damageInfoTitle)
                    damageInfoForm\AddItem(damageInformation)

    CreateRolesForm: (expand using nil) =>
        @AddForm expand, ->
            with rolesForm = vgui.Create('DForm')
                \SetName(dmglog.Translate('roles'))
                with roles = vgui.Create('DListView')
                    \SetHeight(90)
                with showInnocentRoles = vgui.Create('DCheckBoxLabel', rolesForm)
                    \SetPos(455, 3)
                    \SetText(dmglog.Translate('show_innocent_roles'))
                    \SetTextColor(color_white)
                    \SetConVar('ttt_dmglogs_showinnocents')
                    \SizeToContents!

vgui.Register('DamagelogSelectionPanel', PANEL, 'DPanel')