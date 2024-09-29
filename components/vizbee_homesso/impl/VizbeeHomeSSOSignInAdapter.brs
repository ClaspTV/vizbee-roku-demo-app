'********************************************************************
' Vizbee HomeSSO SDK
' Copyright (c) 2024 Vizbee Inc.
' All Rights Reserved.
'
' VizbeeHomeSSOSignInAdapter
' You must create a child component that extends this class and implements the required playback methods.
'' *******************************************************************

' @function onEvent
' @param {Object}  signInInfo
'        {String}  signInInfo.type
'        {String}  signInInfo.status
' @description
' This method is invoked when a custom event is received from the mobile device.

function init()
    VizbeeHomeSSOLog("VERB", "VizbeeHomeSSOSignInAdapter::init")
    m.homeScene = m.top.getScene()
    m.networkHttpTask = createObject("roSGNode", "NetworkHttpTask")

    deviceInfo = CreateObject("roDeviceInfo")
    m.deviceId = "roku:" + deviceInfo.GetChannelClientId()

    registerForRegcodeScreenEvents()
end function

function onStartSignIn(signInInfo as object, vizbeeSignInStatusCallback as object) as void

    ' ' Sample VizbeeSenderSignInInfo
    ' {
    '     isSignedIn: false
    '     signInType : "tve"
    '     deviceOS   : "android"
    '     deviceModel: "samsung"
    '     customData: {}
    ' }

    VizbeeHomeSSOLog("INFO", "VizbeeHomeSSOSignInAdapter::onStartSignIn")
    m.vizbeeSignInStatusCallback = vizbeeSignInStatusCallback

    ' Cancel any ongoing signin request
    ' Usecase:
    '   On Mobile1: Didn't login, trying to connect to Roku
    '   On Roku: If user is NOT signed in, regcode screen pops up, polling starts, regcode sent to mobile for sign in
    '   On Mobile1: Sign in pops up, but no action taken
    '   On Mobile2: Already signed in, trying to connect to Roku
    ' Issue:
    '   As there is single network request being used for regcode generation & polling, 
    '   polling request terminates the task and restarts polling after each failed polling status.
    '   But sometines, regcode request will be cancelled and hence the Mobile2 will not receive regcode to sign in Roku.
    m.networkHttpTask.unObserveField("response")
    m.networkHttpTask.control = "STOP"

    ' Option 1:
    '   Ignore the signin request
    '       if video is playing
    if m.homeScene.callFunc("isVideoPlaying") = true then
        VizbeeHomeSSOLog("INFO", "VizbeeHomeSSOSignInAdapter::onStartSignIn - Video is playing. Ignoring the signin request.")
        return
    end if

    ' ' Option 2:
    ' '   Ignore the signin request
    ' '       if video is playing AND
    ' '       if user is NOT signed in on the mobile
    ' if m.homeScene.callFunc("isVideoPlaying") = true and m.signInInfo.isSignedIn = false then
    '     VizbeeHomeSSOLog("INFO", "VizbeeHomeSSOSignInAdapter::onStartSignIn - Video is playing and user is NOT signed in on the mobile. Ignoring the signin request.")
    '     return
    ' end if

    ' Used to send INTERRUPTED status to the mobile if mobile is not signed in
    m.homeScene.isMobileUserSignedIn = signInInfo.isSignedIn
    if m.homeScene.isMobileUserSignedIn <> true then
        m.homeScene.signInState = VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_IN_PROGRESS
    end if
    m.signInInfo = signInInfo

    ' get the regcode for d2c sign in from the app
    ' Call regcode API - 
    ' Method: POST
    ' URI: https://homesso.vizbee.tv/v1/accountregcode
    ' Payload: {"deviceId":"device_id_1"}
    '
    ' Expected response
    '   {"code":"reg_code_1"}
    m.networkHttpTask.observeField("response", "onRegCodeResponse")
    m.networkHttpTask.request = { method: "POST", uri: "https://homesso.vizbee.tv/v1/accountregcode", payload: { "deviceId": m.deviceId } }
    m.networkHttpTask.control = "RUN"
