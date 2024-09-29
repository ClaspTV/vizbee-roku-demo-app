' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 ' inits grid screen
 ' creates all children
 ' sets all observers
function Init()

    ' listen on port 8089
    ? "[HomeScene] Init"

    m.scene = m.top.getScene()

    'menu node
    m.appMenu = m.top.findNode("menu")
    
    'main grid screen node
    m.GridScreen = m.top.findNode("GridScreen")

    'video player node
    m.videoPlayer = m.top.findNode("videoPlayer")

    'regcode screen node
    m.regcodeScreen = m.top.findNode("regcodeScreen")
    
    ' loading indicator starts at initializatio of channel
    m.loadingIndicator = m.top.findNode("loadingIndicator")

    m.top.observeField("currentViewFocused", "OnCurrentViewFocused")
    m.top.currentViewFocused = Constants().Views.GRID

    m.networkHttpTask = createObject("roSGNode", "NetworkHttpTask")

    m.registrySection = CreateObject("roRegistrySection", "VizbeeSampleApp")
    m.userInfo = getUserInfoFromRegistry()
    ? "HomeScene::Init - userInfo=";m.userInfo

    m.top.observeField("signInState", "OnSignInStateChange")
    m.top.observeField("regcode", "OnRegcodeChange")

    ' Vizbee SDK init
    initVizbeeContinuity()
    initVizbeeHomeSSO()
End function

sub initVizbeeContinuity()
    ' Vizbee SDK init
    ' make sure that sdk init params and videoPlayer is available to the SDK
    VizbeeClient().initVizbeeWithLaunchArgs(m.global.launchParams)
end sub

sub initVizbeeHomeSSO()

    vizbeeModalPreferences = CreateObject("roSGNode", "VizbeeModalPreferences")

    ' sign in informational modal options
    informationalPreference = CreateObject("roSGNode", "VizbeeInformationalModalPreference")
    informationalPreference.enable = true
    vizbeeModalPreferences.informationalPreference = informationalPreference

    ' sign in progress modal options
    progressPreference = CreateObject("roSGNode", "VizbeeProgressModalPreference")
    progressPreference.enable = true
    vizbeeModalPreferences.progressPreference = progressPreference

    ' sign in complete modal options
    successPreference = CreateObject("roSGNode", "VizbeeSuccessModalPreference")
    successPreference.enable = true
    vizbeeModalPreferences.successPreference = successPreference
    
    VizbeeHomeSSOClient().init(vizbeeModalPreferences)
end sub

' if content set, focus on GridScreen
Sub OnChangeContent()
    ? "OnChangeContent "
    m.loadingIndicator.control = "stop"
    
    m.top.currentViewFocused = Constants().Views.GRID
    m.GridScreen.visible = true
    m.GridScreen.setFocus(true)
End Sub

' Main Remote keypress event loop
function OnkeyEvent(key, press) as Boolean
    result = false
    if press = true
        key = LCase(key)
        ? "HomeScene::OnkeyEvent - key=";key
        if m.top.currentViewFocused = Constants().Views.MENU then
            ? "HomeScene::OnkeyEvent - ignoring key event as Menu is focused"
            return false
        end if

        if key = "left"
            ' set focus on menu and expand menu
            ? "HomeScene::OnkeyEvent - Showing app menu"
            m.top.currentViewFocused = Constants().Views.MENU
            m.appMenu.currentIndex = 0
            m.appMenu.visible = true
            m.appMenu.setFocus(true)
            result = true
        else if key = "back"

            if VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_IN_PROGRESS = m.top.signInState
                ? "HomeScene::OnkeyEvent - ignoring key event as regcode is visible"
                m.top.pollingExited = true
            else if m.videoPlayer.visible = true then
                'hide vide player and stop playback if back button was pressed
                ? "HomeScene::OnkeyEvent - Stopping video and showing grid screen"
                hideVideoScreenAndShowGridScreen()
            end if
            result = true

        end if
    end if
    return result
End function

function OnCurrentViewFocused()
    ? "HomeScene::OnCurrentViewFocused - currentViewFocused=";m.top.currentViewFocused
    if m.top.currentViewFocused = Constants().Views.MENU then
        m.appMenu.visible = true
        m.appMenu.setFocus(true)
        m.appMenu.callFunc("itemHasFocus", 0, true)
    else if m.top.currentViewFocused = Constants().Views.GRID then
        m.appMenu.visible = true
        m.GridScreen.setFocus(true)
    else if m.top.currentViewFocused = Constants().Views.VIDEO then
        m.appMenu.visible = false
    end if
End function

function isVideoPlaying() as boolean
    return m.videoPlayer.visible
end function

'-------------------
' Profile Handlers
'-------------------

function hideVideoScreenAndShowGridScreen() as void
    m.videoPlayer.visible = false
    m.videoPlayer.control = "stop"
    m.top.currentViewFocused = Constants().Views.GRID
    m.GridScreen.visible = true
    m.GridScreen.setFocus(true)
end function

function hideRegcodeScreenAndShowGridScreen() as void
    m.regcodeScreen.visible = false
    m.top.currentViewFocused = Constants().Views.GRID
    m.GridScreen.visible = true
    m.GridScreen.setFocus(true)
end function

function hideGridScreenAndShowRegcodeScreen() as void
    m.GridScreen.visible = false
    m.regcodeScreen.visible = true
