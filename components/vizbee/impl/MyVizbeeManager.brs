'********************************************************************
' Vizbee Screen SDK
' Copyright (c) 2014-2020 Vizbee Inc.
' All Rights Reserved.
'
' TODO: You must implement video playback methods here.
'
' This class supports five playback methods and custom event method:
' 1. 'startVideo' is a mandatory method that you need to implement in this class.
' 2. 'seekVideo' is an optional method.
' 3. 'pauseVideo' is an optional method.
' 4. 'playVideo' is an optional method.
' 5. 'stopVideo' is an optional method.
' 6. 'onEvent' is an optional method.
' *******************************************************************

sub init()
    m.scene = m.top.getScene()
    m.scene.observeField("signInState", "onSignInStateChange")

    m.isSignInInProgress = false
    m.isFirstDeeplinkVideo = true
    m.deferredVideoInfo = invalid
    m.deeplinkDelayTimer = invalid
    m.deferredStopVideo = invalid

    m.homeScene = m.top.getScene()
end sub

'-----------------------------------------------------------
' Implement these mobile-to-roku APIs as needed.
' Only 'startVideo' API is mandatory, rest are optional.
'-----------------------------------------------------------

' @function startVideo
' @param {Object}  videoInfo
'        {String}  videoInfo.guid
'        {String}  videoInfo.url
'        {Integer} videoInfo.startTime
'        {boolean} videoInfo.isLive
'        {String}  videoInfo.title
'        {String}  videoInfo.subtitle
'        {String}  videoInfo.desc
'        {String}  videoInfo.imgurl
'        {Object}  videoInfo.customstreaminfo
'        {Object}  videoInfo.custommetadata
' @description
' This method is invoked when a start command is received from the mobile device
' to initiate playback of a video.
' You MUST implement this method for your application

sub startVideo(event as object)

    videoInfo = event.getData()
    vizbee_log("INFO", "MyVizbeeManager::startVideo - Deeplinking to start video: " + FormatJson(videoInfo))

    if m.isSignInInProgress = true then
        vizbee_log("INFO", "MyVizbeeManager::startVideo - holding deeplink as sign in is in progress")
        m.deferredVideoInfo = event
        if m.homeScene.isMobileUserSignedIn = false then
            m.global.VZBManager.callFunc("sendVideoStopWithReason", "Sign-in in progress")
        end if
        return
    end if

    if videoInfo.guid = "sintel" and m.homeScene.callFunc("isUserSignedIn") <> true then
        vizbee_log("INFO", "MyVizbeeManager::startVideo - holding deeplink as this is authenticated stream and is not signed in yet. Initiating sign in flow.")
        m.deferredVideoInfo = event
        signInEvent = {
            "type": "tv.vizbee.homesso.signin",
            "data": {
                "sub_type":"start_sign_in",
                "sinfo": {
                    "is_signed_in": true,
                    "stype" : "MVPD",
                    "device_model" : "iPhone 11",
                    "device_os"    : "iOS"
                    "custom_data"  : {}
                }
            }
        }
        m.global.VZBHomeSSOManager.callFunc("onEvent", signInEvent)
        return
    end if

    if m.isFirstDeeplinkVideo = true then
        vizbee_log("INFO", "MyVizbeeManager::startVideo - this is the first video deeplinked, starting a timer to avoid sign in issues")
        m.isFirstDeeplinkVideo = false
        m.deferredVideoInfo = event
        m.deeplinkDelayTimer = m.top.createChild("Timer")
        m.deeplinkDelayTimer.ObserveField("fire", "onDeeplinkDelayTimerFired")
        m.deeplinkDelayTimer.duration = 4
        m.deeplinkDelayTimer.control = "start"
        return
    end if

    item = getItemByGUID(videoinfo.guid, m.global.playlist)
    if (invalid <> item) then

        nodeitem = createObject("RoSGNode","ContentNode")
        for each key in item
            nodeitem[key] = item[key] 
        end for
        nodeitem.PlayStart = videoinfo.startTime

        m.global.scene.selectedVideoContent = nodeitem
    else
        vizbee_log("PROD", "MyVizbeeManager::startVideo - Could not resolve GUID")
        nodeitem = createObject("RoSGNode","ContentNode")
        nodeitem.stream = {url: videoInfo.url}
        nodeitem.url = videoInfo.url
        'nodeitem.streamFormat = "hls"
        nodeitem.HDPosterUrl = videoInfo.imgurl
        nodeitem.hdBackgroundImageUrl = videoInfo.imgurl
        nodeitem.title = videoInfo.title
        nodeitem.description = "Video casted from mobile"
        nodeitem.guid = videoInfo.guid
        nodeitem.id = videoInfo.guid
        nodeitem.PlayStart = videoinfo.startTime
        if videoInfo.tracks <> invalid then
            nodeitem.subtitleTracks = videoInfo.tracks
        end if

        m.global.scene.selectedVideoContent = nodeitem
    end if

    m.deferredVideoInfo = invalid
end sub

' @function seekVideo
' @param {Number} offsetMs - offset in milliseconds
' @description
' This method is invoked when a seek command is received from the mobile device.

