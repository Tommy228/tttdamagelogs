PANEL =

    Init: () =>
        @AddColumn(dmglog.GetTranslation('listview_time'))\SetFixedWidth(40)
        @AddColumn(dmglog.GetTranslation('listview_type'))\SetFixedWidth(40)
        @AddColumn(dmglog.GetTranslation('listview_event'))\SetFixedWidth(529)
        @AddColumn('')\SetFixedWidth(30)

    DisplayRoundEvents: (roundEvents) =>
        for roundEvent in *roundEvents.eventsList
            text = roundEvent\ToString(roundEvents.roundPlayers)
            print('text', text)
            @AddLine('', '', text)

vgui.Register('DamagelogListView', PANEL, 'DListView')