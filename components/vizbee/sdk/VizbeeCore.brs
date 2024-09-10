'********************************************************************
'**  Vizbee Screen SDK
'**  Copyright (c) 2014-2015 Vizbee Inc.
'**  All Rights Reserved.
'**  Lightly obfuscated for your reading pleasure.
'********************************************************************
function VZB()
this = m.vizbeeScreenInstance
if (this = invalid)
this_config = vizbee_config()
this_options = vizbee_options()
this = {
GetOptions          : vizbee_get_options
SendStartVideoFailure: vizbee_send_start_video_failure
SendVideoStopWithReason: vizbee_send_video_stop_with_reason
Init                : vizbee_init
InitAsync           : vizbee_init_async
Start               : vizbee_start
StartAsync          : vizbee_start_async
MonitorScreen       : vizbee_monitor_screen
ForceMonitorScreen  : vizbee_force_monitor_screen
MonitorSGVideo      : vizbee_monitor_sg_video
onRafCallbackData   : vizbee_on_raf_callback_data
onSSAIAdCallbackData: vizbee_on_ssai_ad_callback_data
onEventInfo         : vizbee_on_event_info
logEvent            : vizbee_log_metrics_event
isLaunchedWithVizbee : false
vizbeeLaunchServiceType : "UNKNOWN"
deferredStartEnabled : false
GetHostAppFeatureFlags  : vizbee_get_host_app_feature_flags
Log                 : vizbee_log
MonitorCommon       : vizbee_monitor_common
InitCommon          : vizbee_init_common
InitPostConfig      : vizbee_init_post_config
config              : this_config
options             : this_options
appID               : invalid
appAdapter          : invalid
appProxy            : invalid
metrics             : invalid
}
m.vizbeeScreenInstance = this
if (m.global <> invalid)
m.global.addFields( {vizbee: this} )
end if
m.AddReplace("VizbeeStatus", "INACTIVE")
end if
return this
end function
function vizbee_get_options() as Dynamic
return m.options
end function
function vizbee_send_start_video_failure(startVideoFailureInfo as Object) as dynamic
if(m.appProxy = invalid) then
vizbee_log("WARN", "INVALID appProxy")
return false
end if
if(m.appProxy.syncController = invalid) then
vizbee_log("WARN", "INVALID syncController")
return false
end if
return m.appProxy.syncController.HandleStartVideoFailure(startVideoFailureInfo)
end function
function vizbee_send_video_stop_with_reason(videoStopInfo as Object) as dynamic
if(m.appProxy = invalid) then
vizbee_log("WARN", "INVALID appProxy")
return false
end if
if(m.appProxy.syncController = invalid) then
vizbee_log("WARN", "INVALID syncController")
return false
end if
return m.appProxy.syncController.HandleVideoStopWithReason(videoStopInfo)
end function
function vizbee_start(appID as String, appAdapter as Object) as Dynamic
m.Init(appID, appAdapter, m.options.isProduction, m.options.launchParameters)
end function
function vizbee_start_async(appID as String, appAdapter as Object, port = invalid) as Dynamic
m.InitAsync(appID, appAdapter, m.options.isProduction, m.options.launchParameters, port)
end function
function vizbee_init(appID as String, appAdapter as Object, isProduction=true as Boolean, args = invalid) as Dynamic
if (NOT m.InitCommon(appID, appAdapter, isProduction, args)) then
return false
end if
vizbee_log("INFO", "Initializing with VizbeeAppID: " + appID)
config = m.config.Get(appID, isProduction, false)
m.InitPostConfig()
end function
function vizbee_init_async(appID as String, appAdapter as Object, isProduction=true as Boolean, args = invalid,  port = invalid) as Dynamic
if (NOT m.InitCommon(appID, appAdapter, isProduction, args)) then
return false
end if
if (NOT type(port) = "roMessagePort")
vizbee_log("PROD", "Invalid port. Stopping initialization.")
end if
vizbee_log("INFO", "Initializing asynchronously with VizbeeAppID: " + appID)
config = m.config.Get(appID, isProduction, true, port, vizbee_init_post_config)
end function
function vizbee_init_common(appID as String, appAdapter as Object, isProduction as Boolean, args as Object) as Dynamic
if (NOT type(appAdapter) = "roAssociativeArray")
vizbee_log("PROD", "Invalid appAdapter. Stopping initialization.")
return false
end if
if (NOT type(appAdapter.startVideo) = "roFunction")
vizbee_log("PROD", "Invalid startVideo in appAdapter. Stopping initialization.")
return false
end if
if ((args <> invalid) AND (NOT type(args) = "roAssociativeArray"))
vizbee_log("PROD", "Invalid launch arguments. Stopping initialization.")
return false
end if
if (isProduction <> invalid) then
if (NOT VizbeeIsBoolean(isProduction)) then
vizbee_log("PROD", "Invalid isProduction flag -- expected boolean. Stopping initialization.")
return false
end if
end if
if (m.config.isActive)
vizbee_log("PROD", "Duplicate Init call, Vizbee SDK is already initialized.")
return false
end if
m.appID = appID
m.appAdapter = appAdapter
m.options.isProduction = isProduction
m.options.launchParameters = args
if ((args <> invalid) AND (args.source <> invalid))
if ((args.source = "external-control") OR (args.source = "dial"))
m.isLaunchedWithVizbee = true
if (args.source = "dial")
m.vizbeeLaunchServiceType = "dial"
else
m.vizbeeLaunchServiceType = "ecp"
end if
if (m.global <> invalid)
m.global.addFields( {vizbee: m} )
end if
end if
end if
return true
end function
function vizbee_init_post_config()
vzbSingleton = VZB()
if (vzbSingleton.config.isActive)
vzbSingleton.appProxy = vizbee_app_proxy(vzbSingleton.appID, vzbSingleton.appAdapter)
vzbSingleton.metrics = vizbee_metrics(vzbSingleton.config, vzbSingleton.options)
vzbSingleton.metrics.trackScreenLaunched()
end if
end function
function vizbee_get_host_app_feature_flags()
hostAppFeatureFlags = {}
if (NOT m.config.isActive)
vizbee_log("PROD", "GetHostAppFeatureFlags - config not active yet.")
return hostAppFeatureFlags
end if
if m.config.properties <> invalid AND m.config.properties.hostApp <> invalid
vizbee_log("INFO", "GetHostAppFeatureFlags", hostAppFeatureFlags)
hostAppFeatureFlags = m.config.properties.hostApp
end if
return hostAppFeatureFlags
end function
function vizbee_monitor_common(msg=invalid as Object, port=invalid as Object, state="SCREEN" as String, screenid="default" as String, isHomeScreen=false as Boolean) as Boolean
if (NOT type(port) = "roMessagePort")
vizbee_log("PROD", "Invalid port in MonitorScreen API")
return false
end if
if (msg <> invalid) AND (type(msg) = "roUrlEvent")
m.config.CheckForConfigResponse(msg, port, state, screenid)
end if
if (m.appProxy = invalid)
vizbee_log("PROD", "MonitorScreen - invalid appAdapter. Vizbee SDK was not initialized correctly.")
return false
end if
if (NOT m.config.isActive)
vizbee_log("PROD", "MonitorScreen - config not active yet.")
return false
end if
m.appProxy.UpdateStateAndPort(state, screenid, "", "", port, isHomeScreen)
return true
end function
function vizbee_force_monitor_screen(port=invalid as Object, screenid="default" as String, isHomeScreen=false as Boolean)
m.appProxy.currScreen = ""
m.MonitorCommon(invalid, port, "SCREEN", screenid, isHomeScreen)
end function
function vizbee_monitor_screen(msg=invalid as Object, port=invalid as Object, screenid="default" as String, isHomeScreen=false as Boolean) as Boolean
if (NOT m.MonitorCommon(msg, port, "SCREEN", screenid, isHomeScreen))
return false
end if
if m.deferredStartEnabled and m.appProxy.deferredStart
if m.appProxy.IsFirstScreen(screenid)
vizbee_log("INFO", "Launching app with deferred start")
m.appProxy.deferredStart = false
vizbee_log("INFO", "set video guid from start_video, deferred: " + m.appProxy.deferredVideoID)
videoState = {
state : "unknown"
id : "unknown"
isLive : false
enableTrickPlay : true
posms : -1
durms : -1
}
videoState.state = "RESET"
videoState.id = m.appProxy.deferredVideoID
m.appProxy.syncController.state.UpdateVideo(videoState)
m.appProxy.adapter.startVideo(m.appProxy.deferredVideoID, m.appProxy.deferredVideoTime, m.appProxy.deferredVideoUrl)
return false
else
vizbee_log("INFO", "Popping for deferred start")
return true
end if
end if
breakLoop = false
if (msg <> invalid)
if (type(msg) = "roUrlEvent")
breakLoop = m.appProxy.syncController.HandleChannelEvent(msg)
if (NOT m.appProxy.helloSent)
m.appProxy.helloSent = true
m.appProxy.syncController.SendHello()
end if
end if
end if
return breakLoop
end function
function vizbee_monitor_sg_video(videonode)
if (m.appProxy = invalid)
vizbee_log("PROD", "MonitorSGVideo - invalid appAdapter. Vizbee SDK was not initialized correctly.")
return false
end if
if (NOT m.config.isActive)
vizbee_log("PROD", "MonitorSGVideo - config not active yet.")
return false
end if
m.appProxy.syncController.HandleVideoSGEvent(videonode)
end function
function vizbee_log_metrics_event(eventName as String, eventProperties as Object)
if (m.metrics = invalid)
vizbee_log("PROD", "Metrics not initialized yet.")
return false
end if
m.metrics.LogEvent(eventName, eventProperties)
end function
function vizbee_app_proxy(id, adapter)
this = {
id                : id
adapter           : adapter
currState         : "SCREEN"
currScreen        : ""
currAd            : ""
currVideo         : ""
currPort          : ""
firstScreenSet    : false
firstScreen       : ""
helloSent         : false
UpdateStateAndPort    : vizbee_app_proxy_update_state_and_port
UpdateStateForRAFAd   : vizbee_app_proxy_update_state_for_RAF_ad
IsFirstScreen         : vizbee_app_proxy_is_first_screen
StartVideo         : vizbee_app_proxy_start_video
PauseVideo         : vizbee_app_proxy_pause_video
PlayVideo          : vizbee_app_proxy_play_video
StopVideo          : vizbee_app_proxy_stop_video
Seek               : vizbee_app_proxy_seek
GetVideoInfo       : vizbee_app_proxy_get_video_info
OnEvent            : vizbee_app_proxy_on_event
deferredVideoID    : ""
deferredVideoTime  : ""
deferredVideoUrl   : ""
deferredStart      : false
syncController     : vizbee_sync_controller()
rrController      : vizbee_rr_controller()
rrConfigHelper    : vizbee_rr_config_helper()
}
vizbee_log("INFO", "session id: " + this.syncController.comm.sessionid)
this.syncController.SetAppProxy(this)
return this
end function
function vizbee_app_proxy_start_video(videoinfo) as Boolean
m.syncController.state.lastVideoIDFromSync = videoinfo.guid
breakWaitLoop = false
isHome = false
if m.adapter.gotoHome <> invalid and type(m.adapter.gotoHome) = "roFunction"
vizbee_log("INFO", "navigating to home via adapter.gotoHome()")
m.adapter.gotoHome()
isHome = true
end if
if ((not VZB().deferredStartEnabled) or (isHome or (m.currState = "SCREEN" AND m.firstScreenSet AND m.currScreen = m.firstScreen)))
vizbee_log("INFO", "set video guid from start_video: " + videoinfo.guid)
videoState = {
state : "unknown"
id : "unknown"
isLive : false
enableTrickPlay : true
posms : -1
durms : -1
customStreamInfo: invalid
customMetadata: invalid
}
videoState.state = "SELECTED"
videoState.id = videoinfo.guid
videoState.isLive = videoinfo.isLive
videoState.title = videoinfo.title
videoState.subtitle = videoinfo.subtitle
videoState.imgurl = videoinfo.imgurl
videoState.customStreamInfo = videoinfo.customStreamInfo
videoState.customMetadata = videoinfo.customMetadata
m.syncController.state.UpdateVideo(videoState)
m.rrController.send("wakeup")
vizbee_log("INFO", "Start video " + videoinfo.guid + " time: " + StrI(videoinfo.startTime))
m.adapter.startVideo(videoinfo)
breakWaitLoop = false
else
vizbee_log("INFO", "Setting guid for deferred launch " + videoinfo.guid)
m.deferredVideoID = videoinfo.guid
m.deferredVideoTime = videoinfo.startTime
m.deferredVideoUrl = videoinfo.url
m.deferredStart = true
breakWaitLoop = true
end if
return breakWaitLoop
end function
function vizbee_app_proxy_pause_video(player=invalid) as Boolean
playerToUse = player
if (invalid = playerToUse)
playerToUse = m.syncController.state.player
end if
if m.adapter.pauseVideo <> invalid and type(m.adapter.pauseVideo) = "roFunction"
vizbee_log("INFO", "Calling pause with adapter method ...")
m.adapter.pauseVideo(playerToUse)
return true
end if
if m.rrConfigHelper.isRREnabled()
vizbee_log("INFO", "Calling pause with RR ...")
m.rrController.send("pause")
return true        
end if
if type(playerToUse) = "roSGNode"
vizbee_log("INFO", "Calling pause on SG video node ...")
playerToUse.control = "pause"
return true
end if
return false
end function
function vizbee_app_proxy_play_video(player=invalid) as Boolean
playerToUse = player
if (invalid = playerToUse)
playerToUse = m.syncController.state.player
end if
if m.adapter.playVideo <> invalid and type(m.adapter.playVideo) = "roFunction"
vizbee_log("INFO", "Calling play with adapter method ...")
m.adapter.playVideo(playerToUse)
return true
end if
if m.rrConfigHelper.isRREnabled()
vizbee_log("INFO", "Calling play with RR ...")
m.rrController.send("play")
return true        
end if
if type(playerToUse) = "roSGNode"
vizbee_log("INFO", "Calling resume on SG video node ...")
playerToUse.control = "resume"
return true
end if
return false
end function
function vizbee_app_proxy_stop_video(player=invalid, reason="stop_reason_unknown") as Boolean
playerToUse = player
if (invalid = playerToUse)
playerToUse = m.syncController.state.player
end if
if m.adapter.stopVideo <> invalid and type(m.adapter.stopVideo) = "roFunction"
vizbee_log("INFO", "Calling stop with adapter method ...")
m.adapter.stopVideo(playerToUse, reason)
return true
end if
if m.rrConfigHelper.isRREnabled()
vizbee_log("INFO", "Calling stop with RR back ...")
m.rrController.send("back")
return true
end if
if type(playerToUse) = "roSGNode"
vizbee_log("INFO", "Calling stop on SG video node ...")
playerToUse.control = "stop"
return true
end if
return false
end function
function vizbee_app_proxy_seek(offsetMs, player=invalid) as Boolean
if m.adapter.seekVideoSegment <> invalid and type(m.adapter.seekVideoSegment) = "roFunction"
m.adapter.seekVideoSegment(offsetMs)
return true
end if
playerToUse = player
if (invalid = playerToUse)
playerToUse = m.syncController.state.player
if (invalid = playerToUse)
return false
end if
end if
if type(playerToUse) = "roSGNode" then
vizbee_log("INFO", "Using seek on SG video node ...")
playerToUse.seek = offsetMs/1000
else
playerToUse.Seek(offsetMs)
end if
return true
end function
function vizbee_app_proxy_get_video_info(sgvideonode as Object) as Object
if m.adapter.GetVideoInfo <> invalid and type(m.adapter.GetVideoInfo) = "roFunction"
vizbee_log("VERB", "VizbeeAppProxy::getVideoInfo - calling adapter method")
videoInfo = m.adapter.GetVideoInfo(sgvideonode)
if videoInfo = invalid
vizbee_log("WARN", "VizbeeAppProxy::getVideoInfo - got invalid videoInfo from adapter")
else
vizbee_log("VERB", "VizbeeAppProxy::getVideoInfo - got valid videoInfo from adapter")
if videoInfo.guid = invalid
videoInfo.guid = ""
end if
videoInfo.guid = videoInfo.guid.toStr()
if NOT vizbee_util().isBoolean(videoInfo.isLive)
videoInfo.isLive = false
end if
end if
return videoInfo
end if
if type(sgvideonode) = "roSGNode"
content = sgvideonode.content
if content = invalid
vizbee_log("WARN", "VizbeeAppProxy::getVideoInfo - content is invalid")
return invalid
end if
vizbee_log("VERB", "VizbeeAppProxy::getVideoInfo - building videoInfo using SG video node")
videoInfo = {
guid: ""
isLive : false
}
if content.id <> invalid
videoInfo.guid = content.id.toStr()
end if
if content.live = true
videoInfo.isLive = true
end if
videoInfo.title = content.title
videoInfo.subtitle = content.subtitle
videoInfo.imgurl = vizbee_content_util().GetPosterURL(content)
return videoInfo
end if
vizbee_log("WARN", "VizbeeAppProxy::getVideoInfo - content is invalid")
return invalid
end function
function vizbee_app_proxy_on_event(einfo = invalid) as Boolean
if m.adapter.onEvent <> invalid and type(m.adapter.onEvent) = "roFunction" and einfo <> invalid
m.adapter.onEvent(einfo)
end if
return true
end function
function vizbee_app_proxy_update_state_for_RAF_ad(ad)
m.syncController.comm.pubnub.CheckPubRequests()
if (m.currState <> "AD" OR m.currAd <> ad) then
m.syncController.HandleAppEvent("SESSION_UPDATE", "AD", ad)
m.currState = "AD"
m.currAd = ad
m.currScreen = ""
m.currVideo = ""
end if
end function
function vizbee_app_proxy_update_state_and_port(state, screen, video, ad, port, isFirstScreen)
m.syncController.comm.pubnub.CheckPubRequests()
if (state = "SCREEN")
if (m.currState = "SCREEN" AND m.currScreen = screen)
portChanged = false
else
if not m.firstScreenSet AND isFirstScreen
m.firstScreen = screen
m.firstScreenSet = true
end if
if (m.currState = "VIDEO")
if ((m.syncController.state.video.po <> -1) AND ((m.syncController.state.video.po + 5000) > m.syncController.state.video.du))
m.syncController.HandleVideoEvent("FINISHED")
else
vizbee_log("INFO", "from VIDEO to SCREEN -> INTERRUPTED")
m.syncController.HandleVideoEvent("INTERRUPTED")
end if
end if
m.syncController.HandleAppEvent("SESSION_UPDATE", "APP", "")
m.currState = "SCREEN"
m.currScreen = screen
m.currPort = port
m.currVideo = ""
m.currAd = ""
vizbee_log("INFO", "Changing to SCREEN port")
portChanged = true
end if
else if (state = "AD")
if (m.currState = "AD" AND m.currAd = ad)
portChanged = false
else
m.syncController.HandleAppEvent("SESSION_UPDATE", "AD", ad)
m.currState = "AD"
m.currAd = ad
m.currPort = port
m.currScreen = ""
m.currVideo = ""
vizbee_log("INFO", "Changing to AD port")
portChanged = true
end if
else if (state = "VIDEO")
if (m.currState = "VIDEO" AND m.currVideo = video)
portChanged = false
else
m.syncController.HandleAppEvent("SESSION_UPDATE", "VIDEO", video)
m.currState = "VIDEO"
m.currVideo = video
m.currPort = port
m.currScreen = ""
m.currAd = ""
vizbee_log("INFO", "Changing to VIDEO port")
portChanged = true
end if
end if
if (portChanged)
vizbee_log("INFO", "Vizbee state tracking: currState=" + m.currState + " firstScreen=" + m.firstScreen + " currScreen=" + m.currScreen)
end if
m.syncController.HandleAppEvent("PORT_UPDATE", portChanged, m.currPort)
end function
function vizbee_app_proxy_is_first_screen(screen) as Boolean
if m.firstScreenSet
if screen = m.firstScreen
return true
end if
end if
return false
end function

