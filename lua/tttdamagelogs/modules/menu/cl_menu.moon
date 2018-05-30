
x, y = 665, 680
key = KEY_F8

dmglog.OpenMenu = (using x, y) ->
    dmglog.Menu = vgui.Create('DamagelogMenu')

concommand.Add('damagelog', () -> dmglog.OpenMenu!)

pressedOpenKey = false
dmglog.HandleKeyPress = (using pressedOpenKey) ->
    isKeyDown = input.IsKeyDown(key)
    if isKeyDown and not pressedOpenKey
        pressedOpenKey = true
        if not IsValid(dmglog.Menu)
            dmglog.OpenMenu!
        else
            dmglog.Menu\Close!
    elseif pressedOpenKey and not isKeyDown
        pressedOpenKey = false

hook.Add('Think', 'TTTDamagelogs_KeyOpen', dmglog.HandleKeyPress)