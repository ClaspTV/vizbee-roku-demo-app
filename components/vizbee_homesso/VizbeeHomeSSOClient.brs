'********************************************************************
' Vizbee HomeSSO SDK
'
' @class VizbeeHomeSSOClient
' @description 
' This script includes wrapper methods to simplify Vizbee HomeSSO integration
'********************************************************************

' @function VizbeeHomeSSOClient
' @return object
' @description
' This function returns instance of VizbeeHomeSSOClientInstance that can be used to call APIs

function VizbeeHomeSSOClient()

    globalAA = GetGlobalAA()
    if globalAA.VizbeeHomeSSOClient = invalid
    	globalAA.VizbeeHomeSSOClient = VizbeeHomeSSOClientInstance()
    end if
    return globalAA.VizbeeHomeSSOClient
end function

' VizbeeHomeSSOClientInstance is a wrapper function that provides Vizbee HomeSSO APIs
' and enums to be used for vizbee integration
function VizbeeHomeSSOClientInstance() as object
    self = {}
    self.init = initialize
    return self
end function

'--------------------
' Public functions
'--------------------

' @function initialize
' @param options as dynamic
' @return boolean
' @description
' This function initializes Vizbee HomeSSO SDK with the given options

function initialize(options=invalid as dynamic) as boolean

    ? "VizbeeHomeSSOClient::initialize"; options
    globalNode = getGlobalAA().global
    if globalNode = invalid 
        ? "VizbeeHomeSSOClient::initialize - Vizbee HomeSSO INIT IGNORED due to invalid global node."
        return false
    end if  

    if globalNode.VZBManager = invalid
        ? "VizbeeHomeSSOClient::initialize - Vizbee HomeSSO INIT IGNORED since Vizbee Continuity is not initialized."
        return false
    end if

    if globalNode.VZBHomeSSOManager = invalid
    
        globalNode.addField("VZBHomeSSOManager","node",false)
        globalNode.VZBHomeSSOManager = CreateObject("roSGNode", "VizbeeHomeSSOManager")
        if options <> invalid then
            globalNode.VZBHomeSSOManager.callFunc("setOptions", options)
        end if
    else
        ? "VizbeeHomeSSOClient::initialize - Vizbee HomeSSO INIT IGNORED due to duplicate init call."
    end if

    return true
end function