'********************************************************************
' Vizbee HomeSSO SDK
'
' @class VizbeeHomeSSOManager
' @description
' This class is used to manage the HomeSSO sign in process.
' This class supports below public APIs:
' 1. init() - Initializes the HomeSSO manager.
' 2. setOptions(options) - Sets the options for the HomeSSO manager.
' 3. onEvent(signInEventInfo) - This method is invoked when a custom event is received from the mobile device.
' *******************************************************************

sub init()

    VizbeeHomeSSOLog("VERB", "VizbeeHomeSSOManager::init")

    m.modalPreferences = {}
    m.senderSessionInfo = invalid
    m.isSenderSignedIn = false
    m.vizbeeHomeSSOSignInAdapter = createObject("roSGNode", "VizbeeHomeSSOSignInAdapter")
    m.vizbeeSignInStatusManager = CreateObject("roSGNode", "VizbeeSignInStatusManager")
    m.global.VZBManager.callFunc("registerForEvent", VizbeeHomeSSOConstants().SignInEventType.HOME_SSO, m.top)   
end sub

' @function setOptions
' @param {Object} options
'        {Object} options.informationalPreference
'        {Object} options.successPreference
' @description
' This method is used to set the options for the HomeSSO manager.

sub setOptions(options) as void

    VizbeeHomeSSOLog("VERB", "VizbeeHomeSSOManager::setOptions")
    
    if options = invalid then
        return
    end if

    m.modalPreferences = options
end sub

' @function onEvent
' @param {Object}  signInEventInfo
'        {String}  signInEventInfo.type
'        {String}  signInEventInfo.data
' @description
' This method is invoked when a custom event is received from the mobile device.

function onEvent(signInEventInfo as Object) as void

    ' Sample event data
    ' {
    '     "type": "tv.vizbee.homesso.signin",
    '     "data": {
    '         "sub_type":"start_sign_in",
    '         "sinfo": {
    '             "is_signed_in": true,
    '             "stype" : "MVPD",
    '             "device_model" : "iPhone 11",
    '             "device_os"    : "iOS"
    '             "custom_data"  : {}
    '         },
    '         "ssinfo": {
    '             "REMOTE_DEVICE_TYPE": "",
    '             "REMOTE_LIMIT_AD_TRACKING": "",
    '             "IDFA": "",
    '             "IDFV": "",
    '             "REMOTE_DEVICE_ID": "",
    '             "REMOTE_FRIENDLY_NAME": "",
    '             "IS_IN_FOREGROUND": true/false,
    '             "REMOTE_NETWORK_SESSION_ID": "",
    '             ...
    '             "customattributes": {
    '               "key1": "value1",
    '               "key2": "value2"
    '             }
    '         }
    '     }
    ' }

    VizbeeHomeSSOLog("VERB", "VizbeeHomeSSOManager::onEvent")

    ' step 1: validate the event
    if isValidSignInEvent(signInEventInfo) = false then
        VizbeeHomeSSOLog("WARN", "VizbeeHomeSSOManager::onEvent - invalid sign in event")
        return
    end if

    VizbeeHomeSSOLog("VERB", "VizbeeHomeSSOManager::onEvent - received valid homesso signin event")

    ' step 2: log event
    startSignInInfoFromEvent = signInEventInfo.data.sinfo
    m.isSenderSignedIn = startSignInInfoFromEvent.is_signed_in
    isUserAlreadySignedIn = m.vizbeeHomeSSOSignInAdapter.callFunc("isSignedIn", startSignInInfoFromEvent.stype)
    signInEventReceivedProperties = {
        "IS_SCREEN_SIGNED_IN": isUserAlreadySignedIn
        "IS_REMOTE_SIGNED_IN": m.isSenderSignedIn
    }

    ' add sender session info
    senderSessionInfo = signInEventInfo.data.ssinfo
    if senderSessionInfo <> invalid then
        signInEventReceivedProperties["CONNECTED_REMOTE"] = {
            "IDFA": senderSessionInfo.IDFA,
            "IDFV": senderSessionInfo.IDFV,
            "REMOTE_DEVICE_ID": senderSessionInfo.REMOTE_DEVICE_ID,
            "REMOTE_DEVICE_TYPE": senderSessionInfo.REMOTE_DEVICE_TYPE,
            "REMOTE_FRIENDLY_NAME": senderSessionInfo.REMOTE_FRIENDLY_NAME,
            "REMOTE_LIMIT_AD_TRACKING": senderSessionInfo.REMOTE_LIMIT_AD_TRACKING,
            "REMOTE_NETWORK_SESSION_ID": senderSessionInfo.REMOTE_NETWORK_SESSION_ID,
        }
    end if
    VizbeeHomeSSOMetricsUtil().log(VizbeeHomeSSOMetricsUtil().Event.SCREEN_HOMESSO_SIGNIN_RECEIVED, signInEventReceivedProperties)

    ' step 3: check if user is already signed in
    if isUserAlreadySignedIn = true then
        VizbeeHomeSSOLog("INFO", "VizbeeHomeSSOManager::onEvent - user is already signed in")
        return
    else
        VizbeeHomeSSOLog("INFO", "VizbeeHomeSSOManager::onEvent - user is not signed in")
    end if

    if m.vizbeeSignInStatusManager.callFunc("getSignInState") <> VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_IN_PROGRESS and senderSessionInfo <> invalid then
        VizbeeHomeSSOLog("INFO", "VizbeeHomeSSOManager::onEvent - save sender session info")
        m.senderSessionInfo = senderSessionInfo
    end if

    ' step 4: start sign in
    startSignInInfo = CreateObject("roSGNode", "VizbeeHomeSSOSenderSignInInfo")
    startSignInInfo.isSignedIn = m.isSenderSignedIn
    startSignInInfo.signInType = startSignInInfoFromEvent.stype
    startSignInInfo.deviceOS = startSignInInfoFromEvent.device_os
    startSignInInfo.deviceModel = startSignInInfoFromEvent.device_model
    startSignInInfo.customData = startSignInInfoFromEvent.custom_data

    m.vizbeeSignInStatusManager.senderSignInInfo = startSignInInfo

    vizbeeSignInStatusCallback = createObject("roSGNode", "VizbeeSignInStatusCallback")
    vizbeeSignInStatusCallback.observeField("progress", "onProgress")
    vizbeeSignInStatusCallback.observeField("success", "onSuccess")
    vizbeeSignInStatusCallback.observeField("failure", "onFailure")
    
    m.vizbeeHomeSSOSignInAdapter.callFunc("onStartSignIn", startSignInInfo, vizbeeSignInStatusCallback)
