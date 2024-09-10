
Sub PlayContentWithRAFAds()

    adIface = Roku_Ads()
    adIface.setDebugOutput(true) 'for debug pupropse

    'RAF content params
    adIface.setContentId(m.videoPlayer.content.guid)
    adIface.setAdUrl("http://1c6e2.v.fwmrm.net/ad/g/1?nw=116450&ssnw=116450&asnw=116450&caid=493509699603&csid=fxn_shows_roku&prof=116450:Fox_Live_Roku&resp=vast&metr=1031&flag=+exvt+emcr+sltp&;_fw_ae=d8b58f7bfce28eefcc1cdd5b95c3b663;app_id=ROKU_ADS_APP_ID")

    '-------------------------------------
    'Vizbee Ad Integration
    '-------------------------------------
     adIface.setTrackingCallback(VZB().RAFCallback, VZB())

    'Returns available ad pod(s) scheduled for rendering or invalid, if none are available.
    adPods = adIface.getAds()

    playVideo = true
    'render pre-roll ads
    if adPods <> invalid and adPods.count() > 0 then
        playVideo = adIface.showAds(adPods)
    endif

    if playVideo then
        m.GridScreen.visible = false
        m.videoPlayer.visible = true
        m.videoPlayer.setFocus(true)
        m.videoPlayer.control = "play"
    else
        m.GridScreen.visible = true
        return
    end if

     while(true)
        msg = wait(100, m.port)

        '-------------------------------------
        'Vizbee Monitor Screen
        '-------------------------------------
        VZB().MonitorScreen(msg, m.port, "MainScreen", true)
        '-------------------------------------

        '-------------------------------------
        'Vizbee Monitor SGVideo
        '-------------------------------------
        VZB().MonitorSGVideo(m.videoPlayer)

        '? "AdScreen loop = ";msg

        msgType = type(msg)

        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then return

        else if msgType = "roSGNodeEvent"

           ? "AdScreen sg node = ";msg.GetField()

            if (msg.GetField() = "selectedVideoContent") then

                ? "AdScreen exiting because selected video content was reset"

                m.selectedVideoContentReset = true
                exit while

            else if (msg.GetNode() = "videoPlayer")

                if msg.GetField() = "position" then

                    'render mid-roll ads
                    curPos = m.videoPlayer.position
                    videoEvent = createPlayPosMsg(curPos)
                    adPods = adIface.getAds(videoEvent)
                    if adPods <> invalid and adPods.count() > 0
                        m.videoPlayer.control = "stop"
                        playVideo = adIface.showAds(adPods)
                        if playVideo then
                            m.videoPlayer.seek = curPos
                            m.videoPlayer.control = "play"
                        endif
                    endif

                else if msg.GetField() = "state" then
                        stopped = RAFOnVideoPlayerStateChange()
                        if stopped
                             ? "Exiting RAF loop"
                            exit while
                        end if

                else if msg.GetField() = "navBack" then
                    'back button handling
                     ? ">>> RAF AdPlayback >> BackEvent"

                 '   if msg.GetData() = true then
                  '      m.videoPlayer.control = "stop"
                   '     exit while
                    'endif
                end if

            end if

        end if
    end while

End Sub

function RAFOnVideoPlayerStateChange() as Boolean

    ? "RAFVideoPlayer > OnVideoPlayerStateChange : state == ";m.videoPlayer.state

    if m.videoPlayer.state = "error"
        'hide vide player in case of error
        m.videoPlayer.visible = false
        m.GridScreen.visible = true
        m.GridScreen.setFocus(true)
        return true
    'else if m.videoPlayer.state = "finished"
        'hide vide player if video is finished
        'm.videoPlayer.visible = false
        'm.GridScreen.visible = true
        'm.GridScreen.setFocus(true)
        'return true
    else if m.videoPlayer.state = "stopped"
        return true
    end if

    return false
end function

'Video events handling.
'@param position [Integer] video position.
'@param completed [Boolean] flag if video is completed
'@param started [Boolean] flag if video is started
'@return [AA] object of video event in structured format.
function createPlayPosMsg(position as Integer, completed = false as Boolean, started = false as Boolean) as Object
    videoEvent = { pos: position,
                   done: completed,
                   started: started,
                   isStreamStarted : function () as Boolean
                                           return m.started
                                       end function,
                   isFullResult : function () as Boolean
                                      return m.done
                                  end function,
                   isPlaybackPosition : function () as Boolean
                                            return true
                                        end function,
                   isStatusMessage : function () as Boolean
                                        return (m.done or m.started)
                                     end function,
                   getIndex : function () as Integer
                                  return m.pos
                              end function,
                   getMessage : function () as String
                                    result = ""
                                    if m.done
                                        result = "end of stream"
                                    else if m.started
                                        result = "start of play"
                                    end if
                                    return result
                                end function
                 }
    return videoEvent
end function
