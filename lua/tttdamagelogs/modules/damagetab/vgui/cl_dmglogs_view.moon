PANEL =

    Init: () =>
        @AddColumn(dmglog.Translate('listview_time'))\SetFixedWidth(40)
        @AddColumn(dmglog.Translate('listview_type'))\SetFixedWidth(40)
        @AddColumn(dmglog.Translate('listview_event'))\SetFixedWidth(529)
        @AddColumn('')\SetFixedWidth(30)

vgui.Register('DamagelogListView', PANEL, 'DListView')