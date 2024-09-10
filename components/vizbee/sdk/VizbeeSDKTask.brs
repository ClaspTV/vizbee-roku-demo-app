'********************************************************************
' Vizbee Screen SDK
' Copyright (c) 2014-2020 Vizbee Inc.
' All Rights Reserved.
'
' VizbeeSDKTask
' *******************************************************************

' -------------
' Init methods
' -------------

sub init()

    'Create the port
    m.port = CreateObject("roMessagePort")
    m.top.observeField("rafCallbackData", m.port)
    m.top.observeField("ssaiAdCallbackData", m.port)
    m.top.observeField("eventInfo", m.port)
    m.top.observeField("metricsEventInfo", m.port)

    ' By default, monitor videoNode for status
    m.top.shouldMonitorVideoPlayer = true

    m.currentVideoInfoURL = invalid
    m.currentVideoIDFromSync = invalid

    m.top.functionName = "execute"
end sub

function execute() as boolean

    vizbee_log("INFO", "VizbeeSDKTask::execute")

    ' Get input params to initialise SDK
    sdkInitParams = m.top.sdkInitParams
    if sdkInitParams = invalid
        return false
    end if

    ' Set SDK env
    if sdkInitParams.options.isProduction
        VZB().GetOptions().SetProduction()
    else
        VZB().GetOptions().SetStaging()
    end if

    ' Set launch parameters
    VZB().GetOptions().setLaunchParameters(sdkInitParams.rokuLaunchParams)

    ' Set customAttributes
    VZB().GetOptions().SetCustomAttributesForMetrics(sdkInitParams.options.customAttributes)

    ' Initialize Vizbee SDK
    VZB().Start(sdkInitParams.appId, getSDKAdapter())

    ' Failed to initialize Vizbee SDK,
    ' so returning from this function which inturn will STOP the task
    isVizbeeSDKInitialized = VZB().config.isActive
    if NOT isVizbeeSDKInitialized
        return isVizbeeSDKInitialized
    end if

    m.global.addFields({ VizbeeConfig: VZB().config.properties })

    ' Set hostAppFeatureFlags
    m.top.onHostAppFeatureFlags = VZB().GetHostAppFeatureFlags()

    while(true)
        msg = wait(250, m.port)

        ' Vizbee monitor screen
        VZB().MonitorScreen(msg, m.port, "MainScreen", true)

        ' Handle video failure when video node is not available
        ' Usecases:
        ' 1. The host app is not able to resolve
        ' 2. The host app is not able to start playback due to authentication failure
        if m.top.startVideoFailureInfo <> invalid then
            VZB().SendStartVideoFailure(m.top.startVideoFailureInfo)
            m.top.startVideoFailureInfo = invalid
        end if

        if m.top.videoStopReasonInfo <> invalid then
            VZB().SendVideoStopWithReason(m.top.videoStopReasonInfo)
            m.top.videoStopReasonInfo = invalid
        end if

        ' Vizbee monitor video
        videoPlayer = m.top.videoPlayer
        if videoPlayer <> invalid

            if m.top.shouldMonitorVideoPlayer
                VZB().MonitorSGVideo(videoPlayer)
            end if

            videoPlayerState = videoPlayer.state
            if isVideoStartedFromSync() and isVideoFinished(videoPlayerState)
                m.currentVideoIDFromSync = invalid
                m.top.onFinishVideo = { reason: videoPlayerState }
            end if
        end if

        ' 
        msgType = type(msg)
        if msgType = "roSGNodeEvent"
            if msg.getField() = "rafCallbackData"
                rafCallBackData = msg.getData()
                VZB().onRafCallbackData(rafCallBackData)
            else if msg.getField() = "ssaiAdCallbackData"
                ssaiAdCallbackData = msg.getData()
                VZB().onSSAIAdCallbackData(ssaiAdCallbackData)
            else if msg.getField() = "eventInfo"
                eventInfo = msg.getData()
                VZB().onEventInfo(eventInfo)
            else if msg.getField() = "metricsEventInfo"
                metricsEventInfo = msg.getData()
                VZB().logEvent(metricsEventInfo.name, metricsEventInfo.properties)
            end if
        end if
    end while
    return true
