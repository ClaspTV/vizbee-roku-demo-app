'********************************************************************
' Vizbee Screen SDK
' Copyright (c) 2014-2020 Vizbee Inc.
' All Rights Reserved.
'
' VizbeeManager
' You must create a child component that extends this class and implements the required playback methods.
'
' This class supports four public APIs:
' 1. 'initVizbeeSDK' function is used to initialize the VizbeeSDK.
' 2. 'getHostAppFeatureFlags' function is used to get the feature flags configured for host app.
' 3. 'activeVideoNode' field is used to set the videoNode so VizbeeSDK can capture the video status.
' 4. 'shouldMonitorVideoNode' is an optional field used to enable/disable videoNode monitoring.
'
' This class supports three playback methods:
' 1. 'startVideo' is a mandatory function that you need to override in your child component.
' 2. 'seekVideo' is an optional function.
' 3. 'stopVideo' is an optional function.
' *******************************************************************

sub init()

    m.videoPlayer = invalid
    m.deferredStartEvent = invalid
    m.playerStateOnSeek = invalid
    m.didPauseAfterSeekCompletion = false
    m.hostAppFeatureFlags = {}

    m.top.observeField("activeVideoNode", "setActiveVideoNode")
    m.top.observeField("shouldMonitorVideoNode", "setVideoNodeMonitoring")
    m.top.observeField("rafCallbackData", "setRafCallbackData")
    m.top.observeField("ssaiAdCallbackData", "setSSAIAdCallbackData")
    m.top.observeField("isSignInInProgress", "onSignInStatusChange")

    ' create vizbee sdk task
    m.sdkTask = createObject("roSGNode", "VizbeeSDKTask")
    m.sdkTask.observeField("onHostAppFeatureFlags", "onHostAppFeatureFlagsImpl")
    m.sdkTask.observeField("onStartVideo", "onStartVideoDefaultImpl")
    m.sdkTask.observeField("onPauseVideo", "pauseVideo")
    m.sdkTask.observeField("onPlayVideo", "playVideo")
    m.sdkTask.observeField("onSeekVideo", "seekVideo")
    m.sdkTask.observeField("onStopVideo", "stopVideo")
    m.sdkTask.observeField("onFinishVideo", "finishVideo")
    m.sdkTask.observeField("onGetVideoInfo", "getVideoInfoAsync")
    m.sdkTask.observeField("onEvent", "onEventImpl")

    ' create rr task
    m.rrTask = createObject("roSGNode", "VizbeeRRTask")
    m.rrTask.observeField("onRRCmdResponse", "rrCmdResponse")

    m.rrConfigHelper = vizbee_rr_config_helper()

    m.vzbEventManager = CreateObject("roSGNode", "VizbeeEventManager")
    m.vzbEventManager.observeField("eventInfo", "onEventDefaultImpl")
end sub

' -------------
' Public APIs
' -------------

' @function initVizbeeSDK
' @param {String}  vizbeeAppId - vizbee appId provided by vizbee
'        {Object}  rokuLaunchParams - app launch parameters
'        {Object}  options - optional parameter
'        {Boolean} options.isProduction - set as 'false' to run with vizbee staging configuration.
'                       Default value is true
' @description
' This method is used to initialize the VizbeeSDK.

function initVizbeeSDK(vizbeeAppId as string, rokuLaunchParams as object, options = { isProduction: true } as object) as boolean

    vizbee_log("INFO", "VizbeeManager::initVizbeeSDK - " + vizbeeAppId + ", rokuLaunchParams", rokuLaunchParams)
    vizbee_log("INFO", "VizbeeManager::initVizbeeSDK - options", options)

    ' validate the input parameters for SDK initialisation
    if not canInitVizbeeSDK(vizbeeAppId, rokuLaunchParams)
        return false
    end if

    ' check whether app was launched by vizbee
    vzbLaunchParameter = rokuLaunchParams.vzb
    if vzbLaunchParameter <> invalid and vzbLaunchParameter <> ""
        m.top.wasAppLaunchedByVizbee = true
    end if

    ' get the input params for vizbee task
    m.sdkTask.sdkInitParams = getSDKTaskInput(vizbeeAppId, rokuLaunchParams, options)

    ' IMPORTANT: If a Task is already in a given state as indicated by its state field, including RUN,
    ' setting its control field to that same state value has no effect. 
    ' To rerun a Task, it must be in the STOP state, either by returning from its function 
    ' or being commanded to STOP via its control field.
    '
    ' Based on above info,
    ' 1. Calling init API mulitple times with SDK already initialized will have no effect,
    '    since it will be in same state RUN
    ' 2. Calling init API again with SDK not being initialized will execute the task,
    '    since it will be in STOP state because of returning from its execute function within the task 
    m.sdkTask.control = "RUN"

    return true