function vizbee_config()
this = {
Get                     : vizbee_config_get
CheckForConfigResponse  : vizbee_config_check_for_config_response
isActive                : false
properties              : invalid
HandleConfigResponse    : vizbee_config_handle_config_response
GetURL                  : vizbee_config_get_url
AddSDKVersion           : vizbee_config_add_sdk_version
AddAppInfo              : vizbee_config_add_app_info
AddDeviceInfo           : vizbee_config_add_device_info
EnrichSyncInfo          : vizbee_config_enrich_sync_info
Activate                : vizbee_config_activate
PostProcess             : vizbee_config_post_process
configRequest       : invalid
configPortId        : ""
configCallback      : invalid
appID               : invalid
}
return this
end function
function vizbee_config_get(appID as String, isProduction = true, async = false, port = invalid, callback = invalid) as Dynamic
m.appID = appID
url = m.GetURL(appID, isProduction)
request = CreateObject("roUrlTransfer")
request.SetUrl(url)
if ((async) AND (port <> invalid) AND (callback <> invalid))
vizbee_log("INFO", "Getting config asynchronously ...")
m.configCallback = callback
m.configRequest = vizbee_util().apiRequest(request)
m.configRequest.SetPort(port)
timeout = 10
m.configRequest.SetMinimumTransferRate(1,timeout)
m.configRequest.AsyncGetToString()
return {}
else
timeout = 10000
response = vizbee_util().apiGet(request, timeout)
apiconfig =  m.HandleConfigResponse(response)
apideviceconfig = m.PostProcess(apiconfig)
return apideviceconfig
end if
end function
function vizbee_config_handle_config_response(response)
error = (response = invalid) OR (response.data = invalid)
error = error OR (response.data.items = invalid) OR (response.data.items[0] = invalid)
error = error OR (response.error <> invalid)
error = error OR (response.data.items[0].channelKeys = invalid) OR (response.data.items[0].channelKeys.pub_key = invalid) OR (response.data.items[0].channelKeys.sub_key = invalid)
if (error AND (response <> invalid) AND (response.error <> invalid))
vizbee_util().storeClear("config", vizbee_constants().REGISTRY_SECTION.CONFIG)
vizbee_log("PROD", "Config disabled. Stopping initialization." + response.error.message)
return invalid
end if
if (error)
vizbee_log("PROD", "AppConfig fetch error, using cached config (if any).")
return vizbee_util().configGet()
end if
appconfig = response.data.items[0]
if (response.externalIpAddress <> invalid)
appconfig.externalIpAddress = response.externalIpAddress
end if
vizbee_util().storeSet("config", FormatJson(appconfig), vizbee_constants().REGISTRY_SECTION.CONFIG)
vizbee_log("INFO", "Saving config", appconfig)
return appconfig
end function
function vizbee_config_check_for_config_response(msg, port, state, id = "")
if (m.configRequest = invalid) then return false
vizbee_log("INFO", "Checking msg for async config response")
newportid = state + id
if (newportid <> m.configPortId)
m.configPortId = newportid
m.configRequest.SetMessagePort(port)
vizbee_log("INFO", "reset configRequest MessagePort. " + newportid)
end if
if (msg.GetSourceIdentity() <> m.configRequest.GetIdentity()) then return false
vizbee_log("INFO", "Got response from async config request")
m.configRequest.AsyncCancel()
m.configRequest = invalid
response = invalid
if (msg.GetResponseCode() <> 500)
response = msg.GetString()
end if
if (response = "")
response = invalid
end if
if (response <> invalid)
response = ParseJSON(response)
end if
apiconfig = m.HandleConfigResponse(response)
apideviceconfig = m.PostProcess(apiconfig)
if (m.configCallback <> invalid)
m.configCallback()
m.configCallback = invalid
end if
return apideviceconfig
end function
function vizbee_config_get_url(appID as String, isProduction = true) as Dynamic
productionURL = "https://config.claspws.tv/api/v2/"
stagingURL = "https://staging-config.claspws.tv/api/v2/"
if (isProduction)
url = productionURL
else
url = stagingURL
end if
url = url + "apps/" + appID
url = url + "/screen/roku"
url = url + "?seed=" + Rnd(10000).ToStr()
vizbee_log("INFO", "App config URL: " + url)
return url
end function
function vizbee_config_add_sdk_version(config) as Dynamic
if (config = invalid) then return invalid
config.sdkVersion = "4.5.9"
return config
end function
function vizbee_config_add_app_info(config) as Dynamic
if (config = invalid) then return invalid
config.appLaunchTime = vizbee_metrics_utils().getCurrentTimestamp()
config.appID = m.appID
return config
end function
function vizbee_config_add_device_info(apiconfig) as Dynamic
if (apiconfig = invalid) then return invalid
config = apiconfig
di = CreateObject("roDeviceInfo")
osVersion = di.GetOSVersion()
config.deviceID                         = "roku:" + di.GetRIDA()
config.idfv                             = LCase(di.GetChannelClientId())
config.serialNumber                     = invalid
config.friendlyName                     = di.GetFriendlyName()
config.macAddress                       = "unknown"
vizbeeRokuUtil                          = vizbee_roku_util_constructor()
config.deviceOSVersion                  = vizbeeRokuUtil.GetRokuOSVersion()
config.connectionType                   = vizbeeRokuUtil.GetRokuConnectionType()
config.internalIpAddress                = vizbeeRokuUtil.GetRokuInternalIPAddress()
config.ipv6AddressesFromPlatform        = vizbeeRokuUtil.GetRokuIPv6AddressesFromPlatform()
config.ipv6AddressFromIPService         = vizbeeRokuUtil.GetRokuIPV6AddressFromIPService()
config.ssid                             = vizbeeRokuUtil.GetRokuSSID()
config.adID                             = di.GetRIDA()
config.limitAdTracking                  = di.IsRIDADisabled()
config.deviceModelName                  = di.GetModel()
config.deviceModelDisplayName           = di.GetModelDisplayName()
config.deviceModelType                  = di.GetModelType()
return config
end function
function vizbee_config_enrich_sync_info(config) as Dynamic
if (config = invalid) then return invalid
if (config.syncInfo = invalid) then
config.syncInfo = vizbee_config_get_default_sync_info()
end if
channelInfo = config.syncInfo.channel
if(channelInfo <> invalid AND channelInfo.type <> invalid AND LCase(channelInfo.type) = "pubnub" AND channelInfo.options <> invalid AND channelInfo.options.id <> invalid) then
deviceID = LCase(channelInfo.options.id)
if (config.serialNumber <> invalid AND vizbee_config_check_key_exists_in_device_id(deviceID, "serial_number")) then deviceID = deviceID.Replace("serial_number", config.serialNumber)
if (config.externalIpAddress <> invalid AND vizbee_config_check_key_exists_in_device_id(deviceID, "ext_ip")) then deviceID = deviceID.Replace("ext_ip", config.externalIpAddress)
if (config.internalIpAddress <> invalid AND vizbee_config_check_key_exists_in_device_id(deviceID, "int_ip")) then deviceID = deviceID.Replace("int_ip", config.internalIpAddress)
if (config.friendlyName <> invalid AND vizbee_config_check_key_exists_in_device_id(deviceID, "friendly_name")) then deviceID = deviceID.Replace("friendly_name", config.friendlyName)
if (config.macAddress <> invalid AND vizbee_config_check_key_exists_in_device_id(deviceID, "mac_address")) then deviceID = deviceID.Replace("mac_address", config.macAddress)
if (config.adID <> invalid AND vizbee_config_check_key_exists_in_device_id(deviceID, "idfa")) then deviceID = deviceID.Replace("idfa", config.adID)
config.syncInfo.channel.options.id = deviceID
end if
return config
end function
function vizbee_config_get_default_sync_info() as Dynamic
defaultSyncInfo = {
channel: {
type: "pubnub"
options: {
id: "ext_ip:int_ip"
}
}
}
return defaultSyncInfo
end function
function vizbee_config_check_key_exists_in_device_id(deviceID, key) as Boolean
return vizbee_util().contains(deviceID.Split(":"), key)
end function
function vizbee_config_activate(apideviceconfig)
if (apideviceconfig =invalid) then
GetGlobalAA().AddReplace("VizbeeStatus", "INACTIVE")
return invalid
end if
GetGlobalAA().AddReplace("VizbeeConfig", apideviceconfig)
GetGlobalAA().AddReplace("VizbeeStatus", "ACTIVE")
m.isActive = true
m.properties = apideviceconfig
vizbee_log("INFO", "Config received, making Vizbee ACTIVE")
end function
function vizbee_config_post_process(apiconfig) as Dynamic
apiconfig = m.AddSDKVersion(apiconfig)
appinfoconfig = m.AddAppInfo(apiconfig)
apideviceconfig = m.AddDeviceInfo(appinfoconfig)
apisyncconfig = m.EnrichSyncInfo(apideviceconfig)
m.Activate(apisyncconfig)
return apisyncconfig
end function
'********************************************************************
'**  Vizbee Constants
'********************************************************************
function vizbee_constants()
this = {
REGISTRY_SECTION: {
CONFIG: "VizbeeConfig"
IDS: "VizbeeIds"
}
}
return this
end function
'********************************************************************
'**  Vizbee Elapsed Playtime Tracker
'********************************************************************
function vizbee_elapsed_playtime_tracker()
this = {
reset           :  vizbee_elapsed_playtime_tracker_reset
setPlaying      :  vizbee_elapsed_playtime_tracker_set_playing
setNotPlaying   :  vizbee_elapsed_playtime_tracker_set_not_playing
elapsedPlayTime :  0
isPlaying       :  false
lastUpdateTime  :  CreateObject("roTimespan")
}
return this
end function
function vizbee_elapsed_playtime_tracker_reset()
m.isPlaying = false
m.elapsedPlayTime = 0
m.lastUpdateTime.mark()
end function
function vizbee_elapsed_playtime_tracker_set_playing()
if (m.isPlaying = true)
m.elapsedPlayTime = m.elapsedPlayTime + m.lastUpdateTime.TotalMilliseconds()
end if
m.isPlaying = true
m.lastUpdateTime.mark()
end function
function vizbee_elapsed_playtime_tracker_set_not_playing()
m.isPlaying = false
m.lastUpdateTime.mark()
end function

