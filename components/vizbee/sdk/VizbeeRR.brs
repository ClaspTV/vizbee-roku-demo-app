'------------------------------------------
' Vizbee RR (Roku Remote)
'-------------------------------------------

function vizbee_rr_controller() as object
    
    return {
        Send: vizbee_rr_controller_send
    }
end function

' handle commands by triggering button presses via remote interface
function vizbee_rr_controller_send(key as string) as boolean

    if key = ""
        return false
    end if

    controlPort = vizbee_rr_config_helper().GetControlPort()
    if controlPort = ""
        return false
    end if

    ipAddressInternal = vizbee_rr_config_helper().GetControlIP()
    if ipAddressInternal = ""
        return false
    end if

    url = "http://" + ipAddressInternal + ":" + controlPort + "/"
    request = createObject("roUrlTransfer")

    key = LCase(key)
    if (key = "play" or key = "pause")
        url = url + "keypress/Play"
    else if (key = "back")
        url = url + "keypress/Back"
    else if (key = "exit")
        url = url + "keypress/Home"
    else if (key = "ok")
        url = url + "keypress/Enter"
    else if (key = "wakeup")
        url = url + "keypress/Lit_z"
    end if

    ' in milliseconds
    timeout = 500
    response = false

    request.setUrl(url)
    ' @deprecated: Since Roku OS 11.5 (September 2022)
    ' request.EnableFreshConnection(true)
    request.SetPort(CreateObject("roMessagePort"))
    if (request.AsyncPostFromString(""))
        event = wait(timeout, request.GetPort())
        if (type(event) = "roUrlEvent")
            response = true
            ' timeout
        else if (event = invalid)
            request.AsyncCancel()
        end if
    end if
    return response
end function