PANEL = 

    Init: () =>
        @SetRoundNumber(0)
        @AddColumn(dmglog.GetTranslation('player'))
        @AddColumn(dmglog.GetTranslation('role'))
        @AddColumn(dmglog.GetTranslation('status'))
        @roleColors = {
            [ROLE_INNOCENT]: Color(0, 200, 0) 
            [ROLE_TRAITOR]: Color(200, 0, 0) 
            [ROLE_DETECTIVE]: Color(0, 0, 200) 
        }

    SetRoundNumber: (roundNumber) =>
        @roundNumber = roundNumber 

    SetRoundPlayers: (roundsPlayers) =>
        @Clear!
        for roundPlayer in *roundsPlayers.list
            @AddRoundPlayer(roundPlayer)

    GetStatusText: (roundPlayer) =>
        if GetRoundState() == ROUND_ACTIVE and dmglog.roundsCount == @roundNumber
            ply = player.GetBySteamID(roundPlayer.steamId)
            if IsValid(ply)
                return 'alive' if ply\IsActive! else 'dead'
            else
                return 'disconnected'
        else
            return 'round_ended'

    AddRoundPlayer: (roundPlayer) =>
        item = @AddLine(roundPlayer.name, dmglog.GetTranslatedRoleString(roundPlayer.role), '')
        item.PaintOver = (item) ->
            column\SetTextColor(@roleColors[roundPlayer.role]) for column in *item.Columns
        item.Think = (item) ->
            item\SetColumnText(3, dmglog.GetTranslation(@GetStatusText(roundPlayer)))

vgui.Register('DamagelogRolesView', PANEL, 'DListView')