'----------------------------------------------
' Vizbee Log
'----------------------------------------------

function vizbee_log(level as string, msg as string, msgJson = {} as object)
    levels = {
        VIZBEE_LOG_LEVEL_UNDEFINED : 0,
        PROD : 1,
        ERROR : 2,
        WARN : 3,
        INFO : 4,
        VERB : 5
    }

    ' set to 'PROD', ERROR' or 'INFO':
    loglevel = levels["PROD"]

    if (levels[level] <= loglevel)

        if (level = "PROD") then level = "LOG"
        timestamp = vizbee_timestamp()

        if level = "INFO" or level = "VERB"
            if (vizbee_isNonEmptyObject(msgJson))
                msg = msg + " - " + FormatJson(msgJson)
            end if
        end if
        print "VIZBEE [" + level + "]: [" + timestamp + "] " + msg
    end if
end function

function vizbee_timestamp(date = CreateObject("roDateTime") as object) as string
    t = vizbee_padLeft(date.GetYear().ToStr(), 4)
    t = t + ":" + vizbee_padLeft(date.GetMonth().ToStr(), 2)
    t = t + ":" + vizbee_padLeft(date.GetDayOfMonth().ToStr(), 2)
    t = t + ":" + vizbee_padLeft(date.GetHours().ToStr(), 2)
    t = t + ":" + vizbee_padLeft(date.GetMinutes().ToStr(), 2)
    t = t + ":" + vizbee_padLeft(date.GetSeconds().ToStr(), 2)
    t = t + ":" + vizbee_padLeft(date.GetMilliseconds().ToStr(), 3)
    return t
end function

function vizbee_padLeft(value as string, length as integer) as string

    while (value.Len() < length)
        value = "0" + value
    end while
    return value
end function

function vizbee_isNonEmptyObject(value as dynamic) as boolean
    return vizbee_isObject(value) and value.keys().count() > 0
end function

function vizbee_isObject(value as dynamic) as boolean
    return type(value) = "Object" or type(value) = "roAssociativeArray"
end function
