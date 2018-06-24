PANEL =

    Init: () =>
        @CreateDamagelogButton!
        @CreateShotLogsButton!
        @CreateShotLogsDisplay!
        @CreateDamagelogDisplay!
        @CreateSearch!

    Resize: () =>
        viewsPosX, viewsPosY = 0, 40
        viewsWidth, viewsHeight = 639, @GetTall! - 10
        @dmglogs\SetPos(viewsPosX, viewsPosY)
        @dmglogs\SetSize(viewsWidth, viewsHeight)
        @shots\SetPos(viewsPosX, viewsPosY)
        @shots\SetSize(viewsWidth, viewsHeight)

    Paint: () =>
        -- NO-OP

    CreateShotLogsButton: () =>
        dmglogsButtonX, dmglogsButtonY = @dmglogsButton\GetPos!
        with @shotLogsButton = vgui.Create('DamagelogViewTabsButton', self)
            do
                \SetSize(150, 30)
                \SetPos(dmglogsButtonX + @dmglogsButton\GetWide! + 10, 0)
                \SetText(dmglog.GetTranslation('shot_logs'))
                \SetIcon('icon16/gun.png')
            do
                .DoClick = () ->
                    @dmglogs\SetVisible(false)
                    @dmglogsButton\SetSelected(false)
                    @shots\SetVisible(true)
                    @shotLogsButton\SetSelected(true)


    CreateDamagelogButton: () =>
        with @dmglogsButton = vgui.Create('DamagelogViewTabsButton', self)
            do
                \SetSize(150, 30)
                \SetPos(12, 0)
                \SetText(dmglog.GetTranslation('round_events'))
                \SetSelected(true)
                \SetIcon('icon16/script.png')
            do
                .DoClick = () ->
                    @dmglogs\SetVisible(true)
                    @dmglogsButton\SetSelected(true)
                    @shots\SetVisible(false)
                    @shotLogsButton\SetSelected(false)

    CreateDamagelogDisplay: () =>
        @dmglogs = vgui.Create('DamagelogListView', self)

    CreateShotLogsDisplay: () =>
        @shots = vgui.Create('DamagelogShotsListView', self)
        @shots\SetVisible(false)

    CreateSearch: () =>
        @searchInput = vgui.Create('DTextEntry', self)
        @searchInput\SetSize(180, 30)
        @searchInput\SetPos(627 - @searchInput\GetWide!, 0)
        @searchInput\SetPlaceholderText(dmglog.GetTranslation('search_placeholder'))

        searchIcon = vgui.Create('DImage', @searchInput)
        searchIcon\SetImage('icon16/magnifier.png')
        searchIcon\SetSize(16, 16)
        searchIcon\SetPos(@searchInput\GetWide! - 25, @searchInput\GetTall! / 2 - 8)

vgui.Register('DamagelogViewTabs', PANEL, 'DPanel')