function vizbee_on_event_info(eventInfo as dynamic) as boolean
if eventInfo = invalid
vizbee_log("WARN", "VizbeeEventHandler::vizbee_on_event_info - MISSING eventInfo")
return false
end if
if(m.appProxy = invalid) then
vizbee_log("WARN", "VizbeeEventHandler::vizbee_on_event_info - INVALID appProxy")
return false
end if
if(m.appProxy.syncController = invalid) then
vizbee_log("WARN", "VizbeeEventHandler::vizbee_on_event_info - INVALID syncController")
return false
end if
vizbee_log("INFO", "VizbeeEventHandler::vizbee_on_event_info sending event to sync controller", eventInfo)
return m.appProxy.syncController.HandleOnEvent(eventInfo)
end function
'********************************************************************
'**  Vizbee Options
'********************************************************************
function vizbee_options()
this = {
SetProduction       : vizbee_options_set_production
SetStaging          : vizbee_options_set_staging
SetLaunchParameters : vizbee_options_set_launch_parameters
SetCustomAttributesForMetrics : vizbee_options_set_custom_attributes_for_metrics
isProduction        : true
launchParameters    : invalid
customAttributes    : invalid
}
return this
end function
function vizbee_options_set_production() as Dynamic
m.isProduction = true
return m
end function
function vizbee_options_set_staging() as Dynamic
m.isProduction = false
return m
end function
function vizbee_options_set_launch_parameters(args=invalid as Object) as Dynamic
m.launchParameters = args
return m
end function
function vizbee_options_set_custom_attributes_for_metrics(attrs=invalid as Object) as Dynamic
m.customAttributes = attrs
return m
end function

function vizbee_presence_extension()
vizbee_sync_comm = vizbee_sync_comm_manager()
vizbee_sync_comm.shouldForwardHeaders = true
vizbee_presence_map = CreateObject("roAssociativeArray")
vizbee_presence_timer = CreateObject("roTimespan")
return {
comm                : vizbee_sync_comm
ResetMsgPort        : vizbee_presence_extension_reset_msg_port
RecvMsg             : vizbee_presence_extension_recv_msg
SendMsg             : vizbee_presence_extension_send_msg
sessionid           : vizbee_sync_comm.sessionid
pubnub              : vizbee_sync_comm.pubnub
FILTER_SENDER_TIMEOUT : 1*60*1000
FILTER_SENDER_WARNING1_TIMEOUT : 1*40*1000
FILTER_SENDER_WARNING2_TIMEOUT : 1*50*1000
enableFilter               : true
sentFirstHelloWarning      : false
sentSecondHelloWarning     : false
senderMap           : vizbee_presence_map
timer               : vizbee_presence_timer
shouldSendWarningMessage : vizbee_presence_extension_should_send_warning_message
sendWarningMessage  : vizbee_presence_extension_send_warning_message
removeOldSenders    : vizbee_presence_extension_remove_old_senders
}
end function
function vizbee_presence_extension_reset_msg_port(port)
m.comm.ResetMsgPort(port)
end function
function vizbee_presence_extension_recv_msg(msg)
messages = m.comm.RecvMsgBody(msg)
if (messages = invalid) return messages
bodies = []
for i = 0 to (messages.count() - 1)
message = messages[i]
m.sentFirstHelloWarning = false
m.sentSecondHelloWarning = false
if (m.senderMap.DoesExist(message.h.id)) then
timer = m.senderMap[message.h.id]
else
timer = CreateObject("roTimespan")
end if
timer.mark()
m.senderMap[message.h.id] = timer
bodies.push(message)
end for
return bodies
end function
function vizbee_presence_extension_send_msg(body, sendFlag)
if (NOT m.enableFilter) then
m.comm.SendMsg(body, sendFlag)
return true
end if
if (NOT (body.cmd.name = "status")) then
m.comm.SendMsg(body, sendFlag)
return true
end if
if ((body.vstatus.st = "INTERRUPTED") OR (body.vstatus.st = "FAILED") OR (body.vstatus.st = "FINISHED")) then
m.comm.SendMsg(body, sendFlag)
return true
end if
if ((NOT m.sentFirstHelloWarning) AND m.shouldSendWarningMessage(m.FILTER_SENDER_WARNING1_TIMEOUT)) then
vizbee_log("VERB", "FILTER-WARNING: Sending hello message as warning1")
m.sendWarningMessage()
m.sentFirstHelloWarning = true
else if ((NOT m.sentSecondHelloWarning) AND m.shouldSendWarningMessage(m.FILTER_SENDER_WARNING2_TIMEOUT)) then
vizbee_log("VERB", "FILTER-WARNING: Sending hello message as warning2")
m.sendWarningMessage()
m.sentSecondHelloWarning = true
end if
m.removeOldSenders(m.FILTER_SENDER_TIMEOUT)
if (m.senderMap.Count() > 0) then
m.comm.SendMsg(body, sendFlag)
else
vizbee_log("VERB", "WARNING >>> filtering status message")
end if
end function
function vizbee_presence_extension_remove_old_senders(filterTime)
vizbee_log("VERB", "-----SENDERS MAP-----")
for each key in m.senderMap
timer = m.senderMap[key]
vizbee_log("VERB", "Sender:" + key + " time:" + StrI(timer.TotalMilliseconds()))
if timer.TotalMilliseconds() > filterTime then
m.senderMap.Delete(key)
end if
end for
vizbee_log("VERB", "-----SENDERS MAP-----")
end function
function vizbee_presence_extension_should_send_warning_message(filterTime)
for each key in m.senderMap
timer = m.senderMap[key]
if timer.TotalMilliseconds() > filterTime then
return true
end if
end for
return false
end function
function vizbee_presence_extension_send_warning_message()
vzbSDKInstance = VZB()
vzbSDKInstance.appProxy.syncController.SendHelloWithType("req")
end function

Function VizbeeIsXmlElement(value As Dynamic) As Boolean
Return VizbeeIsValid(value) And GetInterface(value, "ifXMLElement") <> invalid
End Function
Function VizbeeIsFunction(value As Dynamic) As Boolean
Return VizbeeIsValid(value) And GetInterface(value, "ifFunction") <> invalid
End Function
Function VizbeeIsBoolean(value As Dynamic) As Boolean
Return VizbeeIsValid(value) And GetInterface(value, "ifBoolean") <> invalid
End Function
Function VizbeeIsInteger(value As Dynamic) As Boolean
Return VizbeeIsValid(value) And GetInterface(value, "ifInt") <> invalid And (Type(value) = "roInt" Or Type(value) = "roInteger" Or Type(value) = "Integer")
End Function
Function VizbeeIsFloat(value As Dynamic) As Boolean
Return VizbeeIsValid(value) And (GetInterface(value, "ifFloat") <> invalid Or (Type(value) = "roFloat" Or Type(value) = "Float"))
End Function
Function VizbeeIsDouble(value As Dynamic) As Boolean
Return VizbeeIsValid(value) And (GetInterface(value, "ifDouble") <> invalid Or (Type(value) = "roDouble" Or Type(value) = "roIntrinsicDouble" Or Type(value) = "Double"))
End Function
Function VizbeeIsList(value As Dynamic) As Boolean
Return VizbeeIsValid(value) And GetInterface(value, "ifList") <> invalid
End Function
Function VizbeeIsArray(value As Dynamic) As Boolean
Return VizbeeIsValid(value) And GetInterface(value, "ifArray") <> invalid
End Function
Function VizbeeIsAssociativeArray(value As Dynamic) As Boolean
Return VizbeeIsValid(value) And GetInterface(value, "ifAssociativeArray") <> invalid
End Function
Function VizbeeIsString(value As Dynamic) As Boolean
Return VizbeeIsValid(value) And GetInterface(value, "ifString") <> invalid
End Function
Function VizbeeIsDateTime(value As Dynamic) As Boolean
Return VizbeeIsValid(value) And (GetInterface(value, "ifDateTime") <> invalid Or Type(value) = "roDateTime")
End Function
Function VizbeeIsValid(value As Dynamic) As Boolean
Return Type(value) <> "<uninitialized>" And value <> invalid
End Function

'********************************************************************
'**  Vizbee Video Update Filter
'********************************************************************
function vizbee_video_update_filter(config)
gapInMilliseconds = 2 * 60 * 1000 
if (config <> invalid) AND (config.properties <> invalid) AND (config.properties.metricsParams <> invalid)
screenDurationFrequencyInMins = config.properties.metricsParams.screenDurationFrequencyInMins
if screenDurationFrequencyInMins <> invalid AND screenDurationFrequencyInMins >= 1
gapInMilliseconds = screenDurationFrequencyInMins * 60 * 1000
end if
end if
this = {
lastVideoID             : invalid
lastVideoUpdateSendTime : invalid
update  : vizbee_video_update_filter_update
gap     : gapInMilliseconds
}
return this
end function
function vizbee_video_update_filter_update(videoID)
update = false
if ((m.lastVideoID = invalid) OR (m.lastVideoID <> videoID))
update = true
m.lastVideoID = videoID
end if
if (m.lastVideoUpdateSendTime = invalid)
update = true
m.lastVideoUpdateSendTime = CreateObject("roTimeSpan")
end if
if (update)
m.lastVideoUpdateSendTime.mark()
return true
end if
if (m.lastVideoUpdateSendTime.TotalMilliSeconds() > m.gap)
m.lastVideoUpdateSendTime.mark()
return true
end if
return false
end function