end function

' @function getHostAppFeatureFlags
' @description
' This method returns an object from config with all feature flags defined for host app
function getHostAppFeatureFlags() as object
    return m.hostAppFeatureFlags
end function

' @function setActiveVideoNode
' @param {Object}  videoPlayer - video player object to monitor the video playback heartbeat
' @description
' This method is used to set the current active videoPlayer so VizbeeSDK can capture the video status.

sub setActiveVideoNode(activeVideoNodeEvent as object)
    setActiveVideoNodeDefaultImpl(activeVideoNodeEvent)
end sub

sub setActiveVideoNodeDefaultImpl(activeVideoNodeEvent as object)
    
    ' set vizbee sdk tasks' video player
    videoPlayer = activeVideoNodeEvent.getData()
    if videoPlayer <> invalid

        m.videoPlayer = videoPlayer
        if m.sdkTask <> invalid
            m.sdkTask.videoPlayer = videoPlayer
        end if
        
        retainPausedStateAfterSeek()
    end if
end sub

' @function setVideoNodeMonitoring
' @param {Boolean} shouldMonitorVideoPlayer
' @description
' This method is used to enable/disable videoPlayer monitoring.

sub setVideoNodeMonitoring(monitorEvent as object)

    ' set vizbee sdk task's videoPlayer monitoring flag
    if m.sdkTask <> invalid
        m.sdkTask.shouldMonitorVideoPlayer = monitorEvent.getData()
    end if
end sub

' @function setRafCallbackData
' @param {Object} eventType and ctx
' @description
' This method is used to pass ad event to core SDK.

sub setRafCallbackData(rafCallbackEvent as object)

    ' set vizbee sdk task's setRafCallbackData
    if m.sdkTask <> invalid
        m.sdkTask.rafCallbackData = rafCallbackEvent.getData()
    end if
end sub

' @function setSSAIAdCallbackData
' @param {Object} adapterType and adEventData
' @description
' This method is used to pass ad adapter and ad event details to core SDK to monitor ad status.

sub setSSAIAdCallbackData(ssaiCallbackEvent as object)
    ssaiAdCallbackData = ssaiCallbackEvent.getData()
    if ssaiAdCallbackData = invalid
        return
    end if
    adapterType = ssaiAdCallbackData.adapterType
    adEventData = ssaiAdCallbackData.adEventData
    if m.sdkTask <> invalid
        m.sdkTask.ssaiAdCallbackData = {
            adapterType: adapterType
            adEventData: adEventData
        }
    end if
end sub

' @function registerForEvent
' @param {String} eventName
' @param {Object} eventHandler
' @description
' This method is used to register for custom event.
function registerForEvent(eventName as string, eventHandler as object) as void
    m.vzbEventManager.callFunc("registerForEvent", eventName, eventHandler)
end function

' @function unregisterForEvent
' @param {String} eventName
' @param {Object} eventHandler
' @description
' This method is used to unregister from custom event
function unregisterForEvent(eventName as string, eventHandler as object) as void
    m.vzbEventManager.callFunc("unregisterForEvent", eventName, eventHandler)
end function

' @function sendEventWithName
' @param {String} eventName
' @param {Object} eventData
' @description
' This method is used to send the event with data to the mobile via sync.
function sendEventWithName(eventName as string, eventData as object) as void
    if m.sdkTask <> invalid
        m.sdkTask.eventInfo = { eventName: eventName, eventData: eventData } 
    end if
end function

' @function logMetricsEvent
' @param {String} eventName
' @param {Object} eventProperties
' @description
' This method is used to send the metrics event with properties.
function logMetricsEvent(eventName as string, eventProperties as object) as void
    if m.sdkTask <> invalid
        m.sdkTask.metricsEventInfo = { name: eventName, properties: eventProperties } 
    end if