end function


'---------------------
' Sign In Callbacks
'---------------------

function onProgress(progressStatus as object) as void
    VizbeeHomeSSOLog("VERB", "VizbeeHomeSSOManager::onProgress - received progress homesso signin event")
    if m.isSenderSignedIn = true then
        progressModalTitle = m.vizbeeHomeSSOSignInAdapter.callFunc("getSignInProgressModalTitle")
        progressModalDesc = m.vizbeeHomeSSOSignInAdapter.callFunc("getSignInProgressModalDesc")
        m.modalPreferences.progressPreference.options = CreateObject("roSGNode", "VizbeeModalOptions")
        m.modalPreferences.progressPreference.options.title = progressModalTitle
        m.modalPreferences.progressPreference.options.desc = progressModalDesc
        m.vizbeeSignInStatusManager.callFunc("onProgress", progressStatus.getData(), m.modalPreferences.progressPreference, { isSignedIn: m.isSenderSignedIn, senderSessionInfo: m.senderSessionInfo })
    else
        informationalModalTitle = m.vizbeeHomeSSOSignInAdapter.callFunc("getSignInInformationalModalTitle")
        informationalModalDesc = m.vizbeeHomeSSOSignInAdapter.callFunc("getSignInInformationalModalDesc")
        m.modalPreferences.informationalPreference.options = CreateObject("roSGNode", "VizbeeModalOptions")
        m.modalPreferences.informationalPreference.options.title = informationalModalTitle
        m.modalPreferences.informationalPreference.options.desc = informationalModalDesc
        m.vizbeeSignInStatusManager.callFunc("onProgress", progressStatus.getData(), m.modalPreferences.informationalPreference, { isSignedIn: m.isSenderSignedIn, senderSessionInfo: m.senderSessionInfo })
    end if

end function

function onSuccess(successStatus as object) as void
    VizbeeHomeSSOLog("VERB", "VizbeeHomeSSOManager::onSuccess - received success homesso signin event")
    successModalTitle = m.vizbeeHomeSSOSignInAdapter.callFunc("getSignInSuccessModalTitle")
    successModalDesc = m.vizbeeHomeSSOSignInAdapter.callFunc("getSignInSuccessModalDesc")
    m.modalPreferences.successPreference.options = CreateObject("roSGNode", "VizbeeModalOptions")
    m.modalPreferences.successPreference.options.title = successModalTitle
    m.modalPreferences.successPreference.options.desc = successModalDesc
    m.vizbeeSignInStatusManager.callFunc("onSuccess", successStatus.getData(), m.modalPreferences.successPreference, { isSignedIn: m.isSenderSignedIn, senderSessionInfo: m.senderSessionInfo })
end function

function onFailure(failureStatus as object) as void
    VizbeeHomeSSOLog("VERB", "VizbeeHomeSSOManager::onFailure - received failure homesso signin event")
    m.vizbeeSignInStatusManager.callFunc("onFailure", failureStatus.getData(), invalid, { isSignedIn: m.isSenderSignedIn, senderSessionInfo: m.senderSessionInfo })
end function

'-----------------
' Helper methods
'-----------------

function isValidSignInEvent(signInEventInfo) as boolean

    if signInEventInfo = invalid and (signInEventInfo.type = invalid or signInEventInfo.type <> VizbeeHomeSSOConstants().SignInEventType.HOME_SSO) then
        VizbeeHomeSSOLog("WARN", "VizbeeHomeSSOManager::isValidSignInEvent - signInEventInfo is invalid")
        return false
    end if

    if signInEventInfo.type = invalid or signInEventInfo.type <> VizbeeHomeSSOConstants().SignInEventType.HOME_SSO then
        VizbeeHomeSSOLog("WARN", "VizbeeHomeSSOManager::isValidSignInEvent - signInEventType is invalid")
        return false
    end if

    if signInEventInfo.data.sub_type = invalid or signInEventInfo.data.sub_type <> "start_sign_in" then
        VizbeeHomeSSOLog("WARN", "VizbeeHomeSSOManager::isValidSignInEvent - signInEvent subtype is invalid")
        return false
    end if

    if m.vizbeeHomeSSOSignInAdapter = invalid then
        VizbeeHomeSSOLog("WARN", "VizbeeHomeSSOManager::isValidSignInEvent - VizbeeHomeSSOSignInAdapter is invalid")
        return false
    end if

    startSignInInfoFromEvent = signInEventInfo.data.sinfo
    if startSignInInfoFromEvent = invalid then
        VizbeeHomeSSOLog("WARN", "VizbeeHomeSSOManager::isValidSignInEvent - start signin info is invalid")
        return false
    end if

    if startSignInInfoFromEvent.stype = invalid or startSignInInfoFromEvent.stype = "" then
        VizbeeHomeSSOLog("WARN", "VizbeeHomeSSOManager::isValidSignInEvent - sign in type is invalid")
        return false
    end if

    return true
end function