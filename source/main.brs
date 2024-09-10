library "Roku_Ads.brs"
sub RunUserInterface(args)

    m.screen = CreateObject("roSGScreen")

    ' --------------------------------------------------------
    ' make sure that launchParams are available to vizbee SDK
    ' --------------------------------------------------------
    m.global = m.screen.GetGlobalNode()
    m.global.addFields({ launchParams: args })

    m.scene = m.screen.CreateScene("HomeScene")
    m.port = CreateObject("roMessagePort")
    m.screen.SetMessagePort(m.port)
    m.screen.Show()

    m.GridScreen = m.scene.findNode("GridScreen")
    m.videoPlayer = m.scene.findNode("videoPlayer")

    'added handler on item selecting event in grid screen
    m.scene.observeField("rowItemSelected", m.port)
    m.scene.observeField("selectedVideoContent", m.port)
    m.selectedVideoContentReset = false

    m.getItem = GetItemByGUID
    m.playlist = GetPlaylistArray()
    list = [
        {
            Title: "Demo Videos"
            ContentList : m.playlist
        }
    ]
    m.scene.gridContent = ParsePlayList(list)

    ' ----------------------------------------------
    ' pass HomeScene and playlist to render thread
    ' ----------------------------------------------
    m.global.addFields({ scene: m.scene, playlist: m.playlist })

    while true
        msg = wait(100, m.port)

        if (m.selectedVideoContentReset) then
            m.selectedVideoContentReset = false
            OnChangeSelectedVideoContent()
        end if

        msgType = type(msg)
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then
                return
            end if
        else if msgType = "roSGNodeEvent"
            if (msg.GetField() = "rowItemSelected") then
                OnRowItemSelected()
            else if (msg.GetField() = "selectedVideoContent") then
                m.selectedVideoContentReset = false
                OnChangeSelectedVideoContent()
            else if (msg.GetField() = "state") then
                OnVideoPlayerStateChange()
            end if
        end if

    end while

    if m.screen <> invalid then
        m.screen.Close()
        m.screen = invalid
    end if
end sub

sub OnVideoPlayerStateChange()
    ? "HomeScene > OnVideoPlayerStateChange : state == ";m.videoPlayer.state

    if m.videoPlayer.state = "error"
        'hide vide player in case of error
        m.videoPlayer.visible = false
        m.GridScreen.visible = true
        m.GridScreen.setFocus(true)
    else if m.videoPlayer.state = "playing"
    else if m.videoPlayer.state = "finished"
        'hide vide player if video is finished
        m.videoPlayer.visible = false
        m.GridScreen.visible = true
        m.GridScreen.setFocus(true)
    end if
end sub

' Row item selected handler
sub OnRowItemSelected()
    ? "[HomeScene] OnRowItemSelected"

    selectedItem = m.GridScreen.focusedContent

    m.videoPlayer.content = selectedItem
    m.videoPlayer.observeField("state", m.port)

    PlayContent()
end sub

sub OnChangeSelectedVideoContent()
    ? "OnChangeSelectedVideoContent "
    m.videoPlayer.content = m.scene.selectedVideoContent
    m.videoPlayer.observeField("state", m.port)

    PlayContent()
end sub

sub PlayContent()
    playAds = false
    if (playAds) then
        PlayContentWithRAFAds()
    else
        PlayContentWithoutAds()
    end if
end sub

sub PlayContentWithoutAds()
    m.GridScreen.visible = false
    m.videoPlayer.visible = true
    m.videoPlayer.setFocus(true)
    m.videoPlayer.control = "play"
end sub

' CMS Playlist etc

function ParsePlayList(list as object)
    RowItems = createObject("RoSGNode", "ContentNode")

    for each rowAA in list
        row = createObject("RoSGNode", "ContentNode")
        row.Title = rowAA.Title

        for each itemAA in rowAA.ContentList
            item = createObject("RoSGNode", "ContentNode")
            ' We don't use item.setFields(itemAA) as doesn't cast streamFormat to proper value
            for each key in itemAA
                item[key] = itemAA[key]
            end for
            row.appendChild(item)
        end for
        RowItems.appendChild(row)
    end for

    return RowItems
end function

function GetPlayListArray()

    result = []

    ' Create a playlist
    item1 = {}
    item1.stream = { url: "http://content.claspws.tv/pcfhls/Magma/master.m3u8" }
    item1.url = "http://content.claspws.tv/pcfhls/Magma/master.m3u8"
    item1.streamFormat = "hls"
    item1.HDPosterUrl = "https://designshack.net/wp-content/uploads/3-2.jpg"
    item1.hdBackgroundImageUrl = "https://designshack.net/wp-content/uploads/3-2.jpg"
    item1.title = "Documentary"
    item1.description = "HLS Video"
    item1.guid = "sintel"
    item1.id = "sintel"
    result.push(item1)

    item2 = {}
    item2.stream = { url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/big_buck_bunny_1080p.mp4" }
    item2.url = "https://commondatastorage.googleapis.com/gtv-videos-bucket/big_buck_bunny_1080p.mp4"
    item2.streamFormat = "mp4"
    item2.HDPosterUrl = "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Big_buck_bunny_poster_big.jpg/220px-Big_buck_bunny_poster_big.jpg"
    item2.hdBackgroundImageUrl = "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Big_buck_bunny_poster_big.jpg/220px-Big_buck_bunny_poster_big.jpg"
    item2.title = "Big Buck Bunny"
    item2.description = "MP4"
    item2.guid = "bigbuck"
    item2.id = "bigbuck"
    result.push(item2)

    item3 = {}
    item3.stream = { url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/hls/TearsOfSteel.m3u8" }
    item3.url = "https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/hls/TearsOfSteel.m3u8"
    item3.streamFormat = "hls"
    item3.HDPosterUrl = "https://designshack.net/wp-content/uploads/16-9.jpg"
    item3.hdBackgroundImageUrl = "https://designshack.net/wp-content/uploads/16-9.jpg"
    item3.title = "Random Movie"
    item3.description = "Kapoww"
    item3.guid = "tears"
    item3.id = "tears"
    result.push(item3)

    item4 = {}
    item4.stream = { url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/hls/ElephantsDream.m3u8" }
    item4.url = "https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/hls/ElephantsDream.m3u8"
    item4.streamFormat = "hls"
    item4.HDPosterUrl = "https://designshack.net/wp-content/uploads/1-1.jpg"
    item4.hdBackgroundImageUrl = "https://designshack.net/wp-content/uploads/1-1.jpg"
    item4.title = "Random Movie II"
    item4.description = "Fairy Tale"
    item4.guid = "elephants"
    item4.id = "elephants"
    result.push(item4)

    return result

end function

function GetItemByGUID(guid)

    for each item in m.playlist
        if (item.guid = guid) then
            return item
        end if
    end for

end function