end function

function isSignedIn(signInType as string) as boolean
    VizbeeHomeSSOLog("INFO", "VizbeeHomeSSOSignInAdapter::isSignedIn")
    return m.homeScene.callFunc("isUserSignedIn")
end function

'---------------------
' Private methods
'---------------------

function onRegCodeResponse(event) as void

    VizbeeHomeSSOLog("VERB", "VizbeeHomeSSOSignInAdapter::onRegCodeResponse")
    m.networkHttpTask.unObserveField("response")
    m.networkHttpTask.control = "STOP"
    regCodeResponse = event.getData()
    if regCodeResponse = invalid or regCodeResponse.code = invalid
        VizbeeHomeSSOLog("WARN", "VizbeeHomeSSOSignInAdapter::onRegCodeResponse - regCodeResponse is invalid. Returning.")
        cancelSignIn()
        return
    end if

    m.deviceId = m.deviceId
    m.regCode = regCodeResponse.code

    ' step 2: update the signin status to in progress
    progressStatus = CreateObject("roSGNode", "VizbeeSignInProgressStatus")
    progressStatus.sType = m.signInInfo.signInType
    progressStatus.cData = {
        regCode: regCodeResponse.code
    }
    m.vizbeeSignInStatusCallback.progress = progressStatus
    m.homeScene.regcode = regCodeResponse.code

    ' sendSignInStatus(regCodeResponse.code, VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_IN_PROGRESS)

    ' step 3: start polling for signin status
    ' Call poll API - https://homesso.vizbee.tv/v1/accountregcode/poll
    ' Once polling is success and user is signed in, 
    '       navigate to app home screen
    '       serve any pending deeplink
    checkForPollingSuccess()
    m.repeatPollingStatusTimer = createObject("roTimespan")
    m.repeatPollingStatusTimer.Mark()
    m.pollingSignInStatusTimer = m.top.findNode("pollingSignInStatusTimer")
    m.pollingSignInStatusTimer.observeField("fire", "checkForPollingSuccess")
    m.pollingSignInStatusTimer.control  = "start"
end function

function checkForPollingSuccess() as void

    VizbeeHomeSSOLog("VERB", "VizbeeHomeSSOSignInAdapter::checkForPollingSuccess")

    ' Call regcode API - 
    ' Method: POST
    ' URI: https://homesso.vizbee.tv/v1/accountregcode/poll
    ' Payload: {"deviceId":"device_id_1", "regCode": "reg_code_1"}
    ' 
    ' Expected response
    '   {"status":"done","authToken":"6a85cfdcf9d95b70d2f84048d5120b7f"}

    m.networkHttpTask.observeField("response", "onPollingStatusResponse")
    m.networkHttpTask.request= { method: "POST", uri: "https://homesso.vizbee.tv/v1/accountregcode/poll", payload: {"deviceId": m.deviceId, "regCode": m.regCode} }
    m.networkHttpTask.control = "RUN"
end function

function onPollingStatusResponse(event) as void

    VizbeeHomeSSOLog("VERB", "VizbeeHomeSSOSignInAdapter::onPollingStatusResponse")
    m.networkHttpTask.unObserveField("response")
    m.networkHttpTask.control = "STOP"
    pollingStatusResponse = event.getData()
    if (pollingStatusResponse = invalid or pollingStatusResponse.status <> "done") then
        videoPlayer = m.homeScene.findNode("videoPlayer")
        if videoPlayer <> invalid and videoPlayer.visible = true
            if m.repeatPollingStatusTimer.TotalSeconds() < 90 then
                VizbeeHomeSSOLog("VERB", "VizbeeHomeSSOSignInAdapter::onPollingStatusResponse - pollingStatusResponse is not success and timedout")
                return
            else
                VizbeeHomeSSOLog("INFO", "VizbeeHomeSSOSignInAdapter::onPollingStatusResponse - pollingStatusResponse is not success, cancelling signin")
                cancelSignIn()
                return
            end if
        else
            VizbeeHomeSSOLog("VERB", "VizbeeHomeSSOSignInAdapter::onPollingStatusResponse - pollingStatusResponse is not success")
            return
        end if
    else 
        VizbeeHomeSSOLog("INFO", "VizbeeHomeSSOSignInAdapter::onPollingStatusResponse - pollingStatusResponse success")
        m.homeScene.callFunc("updateUserDetails", ({ email: pollingStatusResponse.email, authToken: pollingStatusResponse.authToken}))
    end if

    stopPolling()

    setSignInSuccessModalDesc(pollingStatusResponse.email + " has been signed in successfully.")
    m.homeScene.signInState = VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_COMPLETED
    successStatus = CreateObject("roSGNode", "VizbeeSignInSuccessStatus")
    successStatus.sType = m.signInInfo.signInType
    successStatus.cData = {
        email: pollingStatusResponse.email 
    }
    m.vizbeeSignInStatusCallback.success = successStatus
