sub init()
    m.vizbeeModal = m.top.getScene().findNode("VizbeeModal")
end sub

'--------------------
' UI set up methods
'--------------------

function setOptions(options) as void
    if options = invalid then 
        return
    end if

    if isVizbeeModalAvailable() = false then
        return
    end if

    m.vizbeeModal.callFunc("setOptions", options)
end function

function show(ttlInSec=10 as integer) as void
    ? "VizbeeModalManager::show"
    if isVizbeeModalAvailable() = false then
        return
    end if
    m.vizbeeModal.callFunc("show")
    startModalTimer(ttlInSec)
end function

function hide() as void
    ? "VizbeeModalManager::hide"
    if isVizbeeModalAvailable() = false then
        return
    end if
    m.vizbeeModal.callFunc("hide")
    stopModalTimer()
end function

'-------------------
' Private methods
'-------------------

sub startModalTimer(ttlInSec as integer) as void
    ? "VizbeeModalManager::startModalTimer"

    m.modalTimer = m.top.createChild("Timer")
    m.modalTimer.ObserveField("fire", "onModalTimerFire")
    m.modalTimer.duration = ttlInSec
    m.modalTimer.control = "start"
end sub

sub stopModalTimer() as void
    ? "VizbeeModalManager::stopModalTimer"
    if m.modalTimer = invalid then
        return
    end if
    m.modalTimer.control = "stop"
    m.modalTimer = invalid
end sub

sub onModalTimerFire()
    ? "VizbeeModalManager::onModalTimerFire"
    m.modalTimer = invalid
    hide()
end sub

function isVizbeeModalAvailable() as boolean
    return m.vizbeeModal <> invalid
end function