end function

'-----------
' startVideo
'-----------

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
' This method is used to start video playback from mobile device.

sub onStartVideoDefaultImpl(startEvent as object)

    if m.top.isSignInInProgress = false
        m.top.wasVideoStartedByVizbee = true
        startVideo(startEvent)
    else
        m.deferredStartEvent = startEvent
    end if
end sub

sub startVideo(startEvent as object)
    vizbee_log("PROD", "WARNING!! VizbeeManager::startVideo() - startVideo method NOT implemented in your component class that extented this class")
end sub

'-----------
' pauseVideo
'-----------

' @function pauseVideo
' @param {roSGNode of type video} player
' @description
' This method is used to pause video playback from mobile device.

sub pauseVideo(pauseEvent as object)

    vizbee_log("INFO", "VizbeeManager::pauseVideo")
    pauseVideoDefaultImpl()
end sub

sub pauseVideoDefaultImpl()

    if m.rrConfigHelper.isRREnabled()

        ' send `pause` RR command on a separate thread
        vizbee_log("INFO", "VizbeeManager::pauseVideoDefaultImpl - pause using RR")
        m.rrTask.rrCommand = "pause"
        m.rrTask.control = "RUN"
    else
        
        if m.videoPlayer <> invalid
            vizbee_log("INFO", "VizbeeManager::pauseVideoDefaultImpl - pause using SGNode")
            m.videoPlayer.control = "pause"
        end if
    end if
end sub

'----------
' playVideo
'----------

' @function playVideo
' @param {roSGNode of type video} player
' @description
' This method is used to play video playback from mobile device.

sub playVideo(playEvent as object)

    vizbee_log("INFO", "VizbeeManager::playVideo")
    playVideoDefaultImpl()
end sub

sub playVideoDefaultImpl()

    if m.rrConfigHelper.isRREnabled()

        ' send `play` RR command on a separate thread
        vizbee_log("INFO", "VizbeeManager::playVideoDefaultImpl - play using RR")
        m.rrTask.rrCommand = "play"
        m.rrTask.control = "RUN"
    else
        
        if m.videoPlayer <> invalid
            vizbee_log("INFO", "VizbeeManager::playVideoDefaultImpl - play using SGNode")
            
            ' call resume using SGNode,
            ' using play will start the video from beginning
            m.videoPlayer.control = "resume"
        end if
    end if
end sub

'----------
' seekVideo
'----------

' @function seekVideo
' @param {Number} offsetMs - offset in milliseconds
' @description
' This method is used to seek video playback from mobile device.

sub seekVideo(seekEvent as object)

    seekParams = seekEvent.getData()
    vizbee_log("INFO", "VizbeeManager::seekVideo", seekParams)

    offsetMs = seekParams.offsetMs
    if m.videoPlayer <> invalid and offsetMs <> invalid

        ' Save the player state before seeking
        ' to maintain the paused state after seeking
        m.playerStateOnSeek = m.videoPlayer.state
        if type(m.videoPlayer) = "roSGNode"
            m.videoPlayer.seek = cint(offsetMs / 1000)
        else
            m.videoPlayer.Seek(offsetMs)
        end if
    end if
end sub

'----------
' stopVideo
'----------

' @function stopVideo
' @param {roSGNode of type video} player
'        {String} stopReason - stop_reason_unknown, stop_by_user or stop_implicit
' @description
' This method is used to stop video playback from mobile device.
' The stopReason indicates whether the user invoked the stop explicitly or,
' the Vizbee SDK implicitly sent a stop because the user switched the video.
' NOTE: You can ignore stopReason unless you want to create custom UI experiences while switching videos.

sub stopVideo(stopEvent as object)

    vizbee_log("INFO", "VizbeeManager::stopVideo")
    stopVideoDefaultImpl()
end sub

sub stopVideoDefaultImpl()

    if m.rrConfigHelper.isRREnabled()

        ' send `stop` RR command on a separate thread
        vizbee_log("INFO", "VizbeeManager::stopVideoDefaultImpl - stop using RR")
        m.rrTask.rrCommand = "back"
        m.rrTask.control = "RUN"
    else
        
        if m.videoPlayer <> invalid
            vizbee_log("INFO", "VizbeeManager::stopVideoDefaultImpl - stop using SGNode")
            m.videoPlayer.control = "stop"
        end if
    end if
