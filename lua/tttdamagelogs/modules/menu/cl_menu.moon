
x, y = 665, 680
key = KEY_F8

dmglog.OpenMenu = (using x, y) ->
    with dmglog.Menu = vgui.Create('DFrame')
        \SetSize(x, y)
        \SetTitle('TTT Damagelogs')
        \SetDraggable(true)
        \MakePopup!
        \SetKeyboardInputEnabled(false)
        \Center!
    with dmglog.Tabs = vgui.Create('DPropertySheet', dmglog.Menu)
        \SetPos(5, 30)
        \SetSize(x - 10, y - 35)
    hook.Run('TTTDamagelogsMenuOpen')

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