'********************************************************************
'**  Vizbee Metrics
'********************************************************************
function vizbee_metrics(globalconfig, globaloptions) as object
return {
trackScreenLaunched : vizbee_metrics_track_screen_launched
trackScreenSignIn : vizbee_metrics_track_screen_signin
trackScreenViewStart : vizbee_metrics_track_screen_view_start
trackScreenViewDuration : vizbee_metrics_track_screen_view_duration
trackScreenAdView : vizbee_metrics_track_screen_ad_view
logEvent : vizbee_metrics_log_event
setCommonProperties : vizbee_metrics_set_common_properties
getRemoteCustomAttributes : vizbee_metrics_get_remote_custom_attributes
addRemoteCustomAttributes : vizbee_metrics_add_remote_custom_attributes
shouldSend : vizbee_metrics_should_send
config : globalconfig
options : globaloptions
router : vizbee_metrics_router()
videoUpdateFilter : vizbee_video_update_filter(globalconfig)
}
end function
function vizbee_metrics_set_common_properties() as dynamic
if (m.config <> invalid) and (m.config.properties <> invalid) then
message = {}
message.properties = {}
configProperties = m.config.properties
deviceId = vizbee_metrics_get_device_id(configProperties)
screenSdkId = vizbee_metrics_get_screen_sdk_id()
messageProperties = {
distinct_id: deviceId
SCREEN_DEVICE_ID: deviceId
APP_ID: configProperties.appID
SCREEN_SDK_VERSION: configProperties.sdkVersion
SCREEN_DEVICE_TYPE: "ROKU"
SCREEN_NATIVE_OS_VERSION: configProperties.deviceOSVersion
SCREEN_FRIENDLY_NAME: configProperties.friendlyName
SCREEN_DEVICE_MODEL: configProperties.deviceModelName
SCREEN_DEVICE_MODEL_DISPLAY_NAME: configProperties.deviceModelDisplayName
SCREEN_DEVICE_MODEL_TYPE: configProperties.deviceModelType
SCREEN_IDFV: configProperties.idfv
SCREEN_IDFA: configProperties.adID
SCREEN_LIMIT_AD_TRACKING: configProperties.limitAdTracking
SCREEN_MAC_ADDRESS: configProperties.macAddress
SCREEN_SERIAL_NUMBER: configProperties.serialNumber
SCREEN_SDK_ID: screenSdkId
WIFI_SSID: configProperties.ssid
EXTERNAL_IP_ADDRESS: configProperties.externalIpAddress
INTERNAL_IP_ADDRESS: configProperties.internalIpAddress
SCREEN_IPV6_ADDRESSES: configProperties.ipv6AddressesFromPlatform
}
if configProperties.ipv6AddressFromIPService <> ""
messageProperties.IPV6_ADDRESS = configProperties.ipv6AddressFromIPService
end if
connectionType = configProperties.connectionType
inferredConnectionType = connectionType
if (connectionType = "") then
inferredConnectionType = "UNKNOWN"
else if (connectionType = "WiFiConnection") then
inferredConnectionType = "WIFI"
else if (connectionType = "WiredConnection") then
inferredConnectionType = "WIRED"
end if
messageProperties.CONNECTION_TYPE = inferredConnectionType
messageProperties.TIMEZONE = vizbee_metrics_utils().getCurrentTimezone()
messageProperties.VZB_TIMESTAMP = vizbee_metrics_utils().getCurrentTimestamp()
messageProperties.SCREEN_APP_FOREGROUND_TIME = configProperties.appLaunchTime
messageProperties.SCREEN_APP_SESSION_ID = messageProperties.APP_ID + ":" + messageProperties.SCREEN_IDFV + ":" + messageProperties.SCREEN_APP_FOREGROUND_TIME
messageProperties.SCREEN_LAUNCHED_WITH_VIZBEE = VZB().isLaunchedWithVizbee
messageProperties.SCREEN_VZB_LAUNCH_SERVICE_TYPE = VZB().vizbeeLaunchServiceType
messageProperties.SCREEN_VZB_LAUNCH_PARAM = "NOT_FOUND"
if(m.options <> invalid and m.options.launchParameters <> invalid)
vzbLaunchParameter = m.options.launchParameters.vzb
if(vzbLaunchParameter <> invalid and vzbLaunchParameter <> "")
messageProperties.SCREEN_VZB_LAUNCH_PARAM = vzbLaunchParameter
end if
end if
if (m.options <> invalid) and (m.options.customAttributes <> invalid) then
for each key in m.options.customAttributes
customKey = "CUSTOM_" + key
messageProperties[customKey] = m.options.customAttributes[key]
end for
end if
message.properties = messageProperties
return message
else
return invalid
end if
end function
function vizbee_metrics_get_remote_custom_attributes(state) as object
remoteCustomAttributes = {}
if state = invalid
return remoteCustomAttributes
end if
if state.customStreamInfo <> invalid
remoteCustomAttributes.customStreamInfo = state.customStreamInfo
end if
if state.customMetadata <> invalid
remoteCustomAttributes.customMetadata = state.customMetadata
end if
return vizbee_util().flattenJSON(remoteCustomAttributes)
end function
function vizbee_metrics_add_remote_custom_attributes(message, state)
shouldAddRemoteCustomAttributes = true
if m.config.properties.metricsParams.shouldAddRemoteCustomAttributes <> invalid
shouldAddRemoteCustomAttributes = m.config.properties.metricsParams.shouldAddRemoteCustomAttributes
end if
if shouldAddRemoteCustomAttributes
message.properties.Append(m.getRemoteCustomAttributes(state))
end if
end function
function vizbee_metrics_get_device_id(configProperties) as string
deviceId = "roku:"
if (configProperties.serialNumber <> "" and configProperties.serialNumber <> invalid) then
deviceId += ("serial:" + LCase(configProperties.serialNumber))
else if ((not configProperties.limitAdTracking) and configProperties.adID <> "" and configProperties.adID <> invalid) then
deviceId += ("idfa:" + LCase(configProperties.adID))
else if (configProperties.idfv <> "" and configProperties.idfv <> invalid) then
deviceId += ("idfv:" + LCase(configProperties.idfv))
end if
return deviceId
end function
function vizbee_metrics_get_screen_sdk_id() as string
screenSdkId = vizbee_util().storeGet("screenSdkId", vizbee_constants().REGISTRY_SECTION.IDS)
if(screenSdkId = invalid)
di = CreateObject("roDeviceInfo")
screenSdkId = di.GetRandomUUID()
vizbee_util().storeSet("screenSdkId", screenSdkId, vizbee_constants().REGISTRY_SECTION.IDS)
end if
return screenSdkId
end function
function vizbee_metrics_should_send(message) as boolean
shouldSend = true
if (m.config <> invalid) and (m.config.properties <> invalid) and (m.config.properties.metricsParams <> invalid) then
if (m.config.properties.metricsParams.shouldSendViewEventsOnlyOnCast = true) then
if (not message.properties.IS_VIDEO_LAUNCHED_FROM_PHONE) then
shouldSend = false
end if
end if
end if
return shouldSend
end function
function vizbee_metrics_track_screen_launched() as boolean
message = m.setCommonProperties()
if (message = invalid)
return false
end if
message.event = "SCREEN_LAUNCHED"
ret = m.router.send(message)
return ret
end function
function vizbee_metrics_track_screen_signin(authInfo) as boolean
message = m.setCommonProperties()
if (message = invalid)
return false
end if
if authInfo = invalid
authInfo = {}
end if
message.event = "SCREEN_TV_SIGNIN"
messageProperties = message.properties
messageProperties.USER_ID = authInfo.userId
messageProperties.USER_LOGIN = authInfo.userLogin
messageProperties.USER_LOGIN_TYPE = authInfo.userLoginType
message.properties = messageProperties
ret = m.router.send(message)
return ret
end function
function vizbee_metrics_track_screen_view_start(state) as boolean
message = m.setCommonProperties()
if (message = invalid)
return false
end if
message.event = "SCREEN_TV_VIEW_START"
if ((state = invalid) or (state.video = invalid) or (state.video.id = invalid) or (state.video.ss = invalid))
return false
end if
messageProperties = message.properties
messageProperties.distinct_id = state.video.ss
messageProperties.VIDEO_ID = state.video.id
messageProperties.VIDEO_TITLE = state.title
messageProperties.VIDEO_SUBTITLE = state.subtitle
messageProperties.IS_LIVE = state.isLive
m.addRemoteCustomAttributes(message, state)
if (state.lastVideoIDFromSync = state.video.id)
messageProperties.IS_VIDEO_LAUNCHED_FROM_PHONE = true
else
messageProperties.IS_VIDEO_LAUNCHED_FROM_PHONE = false
end if
messageProperties.VIDEO_DURATION_MS = state.video.du
message.properties = messageProperties
if m.shouldSend(message) then
ret = m.router.send(message)
else
ret = false
end if
return ret
end function
function vizbee_metrics_track_screen_view_duration(state) as boolean
message = m.setCommonProperties()
if (message = invalid)
return false
end if
message.event = "SCREEN_TV_VIEW_DURATION"
if ((state = invalid) or (state.video = invalid) or (state.video.id = invalid) or (state.video.ss = invalid))
return false
end if
update = m.videoUpdateFilter.update(state.video.id)
if (update)
messageProperties = message.properties
messageProperties.distinct_id = state.video.ss
messageProperties.VIDEO_ID = state.video.id
messageProperties.VIDEO_TITLE = state.title
messageProperties.VIDEO_SUBTITLE = state.subtitle
messageProperties.IS_LIVE = state.isLive
message.properties = messageProperties
m.addRemoteCustomAttributes(message, state)
if (state.lastVideoIDFromSync = state.video.id)
messageProperties.IS_VIDEO_LAUNCHED_FROM_PHONE = true
else
messageProperties.IS_VIDEO_LAUNCHED_FROM_PHONE = false
end if
messageProperties.VIDEO_DURATION_MS = state.video.du
messageProperties.VIDEO_POSITION_MS = state.video.po
if (messageProperties.VIDEO_POSITION_MS > 0)
messageProperties.VIDEO_POSITION_MIN = INT(state.video.po / 60000)
else
messageProperties.VIDEO_POSITION_MIN = 0
end if
messageProperties.VIDEO_ELAPSED_TIME_MS = state.elapsedPlayTimeTracker.elapsedPlayTime
if (messageProperties.VIDEO_ELAPSED_TIME_MS > 0)
messageProperties.VIDEO_ELAPSED_TIME_MIN = INT(message.properties.VIDEO_ELAPSED_TIME_MS / 60000)
else
messageProperties.VIDEO_ELAPSED_TIME_MIN = 0
end if
message.properties = messageProperties
if m.shouldSend(message) then
ret = m.router.send(message)
else
ret = false
end if
return ret
end if
return false
end function
function vizbee_metrics_track_screen_ad_view()
message = m.setCommonProperties()
if (message = invalid)
return false
end if
message.event = "SCREEN_AD_VIEW"
if m.shouldSend(message) then
ret = m.router.send(message)
else
ret = false
end if
return ret
end function
function vizbee_metrics_log_event(eventName, eventProperties) as boolean
message = m.setCommonProperties()
if (message = invalid)
return false
end if
if eventName = invalid
return false
end if
if eventProperties = invalid
eventProperties = {}
end if
message.event = eventName
message.properties.Append(eventProperties)
ret = false
if m.shouldSend(message) then
ret = m.router.send(message)
end if
return ret
end function

'********************************************************************
'**  Vizbee Metrics Router
'********************************************************************
function vizbee_metrics_router() as object
config = GetGlobalAA().Lookup("VizbeeConfig")
properties_filter = invalid
if (config <> invalid) AND (config.metricsParams <> invalid)
properties_filter = config.metricsParams.attribute_filter
end if
metrics_senders = {"mixpanel": vizbee_mixpanel_transport(), "vizbee_metrics" : vizbee_metrics_transport()}
return {
send    : vizbee_metrics_router_send
senders : metrics_senders
propertiesFilter: properties_filter
}
end function
function vizbee_metrics_router_send(message) as boolean
if m.propertiesFilter <> invalid and message <> invalid and message.properties <> invalid
message.properties = vizbee_metrics_utils().getFilteredProperties(message.properties, m.propertiesFilter)
end if
ret = true
for each sender in m.senders
didSend = m.senders[sender].send(message)
ret = ret AND didSend
end for
return ret
end function

'********************************************************************
'**  Vizbee Metrics Transport
'********************************************************************
function vizbee_metrics_transport() as object
metrics_init = false
metrics_url = invalid
metrics_filter = invalid
config = GetGlobalAA().Lookup("VizbeeConfig")
if (config <> invalid) AND (config.metricsParams <> invalid)
metrics_init = true
metrics_url = config.metricsParams.vizbee_url
if (invalid <> metrics_url) then
vizbee_log("INFO", "Vizbee metrics url: " + metrics_url)
end if
metrics_filter = config.metricsParams.vizbee_filter
if (invalid = metrics_filter) then
metrics_filter = ".*"
end if
vizbee_log("INFO", "Vizbee metrics filter: " + metrics_filter)
end if
return {
send    : vizbee_metrics_transport_send
url     : metrics_url
filter  : metrics_filter
init    : metrics_init
}
end function
function vizbee_metrics_transport_send(message) as boolean
if (NOT m.init) OR (invalid = m.url) then
return false
end if
shouldSend = true
if (INVALID <> m.filter) then
shouldSend = vizbee_metrics_utils().shouldSend(message, m.filter)
end if
if (NOT shouldSend) then
return false
end if
return vizbee_metrics_utils().sendWithBase64Encoding(message, m.url)
end function

'********************************************************************
'**  Vizbee Metrics Utils
'********************************************************************
function vizbee_metrics_utils() as object
return {
sendWithBase64Encoding : vizbee_metrics_utils_send
shouldSend : vizbee_metrics_utils_should_send
getFilteredProperties: vizbee_metrics_utils_get_filtered_properties
getCurrentTimestamp : vizbee_metrics_utils_get_timestamp
getCurrentTimezone : vizbee_metrics_utils_get_timezone
}
end function
function vizbee_metrics_utils_should_send(message, filter) as boolean
if (type(message) <> "roAssociativeArray")
return false
end if
if (message = invalid) or (message.properties = invalid) or (message.event = invalid) then
vizbee_log("INFO", "MetricsUtils::send - invalid message")
return false
end if
if (invalid = filter) then
return true
end if
regex = CreateObject("roRegex", filter, "i")
if regex.isMatch(message.event) then
return true
else
return false
end if
end function
function vizbee_metrics_utils_send(message, targetURL) as boolean
if (targetURL = invalid) then
return false
end if
if (type(message) <> "roAssociativeArray")
return false
end if
if (message = invalid) or (message.properties = invalid) or (message.event = invalid) then
vizbee_log("INFO", "MetricsUtils::send - invalid message")
return false
end if
jsonStringMessage = FormatJson(message, 0)
ba = CreateObject("roByteArray")
ba.FromAsciiString(jsonStringMessage)
base64Message = ba.ToBase64String()
url = targetURL + "?data=" + base64Message
vizbee_log("INFO", "MetricsUtils::send url=" + url)
request = CreateObject("roUrlTransfer")
port = CreateObject("roMessagePort")
request.SetMessagePort(port)
request.SetCertificatesFile("common:/certs/ca-bundle.crt")
request.InitClientCertificates()
request.SetUrl(url)
ret = request.GetToString()
return true
end function
function vizbee_metrics_utils_get_filtered_properties(properties, filter) as dynamic
if (type(properties) <> "roAssociativeArray")
return false
end if
if (invalid = filter) then
return properties
end if
filteredProperties = {}
regex = CreateObject("roRegex", filter, "i")
for each key in properties
if regex.isMatch(key) then
filteredProperties[key] = properties[key]
end if
end for
return filteredProperties
end function
function vizbee_metrics_utils_get_timestamp() as string
dt = CreateObject ("roDateTime")
ms = dt.AsSeconds().ToStr() + Right("00" + dt.GetMilliseconds().ToStr(), 3)
return ms
end function
function vizbee_metrics_utils_get_timezone() as string
dt = CreateObject ("roDateTime")
timezone = ""
timeOffset = dt.GetTimeZoneOffset()
totalSeconds = timeOffset * 60
if totalSeconds < 0
totalSeconds = totalSeconds * -1
timezone = "GMT+" + formatSecondsToHHMM(totalSeconds)
else
timezone = "GMT-" + formatSecondsToHHMM(totalSeconds)
end if
return timezone
end function
function formatSecondsToHHMM(TotalSeconds = 0 as integer) as string
dt = CreateObject("roDateTime")
dt.FromSeconds(TotalSeconds)
hours = dt.GetHours().ToStr()
minutes = dt.GetMinutes().ToStr()
if Len(hours) = 1
hours = "0" + hours
end if
if Len(minutes) = 1
minutes = "0" + minutes
end if
return hours + ":" + minutes
end function
'********************************************************************
'**  Vizbee Mixpanel Transport
'********************************************************************
function vizbee_mixpanel_transport() as object
mixpanel_init = false
mixpanel_url = invalid
mixpanel_token = invalid
mixpanel_filter = invalid
config = GetGlobalAA().Lookup("VizbeeConfig")
if (config <> invalid) AND (config.metricsParams <> invalid)
mixpanel_init = true
mixpanel_url = config.metricsParams.mixpanel_url
if (invalid <> mixpanel_url) then
vizbee_log("INFO", "Mixpanel url: " + mixpanel_url)
end if
mixpanel_token = config.metricsParams.mixpanel_token
if (invalid <> mixpanel_token) then
vizbee_log("INFO", "Mixpanel token: " + mixpanel_token)
end if
mixpanel_filter = config.metricsParams.mixpanel_filter
if (invalid = mixpanel_filter) then
mixpanel_filter = ".*"
end if
vizbee_log("INFO", "Mixpanel filter: " + mixpanel_filter)
end if
return {
send    : vizbee_mixpanel_transport_send
url     : mixpanel_url
token   : mixpanel_token
filter  : mixpanel_filter
init    : mixpanel_init
}
end function
function vizbee_mixpanel_transport_send(message) as boolean
if (NOT m.init) OR (invalid = m.url) then
return false
end if
shouldSend = true
if (invalid <> m.filter) then
shouldSend = vizbee_metrics_utils().shouldSend(message, m.filter)
end if
if (NOT shouldSend) then
return false
end if
if (type(message) <> "roAssociativeArray")
return false
end if
if (message = invalid) OR (message.properties = invalid) or (message.event = invalid) then
vizbee_log("INFO", "Mixpanel::send - invalid message")
return false
end if
message.properties.token = m.token
return vizbee_metrics_utils().sendWithBase64Encoding(message, m.url)
end function

