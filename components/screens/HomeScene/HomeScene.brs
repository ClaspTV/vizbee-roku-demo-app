' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 ' inits grid screen
 ' creates all children
 ' sets all observers
Function Init()
    ' listen on port 8089
    ? "[HomeScene] Init"

    'main grid screen node
    m.GridScreen = m.top.findNode("GridScreen")

    'video player node
    m.videoPlayer = m.top.findNode("videoPlayer")

    ' loading indicator starts at initializatio of channel
    m.loadingIndicator = m.top.findNode("loadingIndicator")


    ' -----------------------------------------------------------------------
    ' Vizbee SDK init:
    ' Make sure that sdk init params and videoPlayer is available to the SDK
    ' -----------------------------------------------------------------------
    VizbeeClient().initVizbeeWithLaunchArgs(m.global.launchParams)
    VizbeeClient().startVideoNodeMonitor(m.videoPlayer)
End Function

' if content set, focus on GridScreen
Sub OnChangeContent()
    ? "OnChangeContent "
    m.GridScreen.setFocus(true)
    m.loadingIndicator.control = "stop"
End Sub

' Main Remote keypress event loop
Function OnkeyEvent(key, press) as Boolean
    ? ">>> HomeScene >> OnkeyEvent"
    result = false
    if press
        ? "key == ";key

        if key = "options"
            ' option key handler
        else if m.GridScreen.visible = false and key = "back"
            'hide vide player and stop playback if back button was pressed

            ? ">>> HomeScene >> OnKeyEvent>> Stopping video and changinging screens"

            m.videoPlayer.visible = false
            m.videoPlayer.control = "stop"
            m.GridScreen.visible = true
            m.GridScreen.setFocus(true)
            result = true
        end if
    end if

    return result
End Function
