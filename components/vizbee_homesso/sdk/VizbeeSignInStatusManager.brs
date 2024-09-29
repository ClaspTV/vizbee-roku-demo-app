'********************************************************************
' Vizbee HomeSSO SDK
'
' @class VizbeeSignInStatusManager
' @description
' This class is responsible for managing the sign in status of the user.
' It listens to the sign in progress, success and failure events and 
'       sends the sign in status to the mobile device.
'       logs vizbee homesso metrics
'       updates the UI accordingly.
'
' This class supports below public APIs:
' 1. 'onProgress' observer function is triggered when the sign in starts.
' 2. 'onSuccess' observer function is triggered when the sign in is successful.
' 3. 'onFailure' observer function is triggered when the sign in fails.
' 4. 'getSignInState' function returns the current sign in state.
' *******************************************************************

sub init()
    m.vizbeeSignInModalManager = CreateObject("roSGNode", "VizbeeSignInModalManager")
    m.signInState = VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_NOT_STARTED
end sub

' when: as soon as reg code is generated
' how : callback.onProgress(VizbeeSignInProgressResult("mvpd", JSONObject().put("regcode", regcode)))

' @function onProgress
' @param {Object}  progressStatus The progress status of the sign in process.
'        {Object}  informationalPreference The informational preference.
'        {Object}  customData The custom data.
' @description
' Callback to be invoked when the sign in process starts.

function onProgress(progressStatus as object, informationalPreference as dynamic, customData as dynamic) as void

    VizbeeHomeSSOLog("VERB", "VizbeeSignInStatusManager::onProgress")

    senderSessionInfo = invalid
    isSenderSignedIn = false
    if customData <> invalid
        senderSessionInfo = customData.senderSessionInfo
        isSenderSignedIn = customData.isSignedIn
    end if

    signInState = VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_IN_PROGRESS
    m.signInState = signInState

    ' log metrics
    logMetricsEvent({
        "SCREEN_SIGN_IN_STATUS": signInState
    }, senderSessionInfo)  

    ' send status to mobile
    sendStatusToMobile(signInState, progressStatus)

    ' update modal
    m.vizbeeSignInModalManager.callFunc("updateSignInStatus", informationalPreference, signInState, progressStatus, isSenderSignedIn)
end function

' when: as soon as the polling succeeds
' how : callback.onSuccess(VizbeeSignInSuccessResult("mvpd", userId))

' @function onSuccess
' @param {Object}  successStatus The success status of the sign in process.
'        {Object}  successPreference The success preference.
'        {Object}  customData The custom data.
' @description
' Callback to be invoked when the sign in process is successful.

function onSuccess(successStatus as object,successPreference as dynamic, customData as dynamic) as void

    VizbeeHomeSSOLog("VERB", "VizbeeSignInStatusManager::onSuccess")

    senderSessionInfo = invalid
    isSenderSignedIn = false
    if customData <> invalid
        senderSessionInfo = customData.senderSessionInfo
        isSenderSignedIn = customData.isSignedIn
    end if

    signInState = VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_COMPLETED
    m.signInState = signInState

    ' log metrics
    logMetricsEvent({
        "SCREEN_SIGN_IN_STATUS": signInState
    }, senderSessionInfo)  

    ' send status to mobile
    sendStatusToMobile(signInState, successStatus)

    ' update modal
    m.vizbeeSignInModalManager.callFunc("updateSignInStatus", successPreference, signInState, successStatus, isSenderSignedIn)
end function

' when: as soon as the polling fails or user cancels the sign
' how : callback.onFailure(VizbeeSignInFailureResult("mvpd", false, "xzy")

' @function onFailure
' @param {Object}  failureStatus The failure status of the sign in process.
'        {Object}  failurePreference The failure preference.
'        {Object}  customData The custom data.
' @description
' Callback to be invoked when the sign in process fails.

function onFailure(failureStatus as object, failurePreference as dynamic, customData as dynamic) as void
    
    VizbeeHomeSSOLog("VERB", "VizbeeSignInStatusManager::onFailure")

    senderSessionInfo = invalid
    isSenderSignedIn = false
    if customData <> invalid
        senderSessionInfo = customData.senderSessionInfo
        isSenderSignedIn = customData.isSignedIn
    end if

    if(failureStatus.isCancelled = true)
        signInState = VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_CANCELLED
    else
        signInState = VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_FAILED
    end if
    m.signInState = signInState

    ' log metrics
    logMetricsEvent({
        "SCREEN_SIGN_IN_STATUS": signInState
    }, senderSessionInfo)

    ' send status to mobile
    sendStatusToMobile(signInState, failureStatus)

    ' update modal
    m.vizbeeSignInModalManager.callFunc("updateSignInStatus", failurePreference, signInState, failureStatus, isSenderSignedIn)