function vizbee_pubnub()
config = GetGlobalAA().Lookup("VizbeeConfig")
pub_key = "pub-c-1de7d026-c32b-409b-aa5a-519dca7781c0"
sub_key = "sub-c-23d1a802-b377-11e3-bec6-02ee2ddab7fe"
sub_timeout = 310
if (config <> invalid) AND (config.channelKeys <> invalid)
pub_key = config.channelKeys.pub_key
sub_key = config.channelKeys.sub_key
if vizbee_util().isInteger(config.channelKeys.sub_timeout)
sub_timeout = config.channelKeys.sub_timeout
end if
vizbee_log("INFO", "Sync pub key: " + pub_key)
vizbee_log("INFO", "Sync sub key: " + sub_key)
vizbee_log("INFO", "Sync sub timeout: " + sub_timeout.toStr())
end if
channel_id = vizbee_get_channel_id()
subscribe_timer = CreateObject("roTimespan")
subscribe_timer.Mark()
return {
origin          : "https://pubsub.pubnub.com"
pub_key         : pub_key
sub_key         : sub_key
sub_timeout     : sub_timeout
channel         : channel_id
timetoken       : "0"
subURIClient    : invalid
pubRequests     : {}
pubRequestsPort : CreateObject("roMessagePort")
CheckPubRequests: vizbee_check_pub_requests
msgPort         : invalid
isMsgPortSet    : false
ResetMsgPort    : vizbee_pubnub_reset_msg_port
subscribeTimer  : subscribe_timer
isSubscribed    : false
Publish         : vizbee_pubnub_publish
Subscribe       : vizbee_pubnub_subscribe
IsMyResponse    : vizbee_pubnub_is_my_response
ParseResponse   : vizbee_pubnub_parse_response
}
end function
function vizbee_get_channel_id() as String
ba = CreateObject("roByteArray")
config = GetGlobalAA().Lookup("VizbeeConfig")
if (config = invalid) then return ""
appID          = config.appID
deviceID       = vizbee_get_device_id_for_channel(config)
channelFormula = LCase(appID + ":roku:" + deviceID)
ba.fromAsciiString(channelFormula)
digest = CreateObject("roEVPDigest")
digest.Setup("md5")
channel_id = LCase(digest.Process(ba))
vizbee_log("PROD", "Sync channel: " + channel_id)
return channel_id
end function
function vizbee_get_device_id_for_channel(config) as String
if (config = invalid) then return ""
syncInfo = config.syncInfo
deviceID = LCase(config.externalIpAddress + ":" + config.internalIpAddress)
if (syncInfo <> invalid AND syncInfo.channel <> invalid AND syncInfo.channel.type <> invalid AND LCase(syncInfo.channel.type) = "pubnub")
deviceID = syncInfo.channel.options.id
end if
return deviceID
end function
function vizbee_pubnub_reset_msg_port(port)
if m.subURIClient <> invalid
m.subURIClient.AsyncCancel()
end if
m.subURIClient = CreateObject("roUrlTransfer")
m.subURIClient.SetMessagePort(port)
m.subURIClient.SetCertificatesFile("common:/certs/ca-bundle.crt")
m.subURIClient.InitClientCertificates()
m.subURIClient.SetMinimumTransferRate(1,m.sub_timeout)
m.msgPort = port
m.isMsgPortSet = true
m.isSubscribed = false
m.Subscribe()
end function
function vizbee_pubnub_publish(message)
if not m.isMsgPortSet
vizbee_log("ERROR", "Calling publish without setting msgPort!")
return false
end if
request = CreateObject("roUrlTransfer")
request.SetMessagePort(m.pubRequestsPort)
request.SetCertificatesFile("common:/certs/ca-bundle.crt")
request.InitClientCertificates()
params = request.Escape(FormatJson(message,0))
config = GetGlobalAA().Lookup("VizbeeConfig")
if (type(config) <> "<uninitialized>") then
meta = "%7B%22uuid%22%3A%22" + m.subURIClient.Escape(config.deviceID) + "%22%7D"
uuid = m.subURIClient.Escape(config.deviceID)
url = m.origin + "/publish/" + m.pub_key + "/" + m.sub_key + "/0/" + m.channel + "/0/" + params + "?uuid=" + uuid + "&meta=" + meta
else
url = m.origin + "/publish/" + m.pub_key + "/" + m.sub_key + "/0/" + m.channel + "/0/" + params
end if
vizbee_log("VERB", "VizbeePubnub::publish url=" + url)
request.SetUrl(url)
ret = request.AsyncGetToString()
if NOT ret
vizbee_log("ERROR", "Pubnub publish FAILED!")
vizbee_log("ERROR", m.pubURIClient.GetFailureReason())
return invalid
end if
id = request.GetIdentity()
m.pubRequests[Stri(id)] = request
return id
end function
function vizbee_check_pub_requests()
msg = m.pubRequestsPort.getMessage()
while ((msg <> invalid) AND (type(msg) = "roUrlEvent"))
code = msg.GetResponseCode()
if (code <> 200)
reason = msg.GetFailureReason()
vizbee_log("ERROR", "Publish response code: " + StrI(code))
else
for each key in m.pubRequests
req = m.pubRequests[key]
msgid = msg.GetSourceIdentity()
reqid = req.GetIdentity()
if (msgid = reqid)
m.pubRequests.Delete(key)
end if
end for
end if
msg = m.pubRequestsPort.getMessage()
end while
end function
function vizbee_pubnub_subscribe()
if (GetGlobalAA().Lookup("VizbeeStatus") = "INACTIVE")
return false
end if
if not m.isMsgPortSet
vizbee_log("ERROR", "Calling subscribe without setting msgPort! ")
return false
end if
if m.isSubscribed
return true
end if
timetoken = m.timetoken
if (m.subscribeTimer.TotalMilliseconds() > (m.sub_timeout * 2 * 1000))
vizbee_log("WARN", "Pubnub no subscribe in : " + Stri(m.subscribeTimer.TotalMilliseconds()) + "ms, setting timetoken 0")
timetoken = "0"
end if
config = GetGlobalAA().Lookup("VizbeeConfig")
uuid = m.subURIClient.Escape(config.deviceID)
filter = m.subURIClient.Escape("uuid!=") + "%27" + m.subURIClient.Escape(config.deviceID) + "%27"
url = m.origin + "/subscribe/" + m.sub_key + "/" + m.channel + "/0/" + timetoken + "?uuid=" + uuid + "&filter-expr=" + filter
vizbee_log("VERB", "VizbeePubnub::subscribe url=" + url)
m.subURIClient.SetUrl(url)
ret = m.subURIClient.AsyncGetToString()
if ret
else
vizbee_log("ERROR", "Pubnub subscribe FAILED!")
vizbee_log("ERROR", m.subURIClient.GetFailureReason())
end if
m.isSubscribed = ret
if (m.isSubscribed) then m.subscribeTimer.Mark()
return ret
end function
function vizbee_pubnub_is_my_response(msg) as Boolean
if (type(msg) = "roUrlEvent")
id = msg.GetSourceIdentity()
if (id = m.subURIClient.GetIdentity())
return true
end if
return false
else
return false
end if
end function
function vizbee_pubnub_parse_response(msg)
code = msg.GetResponseCode()
reason = msg.GetFailureReason()
deviceinfo = CreateObject("roDeviceInfo")
status = deviceinfo.GetLinkStatus()
if (status)
else
end if
response = msg.GetString()
if (response = "")
m.isSubscribed = false
m.Subscribe()
return invalid
end if
jo = ParseJson(response)
if ((jo = invalid) OR (NOT (type(jo) = "roArray")))
vizbee_log("ERROR", "Pubnub response json invalid, pubnub reconnecting")
m.isSubscribed = false
m.Subscribe()
return invalid
end if
if (type(jo[0]) = "roArray")
m.isSubscribed = false
m.timetoken = jo[1]
m.Subscribe()
if (jo[0].Count() > 0)
return jo[0]
else
return invalid
end if
else
if (jo[0] = 0)
vizbee_log("ERROR", "Pubnub received error: " + jo[1])
else
end if
m.isSubscribed = false
m.Subscribe()
return invalid
end if
end function

function vizbee_sync_comm_manager()
vizbee_sync_comm_map = CreateObject("roAssociativeArray")
vizbee_sync_comm_timer = CreateObject("roTimespan")
vizbee_sync_comm_timer.Mark()
config = GetGlobalAA().Lookup("VizbeeConfig")
syncSendIntervalInMs = 750
if (config <> invalid) AND (config.features <> invalid) AND (config.features.syncSendIntervalInMs <> invalid)
syncSendIntervalInMs = config.features.syncSendIntervalInMs
end if
return {
id        : config.deviceID
sessionid : vizbee_util().timestamp()
tx        : -1
txidMap             : vizbee_sync_comm_map
updateFrequencyMS   : syncSendIntervalInMs
timer               : vizbee_sync_comm_timer
ResetMsgPort        : vizbee_sync_comm_reset_msg_port
RecvMsgBody         : vizbee_sync_comm_recv_msg_body
SendMsg             : vizbee_sync_comm_send_msg
GetHeader           : vizbee_sync_comm_get_header
GetMsg              : vizbee_sync_comm_get_msg
shouldForwardHeaders : false
pubnub : vizbee_pubnub()
}
end function
function vizbee_sync_comm_get_header()
return {
id : m.id
tx : m.tx
ss : m.sessionid
}
end function
function vizbee_sync_comm_get_msg(header, body)
return {
h : header
b : body
}
end function
function vizbee_sync_comm_reset_msg_port(port)
m.pubnub.ResetMsgPort(port)
end function
function vizbee_sync_comm_recv_msg_body(msg)
if (NOT m.pubnub.IsMyResponse(msg)) then return invalid
jo = m.pubnub.ParseResponse(msg)
if (invalid = jo) then return invalid
bodies = []
for i = 0 to (jo.count() - 1)
obj = jo[i]
if ((invalid <> obj.h) AND (invalid <> obj.b))
header = obj.h
if ((invalid <> header.id) AND (invalid <> header.tx))
id = LCase(header.id)
tx = header.tx
if ((id <> LCase(m.id)) AND (Left(LCase(id),4) <> "roku"))
key = id
if (invalid <> header.ss) then key = key + header.ss
if m.txidMap.DoesExist(key) AND (tx <> 0)
if (m.txidMap.Lookup(key) < tx)
m.txidMap.AddReplace(key, tx)
if (m.shouldForwardHeaders) then
bodies.push(obj)
else
bodies.push(obj.b)
end if
else
vizbee_log("ERROR", "Received duplicate message KEY=" + key + ":TX=" + StrI(tx))
end if
else
m.txidMap.AddReplace(key, tx)
if (m.shouldForwardHeaders) then
bodies.push(obj)
else
bodies.push(obj.b)
end if
end if
else
vizbee_log("VERB", "WARNING: Filtered message with id=" + id)
end if
end if
end if
end for
if (bodies.count() > 0)
return bodies
else
return invalid
end if
end function
function vizbee_sync_comm_send_msg(body, sendFlag)
send = true
if (NOT sendFlag) AND (m.timer.TotalMilliseconds() < m.updateFrequencyMS)
send = false
end if
if (GetGlobalAA().Lookup("VizbeeStatus") = "INACTIVE")
send = false
end if
if (send)
m.tx = m.tx + 1
msg = m.GetMsg(m.getHeader(), body)
m.pubnub.Publish(msg)
m.timer.Mark()
end if
end function

