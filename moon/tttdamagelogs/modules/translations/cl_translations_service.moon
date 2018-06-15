dmglog.Translate = -> ''

pendingLanguagesToAdd = {}
dmglog.AddLanguage = (name) ->
    languageContent = include("langs/#{name}.lua")
    table.insert(pendingLanguagesToAdd, {
        name: name
        content: languageContent
    })

InitTranslations = () ->

    import GetTranslation, AddToLanguage, GetParamTranslation from LANG

    prefix = 'dmglog_'

    dmglog.Translate = (key, params = false) -> 
        tttKey = prefix .. key
        if params 
            GetTranslation(tttKey)
        else
            GetParamTranslation(tttKey, params)

    AddPendingLanguages = () ->
        for language in *pendingLanguagesToAdd
            for key, text in pairs(language.content)
                AddToLanguage(language.name, prefix .. key, text)

    AddPendingLanguages!

hook.Add('Initialize', 'TTTDamagelogs_ClientsideTranslations', InitTranslations)