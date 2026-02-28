Locales = {}
CurrentLocale = nil

function _LoadLocale(name, data)
    Locales[name] = data
end

function _SetLocale(name)
    if Locales[name] then
        CurrentLocale = name
    else
        print(('[tayer-uptime] ^1Locale "%s" not found, falling back to "en"^0'):format(name))
        CurrentLocale = 'en'
    end
end

function _L(key, ...)
    if not CurrentLocale or not Locales[CurrentLocale] then
        return key
    end

    local str = Locales[CurrentLocale][key]
    if not str then
        return key
    end

    if ... then
        return str:format(...)
    end

    return str
end
