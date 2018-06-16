PANEL = 

    Init: () =>
        @UpdateRounds!
        hook.Add 'TTTDamagelogsRoundsCountUpdated', 'TTTDamagelogs_UpdateRoundsCountDisplay', () ->
            @UpdateRounds! if IsValid(self)

    UpdateRounds: () =>
        @Clear!
        for i = 1, dmglog.roundsCount
            @AddChoice(dmglog.GetTranslation('combobox_round', {roundNumber: i}), i)
        @ChooseOptionID(dmglog.roundsCount) if dmglog.roundsCount > 0

    GetSelectedRound: () => select(2, @GetSelected!)        
    
vgui.Register('DamagelogRoundSelection', PANEL, 'DComboBox')