end function

' ----------------
' Helper methods
' ----------------

function isVideoFinished(state as string) as boolean
    return state = "stopped" OR state = "finished" OR state = "error"
end function

function isVideoStartedFromSync() as boolean

    videoInfo = m.top.videoInfo
    return videoInfo <> invalid and vizbee_util().isEqual(m.currentVideoIDFromSync, videoInfo.guid)
end function

' ----------------
' Adapter methods
' ----------------

' @function getSDKAdapter
' @description
' This method returns an object with all playback methods that will be invoked by Vizbee SDK when command is 
' received from mobile device

function getSDKAdapter() as object

    myTask = m
    return {
        task: myTask

        startVideo: startVideo
        pauseVideo: pauseVideo
        playVideo: playVideo
        seekVideoSegment: seekVideo
        stopVideo: stopVideo

        getVideoInfo: getVideoInfo

        onEvent: onEvent
    }
end function

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
' This method is invoked by Vizbee SDK when a start command is received from the mobile device
' to initiate playback of a video.

sub startVideo(videoInfo as object)

    if videoInfo <> invalid

        vizbee_log("INFO", "VizbeeSDKTask::startVideo", videoInfo)
        m.task.currentVideoIDFromSync = videoInfo.guid
        m.task.top.onStartVideo = videoInfo
    end if
end sub

' @function pauseVideo
' @param {roSGNode of type video} player
' @description
' This method is invoked by Vizbee SDK when a pause command is received from the mobile device.

sub pauseVideo(player as object)

    vizbee_log("INFO", "VizbeeSDKTask::pauseVideo")
    m.task.top.onPauseVideo = {
        player: player
    }
end sub

' @function playVideo
' @param {roSGNode of type video} player
' @description
' This method is invoked by Vizbee SDK when a play command is received from the mobile device.

sub playVideo(player as object)

    vizbee_log("INFO", "VizbeeSDKTask::playVideo")
    m.task.top.onPlayVideo = {
        player: player
    }
end sub

' @function seekVideo
' @param {Number} offsetMs - offset in milliseconds
' @description
' This method is invoked by Vizbee SDK when a seek command is received from the mobile device.

sub seekVideo(offsetMs as longinteger)

    vizbee_log("INFO", "VizbeeSDKTask::seekVideo - " + offsetMs.toStr())
    m.task.top.onSeekVideo = {
        offsetMs: offsetMs
    }
end sub

' @function stopVideo
' @param {roSGNode of type video} player
'        {String} stopReason - stop_reason_unknown, stop_by_user or stop_implicit
' @description
' This method is invoked by Vizbee SDK when a stop command is received from the mobile device.
' The stopReason indicates whether the user invoked the stop explicitly or,
' the Vizbee SDK implicitly sent a stop because the user switched the video.
' NOTE: You can ignore stopReason unless you want to create custom UI experiences while switching videos.

sub stopVideo(player as object, stopReason as string)

    vizbee_log("INFO", "VizbeeSDKTask::stopVideo - " + stopReason)
    m.task.top.onStopVideo = {
        player: player
        stopReason: stopReason
    }
end sub

function getVideoInfo(sgVideoNode as object) as dynamic

    if sgVideoNode <> invalid and sgVideoNode.content <> invalid

        ' we use the stream url to identify the video change
        videoUrl = sgVideoNode.content.url
        if videoUrl <> m.currentVideoInfoURL

            m.task.top.videoInfo = invalid
            m.currentVideoInfoURL = videoUrl
            m.task.top.onGetVideoInfo = {
                sgVideoNode: sgVideoNode
            }
        end if
        return m.task.top.videoInfo
    end if

    return invalid
end function

' @function onEvent
' @param {Object}  eventInfo
' @description
' This method is invoked by Vizbee SDK when a custom event is received from the mobile device.

sub onEvent(eventInfo as object)

    vizbee_log("INFO", "VizbeeSDKTask::onEvent", eventInfo)
    m.task.top.onEvent = eventInfo
end sub