function vizbee_sync_controller()
return {
state                     : vizbee_sync_state_manager()
comm                      : vizbee_presence_extension()
appProxy                  : ""
remotePresent             : false
SetRemotePresent          : vizbee_sync_set_remote_present
SetAppProxy               : vizbee_sync_set_app_proxy
HandleAppEvent            : vizbee_sync_handle_app_event
HandleVideoEvent          : vizbee_sync_handle_video_event
HandleVideoSGEvent        : vizbee_sync_handle_video_sg_event
HandleStartVideoFailure   : vizbee_sync_handle_start_video_failure
HandleVideoStopWithReason : vizbee_sync_handle_video_stop_with_reason
HandleAdEvent             : vizbee_sync_handle_ad_event
HandleChannelEvent        : vizbee_sync_handle_channel_event
HandleOnEvent             : vizbee_sync_handle_on_event
HandleVideoReq            : vizbee_sync_handle_video_req
HandleHeartbeatEvent      : vizbee_sync_handle_heartbeat_event
Message                   : vizbee_sync_message
SendHello                 : vizbee_sync_send_hello
SendHelloWithType         : vizbee_sync_send_hello_with_type
}
end function
function vizbee_sync_set_remote_present()
vizbee_log("INFO", "Setting Remote Present")
m.remotePresent = true
end function
function vizbee_sync_set_app_proxy(proxy)
m.appProxy = proxy
end function
function vizbee_sync_send_hello()
m.SendHellowithType("upd")
end function
function vizbee_sync_send_hello_with_type(typeString)
config = GetGlobalAA().Lookup("VizbeeConfig")
status = {
hstatus: {
id   : config.deviceID
type : "SCREEN"
vip  : "false"
}
}
if (m.state.session = "VIDEO") OR (m.state.session = "AD")
state = m.state.GetState()
if (state <> invalid)
if (state.vstatus <> invalid) AND (state.vstatus.st <> "LOADING")
status.hstatus.vip = "true"
status.vinfo = state.vinfo
status.vinfoext = state.vinfoext
status.vstatus = state.vstatus
end if
end if
end if
m.comm.SendMsg(m.Message({
ns   : "video"
name : "hello"
type : typeString
}, status), true)
end function
function vizbee_sync_handle_app_event(event, param1, param2)
send = false
if (event = "SESSION_UPDATE")
state = param1
id = param2
if state = "APP"
send = m.state.UpdateSession("APP")
else if state = "VIDEO"
videoState = {
state : "unknown"
id : "unknown"
isLive : false
enableTrickPlay : true
posms : -1
durms : -1
}
videoState.state = "SELECTED"
videoState.id = id
send = m.state.UpdateVideo(videoState)
else if state = "AD"
send = m.state.UpdateAd("SELECTED", id, "")
end if
else if (event = "PORT_UPDATE")
portChanged = param1
port = param2
if portChanged
m.comm.ResetMsgPort(port)
else
m.comm.pubnub.Subscribe()
end if
end if
end function
function vizbee_sync_handle_video_event(msg, guid = invalid, video = invalid, player = invalid) As Boolean
send = false
vizbee_log("INFO", "HandleVideoEvent type:" + type(msg))
videoState = {
state : "unknown"
id : "unknown"
isLive : false
enableTrickPlay : true
posms : -1
durms : -1
}
if (type(msg) = "String")
if ((msg = "INTERRUPTED") OR (msg = "FINISHED"))
videoState.state = msg
send = m.state.UpdateVideo(videoState)
end if
end if
if (m.remotePresent)
m.comm.SendMsg(m.state.GetState(), send)
end if
if (m.state.video.st = "INTERRUPTED") OR (m.state.video.st = "FINISHED")
vizbee_log("INFO", "video ended, clearing video guid, po, du")
videoState.state = "RESET"
m.state.UpdateVideo(videoState)
end if
return false
end function
function vizbee_sync_handle_video_sg_event(sgvideonode) As Boolean
if invalid = sgvideonode
return false
end if
if m.state.IsAdPlaying() 
return false
end if
send = false
videoState = {
state : "unknown"
id : "unknown"
isLive : false
title : invalid
subtitle: invalid
imgurl : invalid
enableTrickPlay : true
posms : -1
durms : -1
}
state = sgvideonode.state
if (state = "none" OR state = "stopped" OR state = "finished" OR state = "error")
if (NOT m.state.DidGetVideoUpdateFromPlayer())
return false
else if (m.state.video.st = "PAUSED_BY_AD")
return false
else if (m.state.video.st <> "FINISHED" AND m.state.video.st <> "INTERRUPTED") then
if (state = "finished") then
videoState.state = "FINISHED"
send = m.state.UpdateVideoWithPlayer(sgvideonode, videoState)
else
videoState.state = "INTERRUPTED"
send = m.state.UpdateVideoWithPlayer(sgvideonode, videoState)
end if
else
videoState.state = "RESET"
m.state.UpdateVideoWithPlayer(sgvideonode, videoState)
m.state.UpdateSession("SCREEN")
return false
end if
else
videoInfo = m.appProxy.GetVideoInfo(sgvideonode)
if videoInfo = invalid
vizbee_log("WARN", "VizbeeSynController::vizbee_sync_handle_video_sg_event - Got invalid videoInfo")
return false
end if
videoState.id = videoInfo.guid
videoState.isLive = videoInfo.isLive
videoState.title = videoInfo.title
videoState.subtitle = videoInfo.subtitle
videoState.imgurl = videoInfo.imgurl
if (NOT m.state.DidGetVideoUpdateFromPlayer())
videoState.state = "SELECTED"
m.state.UpdateVideoWithPlayer(sgvideonode, videoState)
end if
videoState.posms = sgvideonode.position * 1000
videoState.durms = sgvideonode.duration * 1000
videoState.enableTrickPlay = sgvideonode.enableTrickPlay
if state = "buffering" then
videoState.state = "BUFFERING"
m.state.UpdateVideoWithPlayer(sgvideonode, videoState)
else if state = "playing" then
videoState.state = "PLAYING"
m.state.UpdateVideoWithPlayer(sgvideonode, videoState)
else if state = "paused" then
videoState.state = "PAUSED_BY_USER"
m.state.UpdateVideoWithPlayer(sgvideonode, videoState)
end if
end if
if (m.remotePresent)
m.comm.SendMsg(m.state.GetState(), send)
end if
return true
end function
function vizbee_sync_handle_start_video_failure(startVideoFailureInfo as Object) as dynamic
vizbee_log("INFO", "StartVideo FailureInfo" + startVideoFailureInfo.message)
videoState = {
state: "INTERRUPTED"
id: "unknown"
isLive: false
title: invalid
subtitle: invalid
imgurl: invalid
enableTrickPlay: true
posms: -1
durms: -1
}
m.state.UpdateVideo(videoState)
m.state.UpdateSession("VIDEO")
m.comm.SendMsg(m.state.GetState(), true)
videoState.state = "RESET"
m.state.UpdateVideo(videoState)
m.state.UpdateSession("SCREEN")
end function
function vizbee_sync_handle_video_stop_with_reason(videoStopReasonInfo as object) as dynamic
vizbee_log("INFO", "Video Stop Reason: " + videoStopReasonInfo.reason)
videoState = {
state: "INTERRUPTED"
id: "unknown"
isLive: false
title: invalid
subtitle: invalid
imgurl: invalid
enableTrickPlay: true
posms: -1
durms: -1
}
m.state.UpdateVideo(videoState)
m.state.UpdateSession("VIDEO")
m.comm.SendMsg(m.state.GetState(), true)
videoState.state = "RESET"
m.state.UpdateVideo(videoState)
m.state.UpdateSession("SCREEN")
end function
function vizbee_sync_handle_ad_event(eventType, adId, duration, position) As Boolean
knownEvent = true
send = false
if (duration <> -1) then
durationMs = duration * 1000
else
durationMs = -1
end if
if (position <> -1) then positionMs = position * 1000
if eventType = "Start" then
vizbee_log("INFO", "Video LOADING")
send = m.state.UpdateAd("LOADING", -1, durationMs)
else if eventType = "playingStart"
vizbee_log("INFO", "Video STARTED")
send = m.state.UpdateAd("PLAYING", 0, durationMs)
else if eventType = "playingFirstQuartile" then
positionMs = Int(0.25 * durationMs)
vizbee_log("INFO", "Ad First Quartile dur=" + StrI(durationMs) + " pos=" + StrI(positionMs))
send = m.state.UpdateAd("PLAYING", positionMs, durationMs)
else if eventType = "playingMidpoint" then
positionMs = Int(0.5 * durationMs)
vizbee_log("INFO", "Ad Mid Point dur=" + StrI(durationMs) + " pos=" + StrI(positionMs))
send = m.state.UpdateAd("PLAYING", positionMs, durationMs)
else if eventType = "playingThirdQuartile" then
positionMs = Int(0.75 * durationMs)
vizbee_log("INFO", "Ad Third Quartile dur=" + StrI(durationMs) + " pos=" + StrI(positionMs))
send = m.state.UpdateAd("PLAYING", positionMs, durationMs)
else if eventType = "Position" then
vizbee_log("INFO", "Video POSITION=" + StrI(positionMs))
send = m.state.UpdateAd("PLAYING", positionMs, durationMs)
else if eventType = "Close" or eventType = "Error" or eventType = "Skipped" then
vizbee_log("INFO", "Ad INTERRUPTED")
send = m.state.UpdateAd("INTERRUPTED", "", "")
else if eventType = "Complete" then
vizbee_log("INFO", "Ad FINISHED ")
send = m.state.UpdateAd("FINISHED", "", "")
else
knownEvent = false
end if
if (knownEvent AND m.remotePresent)
m.comm.SendMsg(m.state.GetState(), send)
end if
end function
function vizbee_sync_handle_channel_event(msg, player = invalid) As Boolean
vizbee_log("VERB", "HandleChannelEvent")
m.state.LogState()
messages = m.comm.RecvMsg(msg)
if (messages = invalid) return false
for i = 0 to (messages.count() - 1)
body = messages[i].b
header = messages[i].h
if (m.HandleVideoReq(header, body, player)) then return true
end for
return false
end function
function vizbee_sync_handle_on_event(eventInfo as object) As Boolean
vizbee_log("VERB", "HandleOnEvent")
if eventInfo = invalid then return false
eventName = eventInfo.eventName
if eventName = invalid or eventName = "" then return false
eventData = eventInfo.eventData
if eventData = invalid then return false
vizbee_log("VERB", "HandleOnEvent - Sending event to mobile")
m.comm.SendMsg(m.Message({
ns   : "video"
name : "event"
type : "req"
}, { 
einfo: {
"type": eventName
"data": eventData
} 
}), true)
return true
end function
function vizbee_sync_handle_video_req(header, body, player) as Boolean
breakLoop = false
if (invalid = body) then return breakLoop
if (invalid = body.cmd) OR (invalid = body.cmd.ns) then return breakLoop
cmd_ns   = LCase(body.cmd.ns)
cmd_name = LCase(body.cmd.name)
cmd_type = LCase(body.cmd.type)
vizbee_log("INFO", "cmdname=" + cmd_name)
if (cmd_ns <> "video") then return breakLoop
if (cmd_type <> "req") AND (cmd_type <> "rsp") AND (cmd_type <> "upd") then return breakLoop
if (cmd_type <> "req") then return breakLoop
m.SetRemotePresent()
if (cmd_name = "start_video")
if (body.vinfo <> invalid) AND (body.vinfo.id <> invalid)
starttime = vizbee_sync_validate_time(body.cmd.param, invalid)
if (starttime = invalid) then starttime = 0
starttime = Int(starttime / 1000)
vizbee_log("INFO", "Command start video called: contentId=" + body.vinfo.id + " starttime=" + str(starttime))
url = "" 
if body.vinfo.url <> invalid then
url = body.vinfo.url
end if
isLive = false
if body.vinfo.isLive <> invalid then
isLive = body.vinfo.islive
end if
videoInfo = {
guid: body.vinfo.id
url: url
startTime : starttime
isLive : isLive
}
if body.vinfoext <> invalid then
if body.vinfoext.title <> invalid then
videoInfo.title = body.vinfoext.title
end if
if body.vinfoext.subtitle <> invalid then
videoInfo.subtitle = body.vinfoext.subtitle
end if
if body.vinfoext.desc <> invalid then
videoInfo.desc = body.vinfoext.desc
end if
if body.vinfoext.imgurl <> invalid then
videoInfo.imgurl = body.vinfoext.imgurl
end if
if body.vinfoext.cuepoints <> invalid then
videoInfo.adsInfo = {}
videoInfo.adsInfo.cuepoints = body.vinfoext.cuepoints
end if
if body.vinfoext.protocoltype <> invalid then
videoInfo.protocoltype = body.vinfoext.protocoltype
end if
if body.vinfoext.drmtype <> invalid then
videoInfo.drmtype = body.vinfoext.drmtype
end if
if body.vinfoext.drmlicenseurl <> invalid then
videoInfo.drmlicenseurl = body.vinfoext.drmlicenseurl
end if
if body.vinfoext.drmcustomdata <> invalid then
videoInfo.drmcustomdata = body.vinfoext.drmcustomdata
end if
if body.vinfoext.customstreaminfo <> invalid then
videoInfo.customstreaminfo = body.vinfoext.customstreaminfo
end if
if body.vinfoext.custommetadata <> invalid then
videoInfo.custommetadata = body.vinfoext.custommetadata
end if
end if
breakLoop = m.appProxy.StartVideo(videoInfo)
if breakLoop then
vizbee_log("INFO", "StartVideo breaking loop!")
end if
end if
else if (cmd_name = "status")
if (m.state.session = "VIDEO")
state = m.state.GetState()
m.comm.SendMsg(state, true)
else
end if
else if (cmd_name = "play")
if (m.state.session = "VIDEO")
playerToUse = player
if (invalid = playerToUse)
playerToUse = m.state.player
end if
success = m.appProxy.PlayVideo(playerToUse)
vizbee_log("INFO", "Command play called")
else
vizbee_log("INFO", "Play called in non video state")
end if
else if (cmd_name = "pause")
if (m.state.session = "VIDEO")
playerToUse = player
if (invalid = playerToUse)
playerToUse = m.state.player
end if
success = m.appProxy.PauseVideo(playerToUse)
vizbee_log("INFO", "Command pause called")
else
vizbee_log("INFO", "Pause called in non video state")
end if
else if (cmd_name = "stop")
if (m.state.session = "VIDEO")
playerToUse = player
if (invalid = playerToUse)
playerToUse = m.state.player
end if
reason = "stop_reason_unknown"
if (type(body.cmd.param) = "String")
reason = LCase(body.cmd.param)
end if
success = m.appProxy.StopVideo(playerToUse, reason)
vizbee_log("INFO", "Command stop called")
else
vizbee_log("INFO", "Stop called in non video state")
end if
else if (cmd_name = "exit")
else if (cmd_name = "seek")
playerToUse = player
if (invalid = playerToUse)
playerToUse = m.state.player
end if
if (type(body.cmd.param) = "String") AND (playerToUse <> invalid) AND (m.state.session = "VIDEO")
time = vizbee_sync_validate_time(body.cmd.param, playerToUse, m.appProxy)
if (time <> invalid)
success = m.appProxy.Seek(time, playerToUse)
vizbee_log("INFO", "Command seek called - " + Stri(time))
end if
end if
else if (cmd_name = "hello")
if ((cmd_type = "req") AND (LCASE(body.hstatus.type) <> "screen")) then
m.SendHelloWithType("rsp")
else
vizbee_log("INFO", "WARNING -- ignored hello")
end if
else if (cmd_name = "event")
if body.einfo <> invalid
eventInfo = body.einfo
if eventInfo <> invalid AND eventInfo.type <> invalid AND eventInfo.data <> invalid
eventType = LCase(eventInfo.type)
if eventType = "tv.vizbee.homesign.signin"
ret = VZB().metrics.trackScreenSignIn(eventInfo.data.authInfo)
end if
if header <> invalid and header.ssinfo <> invalid then
senderInfo = vizbee_sync_parse_sender_info_from_sender_session_info(header.ssinfo)
eventInfo.append({senderInfo: senderInfo})
end if
end if
success = m.appProxy.OnEvent(eventInfo)
vizbee_log("INFO", "OnEvent called")
end if
end if
return breakLoop
end function
function vizbee_sync_validate_time(time, player, appProxy=invalid) as Dynamic
if (type(time) <> "String") then return invalid
time = time.toInt()
if (time = invalid) then return invalid
if (time < 0) then return invalid
return time
end function
function vizbee_sync_handle_heartbeat_event() As Boolean
if (m.remotePresent)
m.comm.SendMsg(m.state.GetState(), false)
end if
return false
end function
function vizbee_sync_message(cmd, objects = invalid)
body = {
vers: 1
}
if (cmd <> invalid) then body.cmd = cmd
if (type(objects) = "roAssociativeArray")
for each key in objects
body[key] = objects[key]
next
end if
return body
end function
function vizbee_sync_parse_sender_info_from_sender_session_info(senderSessionInfo as object) as object
senderInfo = {}
if senderSessionInfo <> invalid
senderInfo = {
"deviceId": senderSessionInfo.REMOTE_DEVICE_ID
"deviceType": senderSessionInfo.REMOTE_DEVICE_TYPE
"friendlyName": senderSessionInfo.REMOTE_FRIENDLY_NAME
"sessionId": senderSessionInfo.REMOTE_NETWORK_SESSION_ID
}
end if
return senderInfo
end function
function vizbee_sync_state_manager()
return {
session         : "SCREEN"
video           : vizbee_sync_state_video()
ad              : vizbee_sync_state_ad()
player          : invalid
lastVideoIDFromSync : invalid
UpdateSession   : vizbee_sync_update_session
UpdateVideo     : vizbee_sync_update_video
UpdateVideoWithPlayer : vizbee_sync_update_video_with_player
UpdateAd        : vizbee_sync_update_ad
IsAdPlaying     : vizbee_sync_is_ad_playing
GetState        : vizbee_sync_get_state
DidGetVideoUpdateFromPlayer : vizbee_sync_did_get_video_update_from_player
LogState        : vizbee_sync_state_log
isLive          : false
title          : invalid
subtitle       : invalid
imgurl         : invalid
customStreamInfo : invalid
customMetadata : invalid          
GetVideoSessionID           : vizbee_sync_state_video_session_id
elapsedPlayTimeTracker      : vizbee_elapsed_playtime_tracker()
lasttime        : 0
}
end function
function vizbee_sync_state_log()
end function
function vizbee_sync_get_state() as Object
state = {
vers: 1
cmd: {
type: "upd"
ns:   "video"
name: "status"
}
}
if (m.session = "VIDEO")
state.vinfo = {
id: m.video.id
url: ""
isLive: m.isLive
}
state.vinfoext = {
title: ""
imgurl: ""
}
if (invalid <> m.title)
state.vinfoext.title = m.title
end if
if (invalid <> m.subtitle)
state.vinfoext.subtitle = m.subtitle
end if
if (invalid <> m.imgurl)
state.vinfoext.imgurl = m.imgurl
end if
if (invalid <> m.customStreamInfo)
state.vinfoext.customStreamInfo = m.customStreamInfo
end if
if (invalid <> m.customMetadata)
state.vinfoext.customMetadata = m.customMetadata
end if
state.vstatus = m.video
else if (m.session = "AD")
state.vinfo = {
id: m.video.id
url: ""
isLive : m.isLive
}
state.vinfoext = {
title: ""
imgurl: ""
}
if (invalid <> m.title)
state.vinfoext.title = m.title
end if
if (invalid <> m.subtitle)
state.vinfoext.subtitle = m.subtitle
end if
if (invalid <> m.imgurl)
state.vinfoext.imgurl = m.imgurl
end if
if (invalid <> m.customStreamInfo)
state.vinfoext.customStreamInfo = m.customStreamInfo
end if
if (invalid <> m.customMetadata)
state.vinfoext.customMetadata = m.customMetadata
end if
state.vstatus = m.video
state.adstatus = m.ad
else if (m.session = "SCREEN")
end if
return state
end function
function vizbee_sync_update_session(ss)
m.LogState()
if (m.session = "VIDEO" AND ss = "SCREEN")
if (m.video.st <> "FINISHED")
m.video.st = "INTERRUPTED"
end if
end if
if (m.session = "AD" AND ss = "SCREEN")
if (m.video.st <> "FINISHED")
m.video.st = "INTERRUPTED"
end if
if (m.ad.st <> "FINISHED")
m.ad.st = "INTERRUPTED"
end if
end if
m.session = ss
return true
end function
function vizbee_sync_did_get_video_update_from_player() as Boolean
if ((m.session = "SCREEN") OR (m.session = "VIDEO" AND m.video.st = "LOADING"))
return false
end if
return true
end function
function vizbee_sync_update_video_with_player(player, videoState)
if player <> invalid then
m.player = player
end if
return m.UpdateVideo(videoState)
end function
function vizbee_sync_update_video(videoState)
m.LogState()
m.session = "VIDEO"
sendFlag = true
m.title = videoState.title
m.imgurl = videoState.imgurl
if videoState.subtitle <> invalid
m.subtitle = videoState.subtitle
end if
event = videoState.state
if ((event <> "SELECTED") AND (event <> "INTERRUPTED") AND (event <> "FINISHED") AND (event <> "RESET")) then
if (videoState.id <> m.video.id) then
event = "SELECTED"
end if
end if
if (event = "SELECTED")
duplicate = false
if ((m.video.st = "LOADING") AND (m.video.id = videoState.id))
duplicate = true
end if
m.video.st = "LOADING"
m.video.id = videoState.id
if (m.video.id <> m.lastVideoIDFromSync)
m.lastVideoIDFromSync = invalid
end if
m.video.ss = m.GetVideoSessionID(m.video.id)
if (videoState.isLive = true)
m.isLive = true
else
m.isLive = false
end if
m.video.po = -1
m.video.du = -1
if videoState.customStreamInfo <> invalid
m.customStreamInfo = videoState.customStreamInfo
end if
if videoState.customMetadata <> invalid
m.customMetadata = videoState.customMetadata
end if
m.elapsedPlayTimeTracker.reset()
m.lasttime = 0
if (NOT duplicate)
ret = VZB().metrics.trackScreenViewStart(m)
end if
return true
else if (event = "LOADING")
if (m.video.st = "LOADING")
sendFlag = false
end if
m.video.st = "LOADING"
m.elapsedPlayTimeTracker.setNotPlaying()
m.lasttime = 0
return sendFlag
else if (event = "BUFFERING")
if (m.video.st = "BUFFERING")
sendFlag = false
end if
m.video.st = "BUFFERING"
m.elapsedPlayTimeTracker.setNotPlaying()
m.lasttime = 0
return sendFlag
else if (event = "PLAYING")
if (m.video.st = "PLAYING")
sendFlag = false
end if
if (videoState.posms >= (m.lasttime + 1000))
m.lasttime = videoState.posms
sendFlag = true
end if
m.video.st = "PLAYING"
m.video.po = videoState.posms
m.video.du = videoState.durms
m.video.tp = videoState.enableTrickPlay
m.elapsedPlayTimeTracker.setPlaying()
ret = VZB().metrics.trackScreenViewDuration(m)
return sendFlag
else if (event = "PAUSED_BY_USER")
m.video.st = "PAUSED_BY_USER"
m.video.po = videoState.posms
m.video.du = videoState.durms
m.elapsedPlayTimeTracker.setNotPlaying()
return true
else if (event = "RESUMED")
m.video.st = "PLAYING"
m.elapsedPlayTimeTracker.setPlaying()
return true
else if (event = "PAUSED_FOR_AD")
m.video.st = "PAUSED_BY_AD"
m.elapsedPlayTimeTracker.setNotPlaying()
return true
else if (event = "PLAY_PAUSE_TOGGLE")
if (m.video.st = "PLAYING")
m.video.st = "PAUSED_BY_USER"
m.elapsedPlayTimeTracker.setNotPlaying()
else
m.video.st = "PLAYING"
m.elapsedPlayTimeTracker.setPlaying()
end if
return true
else if (event = "INTERRUPTED")
if (m.video.st = "INTERRUPTED" OR m.video.st = "FINISHED")
return false
end if
m.video.st = "INTERRUPTED"
m.elapsedPlayTimeTracker.setNotPlaying()
m.lasttime = 0
return true
else if (event = "FINISHED")
m.video.st = "FINISHED"
m.elapsedPlayTimeTracker.setNotPlaying()
m.lasttime = 0
return true
else if (event = "RESET")
m.video.id = videoState.id
if (m.video.id <> m.lastVideoIDFromSync)
m.lastVideoIDFromSync = invalid
end if
m.video.ss = "UNKNOWN"
m.video.po = -1
m.video.du = -1
m.title = invalid
m.subtitle = invalid
m.imgurl = invalid
m.customStreamInfo = invalid
m.customMetadata = invalid
m.elapsedPlayTimeTracker.reset()
m.lasttime = 0
m.player = invalid
return false
end if
end function
function vizbee_sync_update_ad(event, param1, param2) as Boolean
m.session = "AD"
sendFlag = true
if (event = "SELECTED")
m.video.st = "PAUSED_BY_AD"
m.ad.st = "LOADING"
m.ad.id = param1
m.ad.po = -1
m.ad.du = -1
m.lasttime = 0
return true
else if (event = "LOADING")
if (m.ad.st = "LOADING")
sendFlag = false
end if
m.ad.st = "LOADING"
m.lasttime = 0
m.ad.po = -1
m.ad.du = param2
return sendFlag
else if (event = "PLAYING")
if (m.ad.st = "PLAYING")
sendFlag = false
end if
if (param1 >= (m.lasttime + 1000))
vizbee_log("INFO", "playing increment more than 1000, forcing send")
m.lasttime = param1
sendFlag = true
end if
m.ad.st = "PLAYING"
m.ad.po = param1
m.ad.du = param2
return sendFlag
else if (event = "INTERRUPTED")
m.ad.st = "INTERRUPTED"
m.lasttime = 0
return true
else if (event = "FINISHED")
m.ad.st = "FINISHED"
m.lasttime = 0
m.ad.po = m.ad.du
return true
end if
return true
end function
function vizbee_sync_state_video()
return {
id : ""
ss : ""
st : "NONE"
po : -1
du : -1
}
end function
function vizbee_sync_state_ad()
return {
id : ""
st : "NONE"
po : -1
du : -1
qu : -1
}
end function
function vizbee_sync_is_ad_playing() as Boolean
if m.ad.st <> "NONE" and m.ad.st <> "LOADING" and m.ad.st <> "INTERRUPTED" and m.ad.st <> "FINISHED"
return true
end if
return false
end function
function vizbee_sync_state_video_session_id(videoID)
sessionID = "UNKNOWN"
if videoID = invalid
return sessionID
end if
config = VZB().config
if (config <> invalid)
properties = config.properties
if (properties <> invalid)
date = CreateObject("roDateTime")
sessionID = properties.deviceID + ":" + videoID + ":" + date.ToISOString()
vizbee_log("INFO", "VideoSessionID: " + sessionID)
end if
end if
return sessionID
end function

