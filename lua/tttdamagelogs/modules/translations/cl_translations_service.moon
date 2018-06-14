dmglog.Translate = -> ''

pendingLanguagesToAdd = {}
dmglog.AddLanguage = (name) ->
    languageContent = include("langs/#{name}.lua")
    table.insert(pendingLanguagesToAdd, {
        name: name
        content: languageContent
    })

InitTranslations = (using dmglog) ->

    prefix = 'dmglog_'

    import GetTranslation, AddToLanguage from LANG

    dmglog.Translate = (key using prefix, GetTranslation) -> 
        GetTranslation(prefix .. key)

    AddPendingLanguages = (using pendingLanguagesToAdd) ->
        for language in *pendingLanguagesToAdd
            for key, text in pairs(language.content)
                AddToLanguage(language.name, prefix .. key, text)

    AddPendingLanguages!

hook.Add('Initialize', 'TTTDamagelogs_ClientsideTranslations', InitTranslations)