end function

' @function getSignInState
' @description
' Returns the current sign in state.

function getSignInState() as string
    return m.signInState
end function

'-----------------
' Helper methods
'-----------------

function sendStatusToMobile(signInState, signInStatus) as void

    VizbeeHomeSSOLog("VERB", "VizbeeSignInStatusManager::sendStatusToMobile")

    if isValidSignInState(signInState) = false
        VizbeeHomeSSOLog("WARN", "VizbeeSignInStatusManager::sendStatusToMobile - signInState is invalid")
        return
    end if
    
    if isValidSignInStatusInfo(signInStatus, signInState) = false
        VizbeeHomeSSOLog("WARN", "VizbeeSignInStatusManager::sendStatusToMobile - signInStatusEventInfo is invalid")
        return
    end if

    if m.global.VZBManager = invalid
        VizbeeHomeSSOLog("WARN", "VizbeeSignInStatusManager::sendStatusToMobile - VZBManager is invalid")
        return
    end if

    signInstausToBeSentToMobile = invalid
    signInstausToBeSentToMobile = {
        "sub_type":"sign_in_status",
        "sstatus": {
            "sstate": signInState
            "stype": signInStatus.sType
            "custom_data": signInStatus.cData
        }
    }
    m.global.VZBManager.callFunc("sendEventWithName", VizbeeHomeSSOConstants().SignInEventType.HOME_SSO, signInstausToBeSentToMobile)
end function

function isValidSignInState(signInState as string) as boolean
    isValidState = false
    for each validSignInState in VizbeeHomeSSOConstants().VizbeeSignInState
        if VizbeeHomeSSOConstants().VizbeeSignInState[validSignInState] = signInState then
            isValidState = true
            exit for
        end if
    end For
    return isValidState
end function

function isValidSignInStatusInfo(signInStatusInfo as object, signInState as string) as boolean

    if signInStatusInfo = invalid then
        VizbeeHomeSSOLog("WARN", "VizbeeSignInStatusManager::isValidSignInStatusInfo - signInStatusInfo is invalid")
        return false
    end if

    if isString(signInStatusInfo.sType) = false then
        VizbeeHomeSSOLog("WARN", "VizbeeSignInStatusManager::isValidSignInStatusInfo - signInType is invalid")
        return false
    end if

    customData = signInStatusInfo.cData
    if signInState = VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_IN_PROGRESS then
        if customData = invalid or customData.regcode = invalid then
            VizbeeHomeSSOLog("WARN", "VizbeeSignInStatusManager::isValidSignInStatusInfo - regcode is invalid")
            return false
        end if
    end if

    return true
end function

function isString(value as dynamic) as Boolean
    return type(value) = "roString" OR type(value) = "String"
end function

function logMetricsEvent(eventProperties as object, senderSessionProperties as dynamic) as void
    
    VizbeeHomeSSOLog("VERB", "VizbeeSignInStatusManager::logMetricsEvent")

    isRemoteSignedIn = invalid
    if m.top.senderSignInInfo <> invalid
        isRemoteSignedIn = m.top.senderSignInInfo.isSignedIn
    end if

    signInStatusEventProperties = {
        "IS_SCREEN_SIGNED_IN": false,
        "IS_REMOTE_SIGNED_IN": isRemoteSignedIn
    }
    screen_signin_status = eventProperties.screen_signin_status
    if screen_signin_status <> invalid and screen_signin_status = VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_COMPLETED then
        signInStatusEventProperties["IS_SCREEN_SIGNED_IN"] = true
    end if
    signInStatusEventProperties.append(eventProperties)

    ' add sender session properties
    if senderSessionProperties <> invalid
        signInStatusEventProperties["CONNECTED_REMOTE"] = {
            "IDFA": senderSessionProperties.IDFA
            "IDFV": senderSessionProperties.IDFV
            "REMOTE_DEVICE_ID": senderSessionProperties.REMOTE_DEVICE_ID
            "REMOTE_DEVICE_TYPE": senderSessionProperties.REMOTE_DEVICE_TYPE
            "REMOTE_FRIENDLY_NAME": senderSessionProperties.REMOTE_FRIENDLY_NAME
            "REMOTE_LIMIT_AD_TRACKING": senderSessionProperties.REMOTE_LIMIT_AD_TRACKING
            "REMOTE_NETWORK_SESSION_ID": senderSessionProperties.REMOTE_NETWORK_SESSION_ID
        }
    end if
    VizbeeHomeSSOMetricsUtil().log(VizbeeHomeSSOMetricsUtil().Event.SCREEN_HOMESSO_SIGNIN_STATUS, signInStatusEventProperties)
end function