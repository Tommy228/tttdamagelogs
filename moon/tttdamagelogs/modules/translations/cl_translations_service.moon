dmglog.GetTranslation = -> ''

pendingLanguagesToAdd = {}
dmglog.AddLanguage = (name) ->
    languageContent = include("langs/#{name}.lua")
    table.insert(pendingLanguagesToAdd, {
        name: name
        content: languageContent
    })

hook.Add 'Initialize', 'TTTDamagelogs_ClientsideTranslations', () ->

    import GetTranslation, AddToLanguage, GetParamTranslation from LANG

    prefix = 'dmglog_'

    dmglog.GetTranslation = (key, params = false) -> 
        tttKey = prefix .. key
        if params
           PrintTable(params)
        return GetParamTranslation(tttKey, params) if params else GetTranslation(tttKey)

    AddPendingLanguages = () ->
        for language in *pendingLanguagesToAdd
            for key, text in pairs(language.content)
                AddToLanguage(language.name, prefix .. key, text)

    AddPendingLanguages!