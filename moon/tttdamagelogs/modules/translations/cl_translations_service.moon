dmglog.GetTranslation = -> ''

pendingLanguagesToAdd = {}
dmglog.AddLanguage = (name) ->
    languageContent = include("langs/#{name}.lua")
    table.insert(pendingLanguagesToAdd, {
        name: name
        content: languageContent
    })

dmglog.GetTranslatedRoleString = (role) ->
    translationKey = switch role
        when ROLE_INNOCENT then 'innocent'
        when ROLE_TRAITOR then 'traitor'
        when ROLE_DETECTIVE then 'detective'
    return dmglog.GetTranslation(translationKey)

hook.Add 'Initialize', 'TTTDamagelogs_ClientsideTranslations', () ->

    import GetTranslation, AddToLanguage, GetParamTranslation from LANG

    prefix = 'dmglog_'

    dmglog.GetTranslation = (key, params = false) -> 
        tttKey = prefix .. key
        return GetParamTranslation(tttKey, params) if params else GetTranslation(tttKey)

    AddPendingLanguages = () ->
        for language in *pendingLanguagesToAdd
            for key, text in pairs(language.content)
                AddToLanguage(language.name, prefix .. key, text)

    AddPendingLanguages!