' sub seekVideo(seekEvent as object)

'     seekParams = seekEvent.getData()
'     print "MyVizbeeManager::seekVideo"
'     ' Implement your seek video here
' end sub

' @function pauseVideo
' @param {roSGNode of type video} player
' @description
' This method is invoked when a pause command is received from the mobile device.

' sub pauseVideo(pauseEvent as object)

'     pauseParams = pauseEvent.getData()
'     print "MyVizbeeManager::pauseVideo"
'     ' Implement your pause video here
' end sub

' @function playVideo
' @param {roSGNode of type video} player
' @description
' This method is invoked when a play command is received from the mobile device.

' sub playVideo(playEvent as object)

'     playParams = playEvent.getData()
'     print "MyVizbeeManager::playVideo"
'     ' Implement your play video here
' end sub

' @function stopVideo
' @param {roSGNode of type video} player
' @param {String} stopReason - stop_reason_unknown, stop_by_user or stop_implicit
' @description
' This method is invoked when a stop command is received from the mobile device.
' The stopReason indicates whether the user invoked the stop explicitly or,
' the Vizbee SDK implicitly sent a stop because the user switched the video.
' NOTE: You can ignore stopReason unless you want to create custom UI experiences while switching videos.

sub stopVideo(stopEvent as object)

    stopParams = stopEvent.getData()
    print "MyVizbeeManager::stopVideo"

    ' Implement your stop video here
    if m.isSignInInProgress = true then
        vizbee_log("INFO", "MyVizbeeManager::stopVideo - holding stop video as sign in is in progress")
        m.deferredStopVideo = stopEvent
        return
    else
        vizbee_log("INFO", "MyVizbeeManager::stopVideo - invoking deferred stop video")
        m.deferredStopVideo = invalid
        stopVideoDefaultImpl()
    end if
end sub

'-----------------------------------------------------------
' Implement this roku-to-mobile API if needed.
'-----------------------------------------------------------

' @function getVideoInfo
' @param {roSGNode of type video} sgVideoNode
' @return {Object}  videoInfo
'
'         ' Mandatory fields
'         {String}  videoInfo.guid
'         {boolean} videoInfo.isLive
'         {String}  videoInfo.title
'         {String}  videoInfo.imgurl
'
'          ' Optional metadata
'         {String}  videoInfo.subtitle
'         {String}  videoInfo.desc
'
'         ' Optional streamInfo
'         {String}  videoInfo.url
'         {Integer} videoInfo.startTime
'
'         ' Optional custom parameters
'         {Object}  videoInfo.customstreaminfo
'         {Object}  videoInfo.custommetadata
' @description
' function getVideoInfo(sgVideoNode) as Object

'     print "MyVizbeeManager::getVideoInfo"
'     ' Implement your getVideoInfo here
' end function

'-----------------------------------------------------------------
' Implement this 'onEvent' method for your application if needed
'-----------------------------------------------------------------

' @function onEvent
' @param {Object}  eventInfo
'        {String}  eventInfo.type
'        {String}  eventInfo.data
' @description
' This method is invoked when a custom event is received from the mobile device.

' sub onEvent(event as object)

'     eventInfo = event.getData()
'     print "MyVizbeeManager::onEvent"
'     ' Implement your onEvent here
' end sub

'----------------
'Helper methods
'----------------
function getItemByGUID(guid, playlist)

    for each item in playlist
        if (item.guid = guid) then
            return item
        end if
    end for

end function

function onSignInStateChange(signInStateChangeEvent as object)

    signInState = signInStateChangeEvent.getData()
    ? "MyVizbeeManager::signInStateChangeEvent - signInState: "; signInState

    if (signInState = VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_COMPLETED or signInState = VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_FAILED or signInState = VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_CANCELLED) then
        vizbee_log("INFO", "MyVizbeeManager::signInStateChangeEvent - sign in completed/failed")
        m.isSignInInProgress = false

        ' handle deferred stop video
        if m.deferredStopVideo <> invalid then
            vizbee_log("INFO", "MyVizbeeManager::signInStateChangeEvent - initiating deferred stop video")
            stopVideo(m.deferredStopVideo)
        end if

        ' handle deferred deeplink
        if m.deferredVideoInfo <> invalid then
            vizbee_log("INFO", "MyVizbeeManager::signInStateChangeEvent - initiating deferred deeplink")
            if m.deeplinkDelayTimer <> invalid then
                m.deeplinkDelayTimer.control = "stop"
            end if
            startVideo(m.deferredVideoInfo)
        end if
    else
        vizbee_log("VERB", "MyVizbeeManager::signInStateChangeEvent - sign in in progress")
        m.isSignInInProgress = true
    end if
end function

function onDeeplinkDelayTimerFired() as void
    m.global.scene.selectedVideoContent = invalid
    if m.deeplinkDelayTimer <> invalid then
        m.deeplinkDelayTimer.control = "stop"
    end if
    vizbee_log("INFO", "MyVizbeeManager::startVideo - sign in progress timer finished, releasing deeplink that was help")
    startVideo(m.deferredVideoInfo)
end function