end sub

sub finishVideo(finishEvent as object)

    vizbee_log("INFO", "VizbeeManager::finishVideo")
    m.top.wasVideoStartedByVizbee = false
end sub

'------------------
' getVideoInfoAsync
'------------------

' @function getVideoInfoAsync
' @param {roSGNode of type video} sgVideoNode
' @description
' This method is used to get video info of current video.

sub getVideoInfoAsync(videoInfoEvent as object)

    vizbee_log("INFO", "VizbeeManager::getVideoInfoAsync")
    m.sdkTask.videoInfo = getVideoInfo(videoInfoEvent.getData().sgVideoNode)
end sub

function getVideoInfo(sgVideoNode as object) as dynamic

    content = sgVideoNode.content
    if content = invalid
        return invalid
    end if

    vizbee_log("INFO", "VizbeeManager::getVideoInfo")

    videoInfo = {
        guid: ""
        isLive : false
    }
    if content.id <> invalid
        videoInfo.guid = content.id.toStr()
    end if
    if (content.live = true)
        videoInfo.isLive = true
    end if

    videoInfo.title = content.title
    videoInfo.subtitle = content.subtitle
    videoInfo.imgurl = getPosterURL(content)

    return videoInfo
end function

' -------
' onEvent
' -------

' @function onEventImpl
' @param {Object}  eventInfo
'        {String}  eventInfo.type
'        {String}  eventInfo.data
' @description
' This method is invoked by Vizbee SDK when a custom event is received from the mobile device.

sub onEventImpl(event as object)

    eventInfo = event.getData()
    vizbee_log("INFO", "VizbeeManager::onEventImpl", eventInfo)

    if eventInfo <> invalid AND eventInfo.type <> invalid AND eventInfo.data <> invalid
        m.vzbEventManager.callFunc("onEvent", eventInfo)
    end if
end sub

' @function onEventDefaultImpl
' @param {Object}  eventInfo
'        {String}  eventInfo.type
'        {String}  eventInfo.data
' @description
' This method is invoked by VizbeeEventManager as a fallback when there are no subscribers.

sub onEventDefaultImpl(event as object)

    eventInfo = event.getData()
    vizbee_log("INFO", "VizbeeManager::onEventDefaultImpl", eventInfo)

    if eventInfo <> invalid AND eventInfo.type <> invalid AND eventInfo.data <> invalid

        eventType = LCase(eventInfo.type)
        if eventType = "tv.vizbee.homesso.signin" or eventType = "tv.vizbee.homesign.signin"
            onSigninEvent(eventInfo.data.authInfo)
        end if

    end if

    onEvent(event)
end sub

sub onEvent(event as object)

    ' do nothing
    ' host app will override if needed
end sub

sub onSigninEvent(signinInfo as object)

    if signinInfo = invalid
        vizbee_log("WARN", "VizbeeManager::onSigninEvent - siginInfo is not available.")
        return
    end if
    
    ' checking if welcomePopover exists and
    ' assumption is welcomePopover is attached to home scene of app
    vizbee_log("INFO", "VizbeeManager::onSigninEvent")
    welcomePopover = invalid
    scene = m.top.getScene()
    if scene <> invalid
        welcomePopover = scene.findNode("vizbeeWelcomePopover")
    end if
    if welcomePopover = invalid
        vizbee_log("WARN", "VizbeeManager::onSigninEvent - welcomePopover component not found in host app.")
        return
    end if
    
    username = ""
    if vizbee_util().isStringAndValueNotEmpty(signinInfo.userFullName)
        username = signinInfo.userFullName
    else if vizbee_util().isStringAndValueNotEmpty(signinInfo.userLogin)
        username = signinInfo.userLogin
    end if
    if username <> ""
        welcomePopover.callFunc("show", username)
    end if
end sub

