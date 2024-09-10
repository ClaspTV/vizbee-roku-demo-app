'------------------------------------------
' Vizbee RR (Roku Remote) Config Helper
'-------------------------------------------

function vizbee_rr_config_helper() as object

    return {
        IsRREnabled: vizbee_rr_config_helper_is_enabled
        GetControlIP: vizbee_rr_config_helper_get_control_ip
        GetControlPort: vizbee_rr_config_helper_get_control_port
    }
end function

function vizbee_rr_config_helper_is_enabled() as boolean

    rrConfig = vizbee_rr_config_helper_get_config().rrInfo
    if rrConfig = invalid or rrConfig.isEnabled = invalid
        return false
    end if

    return rrConfig.isEnabled
end function

function vizbee_rr_config_helper_get_control_ip() as string
    internalIpAddress = vizbee_rr_config_helper_get_config().internalIpAddress
    if internalIpAddress = invalid
        return ""
    end if

    return internalIpAddress
end function

function vizbee_rr_config_helper_get_control_port() as string

    rrConfig = vizbee_rr_config_helper_get_config().rrInfo
    if rrConfig = invalid or rrConfig.controlPort = invalid
        return ""
    end if

    return rrConfig.controlPort.toStr()
end function

function vizbee_rr_config_helper_get_config() as object

    vizbeeConfig = GetGlobalAA().Lookup("VizbeeConfig")

    if vizbeeConfig = invalid AND m.global <> invalid
        vizbeeConfig = m.global.VizbeeConfig
    end if

    if vizbeeConfig = invalid
        vizbeeConfig = {}
    end if

    return vizbeeConfig
end function