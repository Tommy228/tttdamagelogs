PANEL = 

    w: 665
    h: 680

    Init: () =>
        @SetSize(@w, @h)

        @SetTitle(dmglog.GetTranslation('menu_title'))
        @SetDraggable(true)
        @SetKeyboardInputEnabled(false)
        
        @CreateTabs!
        hook.Run('TTTDamagelogsMenuOpen', @Tabs)

        @MakePopup!
        @Center!

    CreateTabs: (using dmglog) =>
        with @Tabs = vgui.Create('DPropertySheet', self)
            \SetPos(5, 30)
            \SetSize(@w - 10, @h - 35)

vgui.Register('DamagelogMenu', PANEL, 'DFrame')