end function

'--------------
' UI methods
'--------------

function registerForRegcodeScreenEvents() as void
    VizbeeHomeSSOLog("INFO", "VizbeeHomeSSOSignInAdapter::registerForRegcodeScreenEvents")
    m.homeScene.observeField("pollingExited", "onPollingExited")
end function

function onPollingExited(registerForRegcodeScreenEvent as object) as void
    VizbeeHomeSSOLog("INFO", "VizbeeHomeSSOSignInAdapter::onPollingExited")
    cancelSignIn()
end function

function cancelSignIn() as void
    VizbeeHomeSSOLog("INFO", "VizbeeHomeSSOSignInAdapter::cancelSignIn")
    if m.networkHttpTask <> invalid then 
        m.networkHttpTask.unObserveField("response")
        m.networkHttpTask.control = "STOP"
    end if
    
    if m.homeScene.signInState = VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_IN_PROGRESS then
        stopPolling()
        failureStatus = CreateObject("roSGNode", "VizbeeSignInFailureStatus")
        failureStatus.sType = m.signInInfo.signInType
        failureStatus.reason = ""
        failureStatus.isCancelled = true
        failureStatus.exception = invalid
        failureStatus.cData = {}
        m.vizbeeSignInStatusCallback.failure = failureStatus
        m.homeScene.signInState = VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_CANCELLED
    end if
end function

function stopPolling() as void
    VizbeeHomeSSOLog("INFO", "VizbeeHomeSSOSignInAdapter::stopPolling")
    if m.pollingSignInStatusTimer <> invalid then
        m.pollingSignInStatusTimer.unObserveField("fire")
        m.pollingSignInStatusTimer.control  = "stop"
    end if
end function

'---------------------
' setter/getter methods for modal title and description
'---------------------

function setSignInSuccessModalTitle(successModalTitle = "" as string) as void
    m.successModalTitle = successModalTitle
end function
function getSignInSuccessModalTitle() as dynamic
    return m.successModalTitle
end function

function setSignInSuccessModalDesc(successModalDesc = "" as string) as void
    m.successModalDesc = successModalDesc
end function
function getSignInSuccessModalDesc() as dynamic
    return m.successModalDesc
end function

function setSignInProgressModalTitle(progressModalTitle = "" as string) as void
    m.progressModalTitle = progressModalTitle
end function
function getSignInProgressModalTitle() as dynamic
    return m.progressModalTitle
end function

function setSignInProgressModalDesc(progressModalDesc = "" as string) as void
    m.progressModalDesc = progressModalDesc
end function
function getSignInProgressModalDesc() as dynamic
    return m.progressModalDesc
end function

function setSignInInformationalModalTitle(informationalModalTitle = "" as string) as void
    m.informationalModalTitle = informationalModalTitle
end function
function getSignInInformationalModalTitle() as dynamic
    return m.informationalModalTitle
end function

function setSignInInformationalModalDesc(informationalModalDesc = "" as string) as void
    m.informationalModalDesc = informationalModalDesc
end function
function getSignInInformationalModalDesc() as dynamic
    return m.informationalModalDesc
end function