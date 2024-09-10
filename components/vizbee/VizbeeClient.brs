' Ref:
'   RAF Integration Guide: https://developer.roku.com/docs/developer-program/advertising/integrating-roku-advertising-framework.md
'   Google DAI Integration Guide: https://developers.google.com/ad-manager/dynamic-ad-insertion/sdk/roku?service=full
'   RAF Tracking Event Types: https://developer.roku.com/docs/developer-program/advertising/integrating-roku-advertising-framework.md#tracking

' ----------------------------
' VizbeeClient
' This script includes wrapper methods to simplify Vizbee integration
' ----------------------------

' This function returns instance of VizbeeClientInstance that can be used to call APIs
function VizbeeClient()

    globalAA = GetGlobalAA()
    if globalAA.VizbeeClient = invalid
    	globalAA.VizbeeClient = VizbeeClientInstance()
    end if
    return globalAA.VizbeeClient
end function

' VizbeeClientInstance is a wrapper function that provides APIs
' and enums to be used for vizbee integration
function VizbeeClientInstance() as object

    self = {}
    
    ' init
    self.initVizbeeWithLaunchArgs = initVizbeeWithLaunchArgs

    ' video node monitor
    self.startVideoNodeMonitor = startVideoNodeMonitor
    self.stopVideoNodeMonitor = stopVideoNodeMonitor

    ' ad monitoring
    self.rafAdTrackingCallback = rafAdTrackingCallback
    self.monitorGoogleDAI = monitorGoogleDAI

    ' custom event handler apis
    self.registerForEvent = registerForEvent
    self.unregisterForEvent = unregisterForEvent
    self.sendEventWithName = sendEventWithName

    ' enums
    self.AdAdapterTypes = {
        RAFX: "rafx",
        GOOGLE_IMA: "google_ima"
    }
    self.AdEventTypes = {
        AD_POD_START: "PodStart",
        AD_START: "Start",
        AD_PROGRESS: "Position",
        AD_FIRST_QUARTILE: "playingFirstQuartile",
        AD_MIDPOINT: "playingMidpoint",
        AD_THIRD_QUARTILE: "playingThirdQuartile",
        AD_COMPLETE: "Complete",
        AD_POD_COMPLETE: "PodComplete",
        AD_CLOSE: "Close",
        AD_ERROR: "Error",
        AD_SKIP: "Skip",
        AD_PAUSE: "Pause",
        AD_Resume: "Resume"
    }
    return self
end function

'--------------------
' Public functions
'--------------------

' Initialize Vizbee SDK with Roku app launch arguments
function initVizbeeWithLaunchArgs(args as Object) as boolean

    if args = invalid
        print "VizbeeClient::initVizbeeWithLaunchArgs - Vizbee INIT FAILED due to invalid launch args."
        return false
    end if

    appInfo = CreateObject( "roAppInfo" )
    vizbeeAppID = appInfo.GetValue("vizbee_app_id")
    if vizbeeAppID = "" or vizbeeAppID = "vzb*********"
        print "VizbeeClient::initVizbeeWithLaunchArgs - Vizbee INIT FAILED due to invalid app id."
        print "VizbeeClient::initVizbeeWithLaunchArgs - Check that you have added the vizbee_app_id field in manifest file."
        return false
    end if
    
    ' Create a SINGLETON instance of MyVizbeeManager
    
    globalNode = getGlobalAA().global
    if globalNode = invalid 
        print "VizbeeClient::initVizbeeWithLaunchArgs - Vizbee INIT IGNORED due to invalid global node."
    end if  
    if globalNode.VZBManager = invalid
    
        globalNode.addField("VZBManager","node",false)
        globalNode.VZBManager = CreateObject("roSGNode", "MyVizbeeManager")
        globalNode.VZBManager.callFunc("initVizbeeSDK", vizbeeAppID, args)
    else
        print "VizbeeClient::initVizbeeWithLaunchArgs - Vizbee INIT IGNORED due to duplicate init call."
    end if

    return true
end function

' Pass video node to Vizbee SDK to monitor video events
function startVideoNodeMonitor(videoNode as Object) as void

    vzbManager = getVZBManager()
    if vzbManager <> invalid
        vzbManager.activeVideoNode = videoNode
        vzbManager.shouldMonitorVideoNode = true
    end if
end function

' Stop monitoring video node
function stopVideoNodeMonitor(videoNode) as void

    vzbManager = getVZBManager()
    if vzbManager <> invalid
        vzbManager.shouldMonitorVideoNode = false
    end if
end function

' Pass CSAI RAF events to Vizbee SDK
function rafAdTrackingCallback(obj = invalid as dynamic, eventType = invalid as dynamic, ctx = invalid as dynamic) as void

    vzbManager = getVZBManager()
    if vzbManager <> invalid and vzbManager.hasField("rafCallbackData") = true then
        vzbManager.rafCallbackData = { eventType: eventType, ctx: ctx }
    end if
end function

