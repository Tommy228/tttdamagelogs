class dmglog.Event

    GetKeyFunctionName: (key) =>
        length = #key
        name = ''
        if length > 0
            name ..= string.upper(key[1])
        if length > 1
            name ..= string.sub(key, 2) 
        "Get#{name}", "Set#{name}"

    MapRegisteredKeys: () =>
        table.Empty(@mappedRegisteredKeys)
        for index, key in ipairs @registeredKeys
            @mappedRegisteredKeys[key] = index
            getter, setter = @GetKeyFunctionName(key) 
            @[getter] = () => @mappedValues[key]
            @[setter] = (value) => @mappedValues[key] = value
 
    new: (registeredKeys) =>
        @registeredKeys = registeredKeys
        @mappedRegisteredKeys = {}
        @mappedValues = {}
        @MapRegisteredKeys!

    @ToString: () =>
        ''

    