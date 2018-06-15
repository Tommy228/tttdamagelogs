PANEL =

    Init: () =>
        @AddColumn(dmglog.GetTranslation('listview_time'))\SetFixedWidth(40)
        @AddColumn(dmglog.GetTranslation('listview_type'))\SetFixedWidth(40)
        @AddColumn(dmglog.GetTranslation('listview_event'))\SetFixedWidth(529)
        @AddColumn('')\SetFixedWidth(30)

vgui.Register('DamagelogListView', PANEL, 'DListView')