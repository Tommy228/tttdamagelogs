PANEL = 

    Init: () =>
        @UpdateRounds!
        hook.Add 'TTTDamagelogsRoundsCountUpdated', 'TTTDamagelogs_UpdateRoundsCountDisplay', () ->
            @UpdateRounds! if IsValid(self)

    UpdateRounds: () =>
        @Clear!
        for i = 1, dmglog.roundsCount
            @AddChoice(dmglog.GetTranslation('combobox_round', {roundNumber: i}))
    
vgui.Register('DamagelogRoundSelection', PANEL, 'DComboBox')