end function

function OnSignInStateChange(signInStateChangeEvent as object) as void
    signInState = signInStateChangeEvent.getData()
    if VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_IN_PROGRESS = signInState then
        ? "HomeScene::OnSignInStateChange - Sign in in progress"
        if m.top.currentViewFocused = "grid" or m.top.currentViewFocused = "menu"
            hideGridScreenAndShowRegcodeScreen()
        end if
        m.GridScreen.visible = false
    else if VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_COMPLETED = signInState or VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_CANCELLED = signInState then
        ? "HomeScene::OnSignInStateChange - Sign in completed/cancelled"
        if m.videoPlayer.visible <> true
            hideRegcodeScreenAndShowGridScreen()
        end if        
    end if
end function

function OnRegcodeChange(regcodeEvent as object) as void
    regcode = regcodeEvent.getData()
    ? "HomeScene::OnRegcodeChange - regcode=";regcode
    m.regcodeScreen.regcode = regcode
end function

function isUserSignedIn() as boolean
    if m.userInfo <> invalid and m.userInfo.email <> invalid and m.userInfo.authToken <> invalid
        return true
    end if
    return false
end function

function updateUserDetails(userInfo as dynamic) as void
    setUserInfoFromRegistry(userInfo)
end function

function signoutUser() as void
    if m.userInfo =invalid or m.userInfo.authToken = invalid then
        ? "HomeScene::signoutUser - User not signed in"
        return
    end if
    m.networkHttpTask.observeField("response", "onSignoutUserResponse")
    m.networkHttpTask.request = { method: "POST", uri: "https://homesso.vizbee.tv/v1/signout", payload: {}, headers: { "Authorization": m.userInfo.authToken} }
    m.networkHttpTask.control = "RUN"
end function

function onSignoutUserResponse(signoutEvent) as void
    m.networkHttpTask.unobserveField("response")
    m.networkHttpTask.control = "STOP"
    signoutResp = signoutEvent.getData()
    ' TODO: handle signout response
    updateUserDetails(invalid)
    ' showSignoutToast()
end function

function showProfileDialog()
    if isUserSignedIn() = true then
        ' user already signed in
        buttons = [ "Signout", "Cancel" ]
        message = ["You are signed in as " + m.userInfo.email + "."]
    else
        ' user not signed in
        buttons = [ "Close" ]
        message = ["You are currently not signed in, please use mobile app to signin in to the account."]
    end if
    dialog = createObject("roSGNode", "StandardMessageDialog")
    dialog.title = "Profile Details"
    dialog.buttons = buttons
    dialog.message = message
    m.top.dialog = dialog

    ' observe the dialog's buttonSelected field to handle button selections
    m.top.dialog.observeFieldScoped("buttonSelected", "onProfileDialogButtonSelected")
    m.top.dialog.observeFieldScoped("wasClosed", "onProfileDialogWasClosed")
End function

function onProfileDialogButtonSelected() as boolean
    if m.top.dialog.buttons[m.top.dialog.buttonSelected] = "Signout" and isUserSignedIn() = true
        ' sign out
        ? "HomeScene::onProfileDialogButtonSelected - Signout"
        signoutUser()
    end if
    m.top.dialog.close = true
    return true
end function

function onProfileDialogWasClosed() as void
    m.top.dialog.unobserveField("buttonSelected")
    m.top.dialog.unobserveField("wasClosed")
    
    ' go to home screen
    m.appMenu.currentIndex = 0
    m.appMenu.callFunc("handleSelectedMenu")
End function

function showSignoutToast()
    vizbeeSignoutOptions = getDefaultOptionsForSignout()
    vizbeeModalManager = CreateObject("roSGNode", "VizbeeModalManager")
    vizbeeModalManager.callFunc("setOptions", vizbeeSignoutOptions)
    vizbeeModalManager.callFunc("show", 5)
end function

function getDefaultOptionsForSignout() as Object

    ? "HomeScene::getDefaultOptionsForSignout"

    defaultSignoutOptions = CreateObject("roSGNode", "VizbeeModalOptions")
    defaultSignoutOptions.desc = "You signed out successfully...!"
    defaultSignoutOptions.descTextColor = "0xFFFFFF"
    defaultSignoutOptions.bgColor = "0x1E1F21"
    defaultSignoutOptions.borderColor = "0x00000000"
    defaultSignoutOptions.iconUrl = "https://static.claspws.tv/images/screen/icons/common/success_checkmark_white.png"
    return defaultSignoutOptions
end function

'----------------------
' Registry Handlers
'----------------------

function getUserInfoFromRegistry() As Dynamic
     if m.registrySection.Exists("UserInfo")
         return ParseJson(m.registrySection.Read("UserInfo"))
     endif
     return invalid
End function

function setUserInfoFromRegistry(userInfo As Dynamic) As Void
    if userInfo = invalid
        ? "HomeScene::setUserInfoFromRegistry - clearing user info"
        m.registrySection.Delete("UserInfo")
        m.userInfo = invalid
        return
    end if
    ? "HomeScene::setUserInfoFromRegistry - setting user info"; userInfo
    m.registrySection.Write("UserInfo", FormatJson(userInfo))
    m.registrySection.Flush()
    m.userInfo = userInfo
End function