function vizbee_content_util()
this = {
GetPosterURL: vizbee_content_util_get_poster_url
}
return this
end function
function vizbee_content_util_get_poster_url(content)
poster_url = invalid
if invalid = content
return poster_url
end if
if ((invalid <> content.sdposterurl) AND ("" <> content.sdposterurl)) then
poster_url = content.sdposterurl
else if ((invalid <> content.hdposterurl) AND ("" <> content.hdposterurl)) then
poster_url = content.hdposterurl
else if ((invalid <> content.fhdposterurl) AND ("" <> content.fhdposterurl)) then
poster_url = content.fhdposterurl
end if
return poster_url
end function
function VizbeeErrorType() as object
return {
SIGNIN: {
UNKNOWN_ERROR: "E001",
USER_NOT_SIGNED_IN: "E002",
UNKNOWN_SIGN_IN_METHOD: "E003",
PROFILE_NOT_SUPPORTED: "E101",
PROFILE_REG_CODE_GENERATION_FAILED: "E102",
PROFILE_REG_CODE_POLLING_FAILED: "E103",
PROFILE_REG_CODE_SUBMISSION_WITH_ACCESS_TOKEN_FAILED: "E104",
PROFILE_REG_CODE_ASSOCIATED_USER_FETCH_FAILED: "E105",
PROFILE_USER_FETCH_FAILED: "E106",
PROFILE_AUTH_CHECK_AFTER_PROFILE_CHANGE_FAILED: "E107",
MVPD_NOT_SUPPORTED: "E201",
MVPD_REG_CODE_GENERATION_FAILED: "E202",
MVPD_REG_CODE_POLLING_FAILED: "E203",
MVPD_REG_CODE_SUBMISSION_WITH_ACCESS_TOKEN_FAILED: "E204",
MVPD_REG_CODE_ASSOCIATED_USER_FETCH_FAILED: "E205",
MVPD_USER_FETCH_FAILED: "E206",
MVPD_AUTH_CHECK_AFTER_PROFILE_CHANGE_FAILED: "E207",
}
}
end function
function vizbee_roku_connection_info_util_constructor()
this = {}
deviceInfo = CreateObject("roDeviceInfo")
this._connectionInfo = deviceInfo.GetConnectionInfo()
this.getRokuConnectionType = function() as String
return m._connectionInfo.type
end function
this.getRokuInternalIPAddress = function() as String
internalIPAddress = ""
ipAddress = m._connectionInfo.ip
if ipAddress <> invalid and ipAddress <> ""
internalIPAddress = ipAddress
end if
vizbee_log("VERB", "VizbeeRokuConnectionInfoUtil::GetRokuInternalIPAddress - " + internalIPAddress)
return internalIPAddress 
end function
this.getRokuIPv6Addresses = function() as dynamic
ipv6Addresses = m._connectionInfo.ipv6
if vizbee_util().isNonEmptyArray(ipv6Addresses)
vizbee_log("INFO", "VizbeeRokuUtil::getRokuIPv6Addresses - got valid ipv6addresses")
return ipv6Addresses
end if
return []
end function
this.getRokuSSID = function() as String
ssid = "unknown"
if m.getRokuConnectionType() = "WiFiConnection" then
ssid = m._connectionInfo.ssid
if ssid = invalid or ssid = ""
ssid = "unknown"
end if
end if
vizbee_log("VERB", "VizbeeRokuConnectionInfoUtil::GetRokuSSID - " + ssid)
return ssid
end function
return this
end function

