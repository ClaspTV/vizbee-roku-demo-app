'********************************************************************
' Vizbee HomeSSO SDK
'
' @class VizbeeHomeSSOUtil
' @description 
' Utility functions for HomeSSO SDK
'********************************************************************

function vizbeeHomeSSOUtil()
    homeSSOUtil = {}

    '-------------------------
    ' General Utils
    '-------------------------

    homeSSOUtil.contains = function(arr as Object, value as String) as Boolean
        for each entry in arr
            if entry = value
                return true
            end if
        end for
        return false
    end function

    ' currently supports string, number and boolean inputs
    homeSSOUtil.isEqual = function(value1 as dynamic, value2 as dynamic) as Boolean
        
        ' sanity checks
        ' 1. are inputs valid
        if value1 = invalid or value2 = invalid
            return false
        end if

        ' 2. compare string inputs
        if m.isString(value1) and m.isString(value2)
            return value1 = value2
        end if

        ' 3. compare number inputs
        if m.isNumber(value1) and m.isNumber(value2)
            return value1 = value2
        end if

        ' 4. compare boolean inputs
        if m.isBoolean(value1) and m.isBoolean(value2)
            return value1 = value2
        end if

        ' 5. by default false
        return false
    end function

    homeSSOUtil.isString = function(value as dynamic) as Boolean
        return type(value) = "roString" OR type(value) = "String"
    end function

    homeSSOUtil.isStringAndValueNotEmpty = function(value as dynamic) as Boolean
        return m.isString(value) AND value <> ""
    end function

    homeSSOUtil.isBoolean = function(value as dynamic) as Boolean
        return type(value) = "roBoolean" or type(value) = "Boolean"
    end function

    homeSSOUtil.isInteger = function(value as dynamic) as boolean
        t = type(value)
        return t = "Int" or t = "Integer" or t = "roInteger" or t = "roInt"
    end function

    homeSSOUtil.isNumber = function(value as dynamic) as Boolean
        t = type(value)
        return t = "Int" or t = "Integer" or t = "roInteger" or t = "roInt" or t = "Float" or t = "roFloat" or t = "Double" or t = "roDouble"
    end Function

    homeSSOUtil.isObject = function(value as dynamic) as boolean
        return type(value) = "Object" or type(value) = "roAssociativeArray"
    end function
    
    homeSSOUtil.isNonEmptyObject = function(value as dynamic) as boolean
        return m.isObject(value) and value.keys().count() > 0
    end function

    homeSSOUtil.isArray = function(value as dynamic) as boolean
        return type(value) = "roArray"
    end function
    
    homeSSOUtil.isNonEmptyArray = function(value as dynamic) as boolean
        return m.isArray(value) and value.count() > 0
    end function

    homeSSOUtil.isValidIPv4Address = function(value as string) as boolean
        ipv4AddressRegexMatcher = "(\b25[0-5]|\b2[0-4][0-9]|\b[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}"
        regex = CreateObject("roRegEx", ipv4AddressRegexMatcher, "i")
        return regex.IsMatch(LCase(value.Trim()))
    end function

    '-------------------------
    ' Date Utils
    '-------------------------

    homeSSOUtil.ISO8601Date = function(date = CreateObject("roDateTime") as Object) as String
        d = m.padLeft(date.GetYear().ToStr(), 4)
        d = d + "-" + m.padLeft(date.GetMonth().ToStr(), 2)
        d = d + "-" + m.padLeft(date.GetDayOfMonth().ToStr(), 2)
        d = d + "T" + m.padLeft(date.GetHours().ToStr(), 2)
        d = d + ":" + m.padLeft(date.GetMinutes().ToStr(), 2)
        d = d + ":" + m.padLeft(date.GetSeconds().ToStr(), 2) + ".000Z"
        return d
    end function

    homeSSOUtil.timestamp = function(date = CreateObject("roDateTime") as Object) as String
        t = m.padLeft(date.GetYear().ToStr(), 4)
        t = t + ":" + m.padLeft(date.GetMonth().ToStr(), 2)
        t = t + ":" + m.padLeft(date.GetDayOfMonth().ToStr(), 2)
        t = t + ":" + m.padLeft(date.GetHours().ToStr(), 2)
        t = t + ":" + m.padLeft(date.GetMinutes().ToStr(), 2)
        t = t + ":" + m.padLeft(date.GetSeconds().ToStr(), 2)
        t = t + ":" + m.padLeft(date.GetMilliseconds().ToStr(), 3)
        return t
    end function

    '-------------------------
    ' JSON Utils
    '-------------------------

    homeSSOUtil.flattenJSON = function(data as Dynamic) as Object

        if data = invalid
            return {}
        end if

        if Type(data) <> "roAssociativeArray" and Type(data) <> "roArray"
            return {}
        end if

        jsonFlatten = {
            result: {},
            recurse: function(cur as dynamic, prop as string) as void

                if Type(cur) = "roAssociativeArray"
                    
                    for each key in cur
                        fullKey = key
                        if prop <> ""
                            fullKey = prop +"."+ fullKey
                        end if
                        m.recurse(cur[key], fullKey)
                    end for
                else if Type(cur) = "roArray"
                    
                    if (cur.count() = 0 and prop <> "")
                        m.result[prop] = []
                    else
                        for i = 0 to (cur.count() - 1)
                            m.recurse(cur[i], prop + "[" + i.ToStr() + "]")
                        end for
                    end if
                else if prop <> invalid and prop <> ""
                    m.result[prop] = cur
                end if
            end function
        }
        
        jsonFlatten.recurse(data, "")
        return jsonFlatten.result
    end function

    '-------------------------
    ' String Utils
    '-------------------------

    homeSSOUtil.padLeft = function(value as String, length as Integer) as String
        while (value.Len() < length)
            value = "0" + value
        end while
        return value
    end function

    homeSSOUtil.stringToDictionary = function(input as String, interKVDelimiter as String, intraKVDelimiter as String) as Object

        kvDictionary = {}

        kvArray = input.Split(interKVDelimiter)
        for i = 0 to (kvArray.count() - 1)
            
            kv = kvArray[i].Split(intraKVDelimiter)
            if kv.count() = 2

                key = kv[0]
                value = kv[1]

                if key <> invalid and key <> ""
                    kvDictionary[key] = value
                end if
            end if
        end for

        return kvDictionary
    end function

    return homeSSOUtil
end function
