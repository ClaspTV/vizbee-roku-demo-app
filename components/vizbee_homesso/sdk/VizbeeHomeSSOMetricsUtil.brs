'********************************************************************
' Vizbee HomeSSO SDK
'
' @class VizbeeHomeSSOMetricsUtil
' @description
' This class is used to log metrics events for HomeSSO SDK.
'********************************************************************

function VizbeeHomeSSOMetricsUtil()

    this = m.homeSSOMetricsUtilInstance
    if (this = invalid)

        this = {
            Event: {
                SCREEN_HOMESSO_SIGNIN_RECEIVED: "SCREEN_HOMESSO_SIGNIN_RECEIVED"
                SCREEN_HOMESSO_SIGNIN_STATUS: "SCREEN_HOMESSO_SIGNIN_STATUS"
            }
            senderProperties: {}
            log: vizbee_homesso_metrics_util_log
        }

        'singleton
        m.homeSSOMetricsUtilInstance = this
    end if

    return this
end function

function vizbee_homesso_metrics_util_log(eventName as String, eventProperties as Object)
    
    globalNode = getGlobalAA().global
    if globalNode = invalid 
        return false
    end if  

    if globalNode.VZBManager = invalid
        return false
    end if

    if eventName = invalid or eventName = ""
        return false
    end if

    if eventProperties = invalid
        eventProperties = {}
    end if

    eventProperties["SCREEN_HOMESSO_SDK_VERSION"] = "1.0.1"
    globalNode.VZBManager.callFunc("logMetricsEvent", eventName, eventProperties)
end function