sub sendVideoStopWithReason(reason as string, additionalInfo=invalid as dynamic)
    vizbee_log("INFO", "VizbeeManager::sendVideoStopWithReason - reason: " + reason + ", additionalInfo: ", additionalInfo)
    ' reason: string - required
    ' additionalInfo: assocarray - optional

    ' Examples:
    ' Stop video when app is not ready to play video (sign in preogress)
    ' reason = "Sign-in in progress"

    ' Stop video when app failed to play video
    ' reason = "Failed to play video"
    ' additionalInfo: {
    '     error: {
    '         number: number
    '         message: string
    '         backtrace: stacktrace object
    '     }
    ' }
    m.sdkTask.videoStopReasonInfo = { 
        reason: reason 
        additionalInfo: additionalInfo
    }
end sub

sub onSignInStatusChange()
    if m.top.isSignInInProgress = false and m.deferredStartEvent <> invalid
        onStartVideoDefaultImpl(m.deferredStartEvent)
        m.deferredStartEvent = invalid
    end if
end sub

' -------------
' Feature Flags
' -------------

sub onHostAppFeatureFlagsImpl(event as object)

    eventInfo = event.getData()
    vizbee_log("INFO", "VizbeeManager::onHostAppFeatureFlagsImpl", eventInfo)

    if eventInfo <> invalid
        m.hostAppFeatureFlags = eventInfo
    end if
end sub

' --------------
' Helper methods
' --------------

sub rrCmdResponse(rrCmdResponseEvent as object)
    m.rrTask.control = "STOP"
end sub

function canInitVizbeeSDK(vizbeeAppId as string, rokuLaunchParams as object) as boolean

    if vizbeeAppId = invalid or vizbeeAppId = ""
        vizbee_log("PROD", "WARNING! VizbeeManager::canInitVizbeeSDK() - vizbee AppID not provided")
        return false
    end if

    if rokuLaunchParams = invalid
        vizbee_log("PROD", "WARNING! VizbeeManager::canInitVizbeeSDK() - rokuLaunchParams not provided")
        return false
    end if

    return true
end function

function getSDKTaskInput(vizbeeAppId as string, rokuLaunchParams as object, options as object) as object

    taskInput = {
        appId: vizbeeAppId
        rokuLaunchParams: rokuLaunchParams
        options: options
    }

    if options <> invalid and options.isProduction = invalid
        options.isProduction = true
    end if

    if options = invalid
        options = {
            isProduction: true
        }
    end if
    return taskInput
end function

function getPosterURL(content as dynamic) as string

    poster_url = ""

    if invalid = content
        return poster_url
    end if

    if vizbee_util().isStringAndValueNotEmpty(content.sdPosterUrl)
        poster_url = content.sdPosterUrl
    else if vizbee_util().isStringAndValueNotEmpty(content.hdPosterUrl)
        poster_url = content.hdPosterUrl
    else if vizbee_util().isStringAndValueNotEmpty(content.fhdPosterUrl)
        poster_url = content.fhdPosterUrl
    end if

    return poster_url
end function

sub sendStartVideoFailure(failureInfo as Object)
    if validateStartVideoFailureInfo(failureInfo)
        m.sdkTask.startVideoFailureInfo = failureInfo
    else
        vizbee_log("WARN", "WARNING! VizbeeManager::sendStartVideoFailure() - INVALID failureInfo")
    end if
end sub

function validateStartVideoFailureInfo(failureInfo as dynamic) as boolean

    ' Following the same error structure that Roku has:
    ' failureInfo: {
    '   number :number
    '   message :string
    '   backtrace :stacktrace object
    ' }

    return failureInfo <> invalid and failureInfo.message <> invalid
end function

function retainPausedStateAfterSeek() as void

    ' Make sure to maintain the previous player state (paused) after seeking

    ' didPauseAfterSeekCompletion flag is used to make 
    ' sure that the video is paused from vizbee after seek
    if m.videoPlayer <> invalid and m.playerStateOnSeek = "paused" then
        if m.videoPlayer.state = "playing" then
            ' send pause after seek completion
            pauseVideoDefaultImpl()
            m.didPauseAfterSeekCompletion = true
        else if m.videoPlayer.state = "paused" and m.didPauseAfterSeekCompletion = true then
            m.playerStateOnSeek = invalid
            m.didPauseAfterSeekCompletion = false
        end if
    end if
end function