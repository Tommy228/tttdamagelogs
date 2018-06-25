dmglog.filters = dmglog.filters or {}

if not sql.TableExists('dmglog_filters')
    sql.Query([[
        CREATE TABLE dmglog_filters (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name VARCHAR(20) NOT NULL UNIQUE,
            value BOOLEAN NOT NULL DEFAULT 0 CHECK (value IN (0, 1))
        )
    ]])

class dmglog.Filter

    new: (name, value, translationKey, predicate) =>
        @name = name
        @value = value
        @translationKey = translationKey
        @predicate = predicate

    Save: () =>
        escapedName = sql.SQLStr(@name)
        escapedValue = dmglog.sql.SQLBool(@value)
        sql.Query("UPDATE dmglog_filters SET value = #{escapedValue} WHERE name = #{escapedName}")

    Enabled: () =>
        return @value

    SetEnabled: (enabled) =>
        @value = enabled

dmglog.CreateFilter = (name, defaultValue, translationKey, predicate) ->
    escapedName = sql.SQLStr(name)
    escapedDefaultValue = dmglog.sql.SQLBool(defaultValue)
    currentValue = sql.QueryValue("SELECT value FROM dmglog_filters WHERE name = #{escapedName} LIMIT 1")
    if not currentValue
        sql.Query("INSERT INTO dmglog_filters (name, value) VALUES (#{escapedName}, #{escapedDefaultValue})")
        currentValue = defaultValue
    filter = dmglog.Filter(name, currentValue == 1, translationKey, predicate)
    dmglog.filters[name] = filter
    return filter