function vizbee_roku_device_info_util_constructor()
this = {}
deviceInfo = CreateObject("roDeviceInfo")
this._deviceInfo = deviceInfo
this.getRokuConnectionType = function() as String
return m._deviceInfo.GetConnectionType()
end function
this.getRokuInternalIPAddress = function() as String
internalIPAddress = ""
ipAddrsAA = m._deviceInfo.GetIPAddrs()
if ipAddrsAA <> invalid then
for each key in ipAddrsAA
if ipAddrsAA[key] <> invalid and ipAddrsAA[key] <> ""
internalIPAddress = ipAddrsAA[key]
vizbee_log("VERB", "VizbeeRokuDeviceInfoUtil::GetRokuInternalIPAddress - " + internalIPAddress)
return internalIPAddress
end if
end for
end if
vizbee_log("VERB", "VizbeeRokuDeviceInfoUtil::GetRokuInternalIPAddress - " + internalIPAddress)
return internalIPAddress
end function
this.getRokuSSID = function() as String
return "unknown"
end function
this.getRokuOSVersion = function() as String
rokuOSFullVersion = "unknown"
osVersion = m._deviceInfo.GetOSVersion()
if osVersion <> invalid then
if osVersion.major <> invalid then
rokuOSFullVersion = osVersion.major
end if
if osVersion.minor <> invalid then
rokuOSFullVersion = rokuOSFullVersion + "." + osVersion.minor
end if
if osVersion.revision <> invalid then
rokuOSFullVersion = rokuOSFullVersion + "." + osVersion.revision
end if
if osVersion.build <> invalid then
rokuOSFullVersion = rokuOSFullVersion + " (build " + osVersion.build + ")"
end if
end if
return rokuOSFullVersion
end function
return this
end function

function vizbee_roku_ip_info_util_constructor()
return {
getIPv6AddressFromIPService: function() as string
request = CreateObject("roUrlTransfer")
request.SetUrl("https://ip.claspws.tv")
ipv6Response = vizbee_util().apiGetWithHeaders(request)
if ipv6Response <> invalid and ipv6Response.headers <> invalid and ipv6Response.headers["x-vzb-client-ip"] <> invalid
ipv6Address = ipv6Response.headers["x-vzb-client-ip"]
end if
if not vizbee_util().isStringAndValueNotEmpty(ipv6Address)
vizbee_log("INFO", "VizbeeRokuIpInfoUtil::GetIPv6AddressFromIPService - got invalid ipv6address")
return ""
end if
return ipv6Address
end function
}
end function

function vizbee_roku_util_constructor()
this = {}
this._rokuUtilImpl = vizbee_roku_connection_info_util_constructor()
this._rokuIPInfoImpl = vizbee_roku_ip_info_util_constructor()
this._rokuDeviceInfoImpl = vizbee_roku_device_info_util_constructor()
this.getRokuConnectionType = function() as String
return m._rokuUtilImpl.getRokuConnectionType()
end function
this.getRokuInternalIPAddress = function() as String
return m._rokuUtilImpl.getRokuInternalIPAddress()
end function
this.getRokuIPV6AddressFromIPService = function() as dynamic
return m._rokuIPInfoImpl.getIPv6AddressFromIPService()
end function
this.getRokuIPv6AddressesFromPlatform = function() as dynamic
return m._rokuUtilImpl.getRokuIPv6Addresses()
end function
this.getRokuSSID = function() as String
return m._rokuUtilImpl.getRokuSSID()
end function
this.getRokuOSVersion = function() as String
return m._rokuDeviceInfoImpl.getRokuOSVersion()
end function
return this
end function

function vizbee_util()
util = {}
util.apiGet = function(request, timeout = 2500) as Dynamic
response = invalid
if (request = invalid) then return response
request = m.apiRequest(request)
request.SetPort(CreateObject("roMessagePort"))
timer = CreateObject("roTimespan")
timer.Mark()
if (request.AsyncGetToString())
vizbee_log("INFO", "APIGET: waiting for response ...")
event = wait(timeout, request.GetPort())
if (type(event) = "roUrlEvent")
if (event.GetResponseCode() <> 500)
response = event.GetString()
end if
else if (event = invalid)
request.AsyncCancel()
vizbee_log("INFO", "APIGET: timeout " + Stri(timer.TotalMilliseconds()) + "ms")
else
end if
end if
if (response <> invalid)
vizbee_log("INFO", "APIGET: response = ", response)
response = ParseJSON(response)
end if
vizbee_log("INFO", "APIGET: " + Stri(timer.TotalMilliseconds()) + "ms")
return response
end function
util.apiGetWithHeaders = function(request, timeout = 2500) as Dynamic
response = invalid
if (request = invalid) return response
request = m.apiRequest(request)
request.SetPort(CreateObject("roMessagePort"))
timer = CreateObject("roTimespan")
timer.Mark()
if (request.AsyncGetToString())
vizbee_log("INFO", "ApiGetWithHeaders: waiting for response ...")
event = wait(timeout, request.GetPort())
if (type(event) = "roUrlEvent")
if (event.GetResponseCode() <> 500)
response = {
headers: event.GetResponseHeaders()
body: event.GetString()
}
end if
else if (event = invalid)
request.AsyncCancel()
vizbee_log("INFO", "ApiGetWithHeaders: timeout " + Stri(timer.TotalMilliseconds()) + "ms")
else
end if
end if
if (response <> invalid and response.body <> invalid)
vizbee_log("INFO", "ApiGetWithHeaders: response = ", response)
response.body = ParseJSON(response.body)
end if
vizbee_log("INFO", "ApiGetWithHeaders: " + Stri(timer.TotalMilliseconds()) + "ms")
return response
end function
util.apiRequest = function(request as Object) as Dynamic
date = m.ISO8601Date()
request.EnablePeerVerification(false)
request.SetCertificatesFile("common:/certs/ca-bundle.crt")
request.InitClientCertificates()
request.AddHeader("Content-Type", "application/json")
request.AddHeader("Vizbee-Version", "1.0.0 " + date)
request.RetainBodyOnError(true)
return request
end function
util.rrPost = function(request) as Dynamic
timer = CreateObject("roTimespan")
timer.Mark()
timeout = 500
response = false
if (request = invalid) then return response
request.SetPort(CreateObject("roMessagePort"))
if (request.AsyncPostFromString(""))
event = wait(timeout, request.GetPort())
if (type(event) = "roUrlEvent")
response = true
else if (event = invalid)
request.AsyncCancel()
else
end if
end if
vizbee_log("INFO", "rrPost: " + Stri(timer.TotalMilliseconds()) + "ms")
return response
end function
util.storeGet = function(key as String, vizbeeRegistrySection as String) as Dynamic
reg = CreateObject("roRegistrySection", vizbeeRegistrySection)
if reg.Exists(key) then return reg.Read(key)
return invalid
end function
util.storeSet = function(key as String, value as String, vizbeeRegistrySection as String)
reg = CreateObject("roRegistrySection", vizbeeRegistrySection)
reg.Write(key, value)
reg.Flush()
end function
util.storeClear = function(key as String, vizbeeRegistrySection as String)
reg = CreateObject("roRegistrySection", vizbeeRegistrySection)
reg.Delete(key)
reg.Flush()
end function
util.configGet = function() as Dynamic
config = m.storeGet("config", vizbee_constants().REGISTRY_SECTION.CONFIG)
if (config <> invalid) then config = ParseJson(config)
if (config = invalid)
vizbee_log("PROD", "R:002 empty or invalid config from store")
end if
return config
end function
util.contains = function(arr as Object, value as String) as Boolean
for each entry in arr
if entry = value
return true
end if
end for
return false
end function
util.isEqual = function(value1 as dynamic, value2 as dynamic) as Boolean
if value1 = invalid or value2 = invalid
return false
end if
if m.isString(value1) and m.isString(value2)
return value1 = value2
end if
if m.isNumber(value1) and m.isNumber(value2)
return value1 = value2
end if
if m.isBoolean(value1) and m.isBoolean(value2)
return value1 = value2
end if
return false
end function
util.isString = function(value as dynamic) as Boolean
return type(value) = "roString" OR type(value) = "String"
end function
util.isStringAndValueNotEmpty = function(value as dynamic) as Boolean
return m.isString(value) AND value <> ""
end function
util.isBoolean = function(value as dynamic) as Boolean
return type(value) = "roBoolean" or type(value) = "Boolean"
end function
util.isInteger = function(value as dynamic) as boolean
t = type(value)
return t = "Int" or t = "Integer" or t = "roInteger" or t = "roInt"
end function
util.isNumber = function(value as dynamic) as Boolean
t = type(value)
return t = "Int" or t = "Integer" or t = "roInteger" or t = "roInt" or t = "Float" or t = "roFloat" or t = "Double" or t = "roDouble"
end Function
util.isObject = function(value as dynamic) as boolean
return type(value) = "Object" or type(value) = "roAssociativeArray"
end function
util.isNonEmptyObject = function(value as dynamic) as boolean
return m.isObject(value) and value.keys().count() > 0
end function
util.isArray = function(value as dynamic) as boolean
return type(value) = "roArray"
end function
util.isNonEmptyArray = function(value as dynamic) as boolean
return m.isArray(value) and value.count() > 0
end function
util.isValidIPv4Address = function(value as string) as boolean
ipv4AddressRegexMatcher = "(\b25[0-5]|\b2[0-4][0-9]|\b[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}"
regex = CreateObject("roRegEx", ipv4AddressRegexMatcher, "i")
return regex.IsMatch(LCase(value.Trim()))
end function
util.ISO8601Date = function(date = CreateObject("roDateTime") as Object) as String
d = m.padLeft(date.GetYear().ToStr(), 4)
d = d + "-" + m.padLeft(date.GetMonth().ToStr(), 2)
d = d + "-" + m.padLeft(date.GetDayOfMonth().ToStr(), 2)
d = d + "T" + m.padLeft(date.GetHours().ToStr(), 2)
d = d + ":" + m.padLeft(date.GetMinutes().ToStr(), 2)
d = d + ":" + m.padLeft(date.GetSeconds().ToStr(), 2) + ".000Z"
return d
end function
util.timestamp = function(date = CreateObject("roDateTime") as Object) as String
t = m.padLeft(date.GetYear().ToStr(), 4)
t = t + ":" + m.padLeft(date.GetMonth().ToStr(), 2)
t = t + ":" + m.padLeft(date.GetDayOfMonth().ToStr(), 2)
t = t + ":" + m.padLeft(date.GetHours().ToStr(), 2)
t = t + ":" + m.padLeft(date.GetMinutes().ToStr(), 2)
t = t + ":" + m.padLeft(date.GetSeconds().ToStr(), 2)
t = t + ":" + m.padLeft(date.GetMilliseconds().ToStr(), 3)
return t
end function
util.flattenJSON = function(data as Dynamic) as Object
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
util.padLeft = function(value as String, length as Integer) as String
while (value.Len() < length)
value = "0" + value
end while
return value
end function
util.stringToDictionary = function(input as String, interKVDelimiter as String, intraKVDelimiter as String) as Object
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
return util
end function

function vizbee_on_raf_callback_data(rafCallbackData as dynamic) as void
if rafCallbackData = invalid
vizbee_log("VERB", "VizbeeRAF::vizbee_on_raf_callback_data - invalid RAF callback data")
return
end if
eventType = rafCallbackData.eventType
ctx = rafCallbackData.ctx
adInfo = vizbee_raf_get_ad_info(eventType, ctx)
	
adId = adInfo.adId
if m.appProxy <> invalid and adId <> invalid
m.appProxy.UpdateStateForRAFAd(adId)
if eventType = invalid
eventType = "Position"
end if
m.appProxy.syncController.HandleAdEvent(eventType, adId, adInfo.adDuration, adInfo.adPosition)
end if
end function
function vizbee_raf_get_ad_info(eventType as dynamic, ctx as dynamic) as object
adInfo = {}
if ctx = invalid or ctx.ad = invalid
return adInfo
end if
adInfo = {
adIndex: ctx.adIndex
adId: "ADID_unknown"
adPosition: -1
adDuration: -1
}
ad = ctx.ad
if ad.adid <> invalid
adInfo.adId = ad.adid
else if ad.title <> invalid
adInfo.adId = ad.title
else if ctx.adIndex <> invalid
adInfo.adId = "AD" + StrI(ctx.adIndex)
end if
if eventType = invalid
adInfo.adPosition = Int(ctx.time)
else
adInfo.adPosition = -1
end if
if ad.duration <> invalid
adInfo.adDuration = ad.duration
end if
vizbee_log("VERB", "VizbeeRAF::vizbee_raf_get_ad_info - adInfo=", adInfo)
return adInfo
end function

function vizbee_on_ssai_ad_callback_data(ssaiAdCallbackData as dynamic) as void
adapterType = ssaiAdCallbackData.adapterType
adEventData = ssaiAdCallbackData.adEventData
if adapterType = invalid or adEventData = invalid or vizbee_util().isStringAndValueNotEmpty(adEventData.eventType) = false
vizbee_log("WARN", "VizbeeSSAIAds::vizbee_on_ssai_ad_callback_data - MISSING adapterType or adEventData")
return
end if
vizbee_log("INFO", "VizbeeSSAIAds::vizbee_on_ssai_ad_callback_data adapterType=", adapterType)
vizbee_log("INFO", "VizbeeSSAIAds::vizbee_on_ssai_ad_callback_data adEvent=", adEventData)
if adapterType = "google_ima"
adInfo = getVizbeeAdInfoFromGoogleDAI(adEventData.data)
vizbee_log("INFO", "VizbeeSSAIAds::vizbee_on_ssai_ad_callback_data adInfo=", adInfo)
end if
	
adId = adInfo.adid
vizbee_log("INFO", "VizbeeSSAIAds::vizbee_on_ssai_ad_callback_data adId=" + adId)
if m.appProxy <> invalid and adId <> invalid
m.appProxy.UpdateStateForRAFAd(adId)
eventType = adEventData.eventType
if eventType = invalid
eventType = "Position"
end if
vizbee_log("INFO", "VizbeeSSAIAds::vizbee_on_ssai_ad_callback_data calling HandleAdEvent")
m.appProxy.syncController.HandleAdEvent(eventType, adId, adInfo.adduration, adInfo.adposition)
end if
end function
function getVizbeeAdInfoFromGoogleDAI(adObject as object) as object
adInfo = {}
if adObject = invalid or adObject.adid = invalid
return adInfo
end if
adIndex = 0
if adObject.adbreakinfo <> invalid and adObject.adbreakinfo.adposition <> invalid
adIndex = adObject.adbreakinfo.adposition
end if
adInfo = {
adIndex: adIndex
adId: adObject.adid
adPosition: adObject.currenttime
adDuration: adObject.duration
additionalInfo: {
adSystem: adObject.adsystem
adTitle: adObject.adtitle
adName: adObject.advertisername
adCompanions: adObject.companions
universalAdidRegistry: adObject.universaladidregistry
universalAdidValue: adObject.universaladidvalue
}
}
vizbee_log("VERB", "VizbeeSSAIAds::getVizbeeAdInfoFromGoogleDAI - adInfo=", adInfo)
return adInfo
end function