' Monitor Google IMA events and pass them to Vizbee SDK
function monitorGoogleDAI(imaInstance as dynamic) as void

    if imaInstance = invalid
        print "VizbeeSSAIAds::monitorGoogleDAI - INVALID imaInstance"
        return
    end if

    streamManager = imaInstance.getStreamManager()
    if streamManager = invalid
        print "VizbeeSSAIAds::monitorGoogleDAI - INVALID streamManager, not monitoring ads"
        return
    end if

    streamManager.addEventListener(imaInstance.AdEvent.AD_PERIOD_STARTED, function(adObject as object)
        sendAdEventToVizbeeSDK(VizbeeClient().AdAdapterTypes.GOOGLE_IMA, VizbeeClient().AdEventTypes.AD_POD_START, adObject)
    end function)
    streamManager.addEventListener(imaInstance.AdEvent.START, function(adObject as object)
        sendAdEventToVizbeeSDK(VizbeeClient().AdAdapterTypes.GOOGLE_IMA, VizbeeClient().AdEventTypes.AD_START, adObject)
    end function)
    streamManager.addEventListener(imaInstance.AdEvent.PROGRESS, function(adObject as object)
        sendAdEventToVizbeeSDK(VizbeeClient().AdAdapterTypes.GOOGLE_IMA, VizbeeClient().AdEventTypes.AD_PROGRESS, adObject)
    end function)
    streamManager.addEventListener(imaInstance.AdEvent.FIRST_QUARTILE, function(adObject as object)
        sendAdEventToVizbeeSDK(VizbeeClient().AdAdapterTypes.GOOGLE_IMA, VizbeeClient().AdEventTypes.AD_FIRST_QUARTILE, adObject)
    end function)
    streamManager.addEventListener(imaInstance.AdEvent.MIDPOINT, function(adObject as object)
        sendAdEventToVizbeeSDK(VizbeeClient().AdAdapterTypes.GOOGLE_IMA, VizbeeClient().AdEventTypes.AD_MIDPOINT, adObject)
    end function)
    streamManager.addEventListener(imaInstance.AdEvent.THIRD_QUARTILE, function(adObject as object)
        sendAdEventToVizbeeSDK(VizbeeClient().AdAdapterTypes.GOOGLE_IMA, VizbeeClient().AdEventTypes.AD_THIRD_QUARTILE, adObject)
    end function)
    streamManager.addEventListener(imaInstance.AdEvent.COMPLETE, function(adObject as object)
        sendAdEventToVizbeeSDK(VizbeeClient().AdAdapterTypes.GOOGLE_IMA, VizbeeClient().AdEventTypes.AD_COMPLETE, adObject)
    end function)
    streamManager.addEventListener(imaInstance.AdEvent.AD_PERIOD_ENDED, function(adObject as object)
        sendAdEventToVizbeeSDK(VizbeeClient().AdAdapterTypes.GOOGLE_IMA, VizbeeClient().AdEventTypes.AD_POD_COMPLETE, adObject)
    end function)
    streamManager.addEventListener(imaInstance.AdEvent.SKIPPED, function(adObject as object)
        sendAdEventToVizbeeSDK(VizbeeClient().AdAdapterTypes.GOOGLE_IMA, VizbeeClient().AdEventTypes.AD_SKIPPED, adObject)
    end function)
    streamManager.addEventListener(imaInstance.AdEvent.ERROR, function(adObject as object)
        sendAdEventToVizbeeSDK(VizbeeClient().AdAdapterTypes.GOOGLE_IMA, VizbeeClient().AdEventTypes.AD_ERROR, adObject)
    end function)
end function

' @function registerForEvent
' @param {String} eventName
' @param {Object} eventHandler
' @description
' This method is used to register for custom event.
function registerForEvent(eventName as string, eventHandler as object) as void
    vzbManager = getVZBManager()
    if vzbManager <> invalid
        vzbManager.callFunc("registerForEvent", eventName, eventHandler)
    end if
end function

' @function unregisterForEvent
' @param {String} eventName
' @param {Object} eventHandler
' @description
' This method is used to unregister from custom event
function unregisterForEvent(eventName as string, eventHandler as object) as void
    vzbManager = getVZBManager()
    if vzbManager <> invalid
        vzbManager.callFunc("unregisterForEvent", eventName, eventHandler)
    end if
end function

' @function sendEventWithName
' @param {String} eventName
' @param {Object} eventData
' @description
' This method is used to send the event with data to the mobile via sync.
function sendEventWithName(eventName as string, eventData as object) as void
    vzbManager = getVZBManager()
    if vzbManager <> invalid
        vzbManager.callFunc("sendEventWithName", eventName, eventData)
    end if
end function

'--------------------
' Helper functions
'--------------------

function getVZBManager() as dynamic

    globalNode = GetGlobalAA().global
    if globalNode <> invalid
        vzbManager = globalNode.VZBManager
        if vzbManager <> invalid
            return vzbManager
        end if
    end if
    return invalid
end function

sub sendAdEventToVizbeeSDK(adapterType as string, eventType as string, adObject as object)

    vzbManager = getVZBManager()
    if vzbManager <> invalid and vzbManager.hasField("ssaiAdCallbackData") = true then
        vzbManager.ssaiAdCallbackData = {
            adapterType: adapterType,
            adEventData: {
                eventType: eventType,
                data: adObject
            }
        }
    end if
end sub