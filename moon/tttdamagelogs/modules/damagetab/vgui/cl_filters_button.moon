PANEL = 

    DoClick: (forcedX, forcedY) =>
        filters = DermaMenu!
        mouseX, mouseY = gui.MouseX!, gui.MouseY!
        for filterName, filter in pairs(dmglog.filters)
            filterName = dmglog.GetTranslation(filter.translationKey)
            option = filters\AddOption filterName, () ->
                filter\SetEnabled(not filter\Enabled!)
                @OnUpdate! if @OnUpdate
                filter\Save!
                timer.Simple 0, () ->
                    @DoClick(forcedX or mouseX, forcedY or mouseY)
            option\SetIcon(filter\Enabled! and 'icon16/accept.png' or 'icon16/delete.png')
        filters\Open(forcedX or mouseX, forcedY or mouseY)

vgui.Register('DamagelogFiltersButton', PANEL, 'DButton')