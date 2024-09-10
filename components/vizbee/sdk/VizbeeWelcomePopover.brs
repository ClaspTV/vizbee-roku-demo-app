sub init()

    'NODES
    m.welcomeNode = m.top.FindNode("welcomeNode")
    m.bgNode = m.top.FindNode("Bg")
    m.textNode = m.top.FindNode("TextNode")
    m.bgBmp = m.top.FindNode("BgBmp")
    m.iconImage = m.top.findNode("iconImage")
    m.buttonLabel = m.top.findNode("ButtonLabel")
    m.animation= m.top.findNode("fadeInAnimation")

    'EVENT LISTENERS
    m.animation.observeField("state", "animationStateChange")

    'DISPLAY POLICY
    m.displayPolicies = {
        "ONCE": "once",
        "ALWAYS": "always"
    }
    m.isPopoverDisplayed = false

    applyDefaultStyles()
end sub

'------------
' Public API
'------------

sub show(username as string, prefix = "Welcome " as string)

    ' check for display policy
    if shouldShowPopover()

        showUsername(username, prefix)
        setNonBmpValues()
        layoutImages()
        calculateAndSetDimensions()
    end if
end sub

'--------------
' UI Functions
'--------------

function shouldShowPopover() as boolean

    displayPolicy = m.top.displayPolicy
    if (displayPolicy = m.displayPolicies.ONCE AND NOT m.isPopoverDisplayed) or  displayPolicy = m.displayPolicies.ALWAYS
        
        m.isPopoverDisplayed = true
        return true
    end if
    return false
end function

sub showUsername(username as string, prefix as string)

    if NOT username = ""

        m.textNode.text = prefix + username

        m.welcomeNode.visible = true
        m.animation.control = "start"
    end if
end sub

sub setNonBmpValues()

    m.bgNode.color = m.top.backgroundColor
    m.textNode.font = m.top.textFont
    m.textNode.color = m.top.textColor
    m.iconImage.uri = m.top.iconUri
    m.animation.duration = m.top.animationDuration
end sub

sub layoutImages()

    backgroundBitmapUri = m.top.backgroundBitmapUri
    if(IsValid(backgroundBitmapUri) AND len(backgroundBitmapUri) > 0)

        m.bgBmp.Uri = backgroundBitmapUri
        m.bgBmp.visible = true
    end if
end sub

sub calculateAndSetDimensions()

    ' We need to reset width to 0 on the text node for the initial auto sizing
    m.textNode.width = 0
    textBounds = m.textNode.boundingRect()
    baseWidth = textBounds.width
    baseHeight = textBounds.height
    heightOverride = 0

    if(m.top.hasField("height") AND m.top.height > 0)
        heightOverride = m.top.height
    end if

    ' this handles maxWidth setting
    maxWidth = m.top.maxWidth
    if(maxWidth > 0 AND maxWidth <= baseWidth)
        baseWidth = maxWidth
    endif

    ' TODO: This needs simplifying
    ' this handled minWidth setting
    minWidth = m.top.minWidth
    if(maxWidth > 0)
        ' if maxWidth was set, minWidth must be less than that to relevant
        if(minWidth < maxWidth)
            if(minWidth > 0 AND minWidth >= baseWidth)
                baseWidth = minWidth
            endif
        endif
    else
        if(minWidth > 0 AND minWidth >= baseWidth)
            baseWidth = minWidth
        end if
    end if
    padding = m.top.padding
    if isValid(m.iconImage) AND isValid(m.iconImage.uri) AND m.iconImage.uri <> ""
        if Len(m.textNode.text) < 10
            m.baseTotalWidth = baseWidth + (padding[1] + padding[3])
            m.textNode.translation = [padding[3], padding[0]]
            m.iconImage.translation = [25, 19]
            m.textNode.horizAlign = m.top.horizAlign
        else
            iconWidth = cint(m.iconImage.boundingRect().width * 0.5) + 5
            m.baseTotalWidth = baseWidth + (padding[1] + padding[3]) + iconWidth
            m.textNode.translation = [iconWidth + padding[3], padding[0]]
            m.iconImage.translation = [25, 19]
            m.textNode.horizAlign = m.top.horizAlign
        end if
    else
        m.baseTotalWidth = baseWidth + (padding[1] + padding[3])
        m.textNode.translation = [padding[3], padding[0]]
        m.textNode.horizAlign = m.top.horizAlign
    end if

    if(heightOverride > 0)
        m.baseTotalHeight = heightOverride
    else
        if(m.top.minHeight > 0)
            m.baseTotalHeight = m.top.minHeight
        else
            m.baseTotalHeight = baseHeight + (padding[0] + padding[2])
        end if
    end if

    ' adjusting for minHeight if no height value was set
    if(heightOverride = 0 AND m.top.minHeight > 0)
        m.baseTotalHeight = m.top.minHeight
    end if


    m.textNode.vertAlign = m.top.vertAlign
    
    m.bgNode.height = m.baseTotalHeight
    m.bgNode.width = m.baseTotalWidth
    m.textNode.width = m.bgNode.width - padding[1] - padding[3]
    m.textNode.height = m.bgNode.height - padding[0] - padding[2]

    bgBounds = m.bgNode.boundingRect()
    m.bgBmp.width = bgBounds.width
    m.bgBmp.height = bgBounds.height

    m.top.translation = [m.top.nodeTranslation[0] + (maxWidth - m.bgBmp.width), m.top.nodeTranslation[1]]
end sub

sub applyDefaultStyles()
    
    m.top.textFont.size = 28
    m.top.setFields({
        textColor: "0xFFFFFFFF"
    
        height: 70
        minWidth: 170
        maxWidth: 400
        padding: [15,30,15,30]
    
        backgroundColor: "0x00000000"
        backgroundBitmapUri: "https://static.claspws.tv/screen/icons/roku/20White9Slice.9.png"
        
        iconUri: "https://static.claspws.tv/screen/icons/common/user_icon_white.png" 
    })
end sub

sub animationStateChange()

    if m.animation.state = "stopped"
        m.welcomeNode.visible = false
    end if
end sub

'-----------------
' Helper Functions
'-----------------

function isInvalid(value as dynamic) as boolean
    return value = invalid or type(value) = "<uninitialized>"
end function

function isValid(value as dynamic) as boolean
    return NOT IsInvalid(value)
end function

function isString(value as dynamic) as boolean
    return type(value) = "roString" OR type(value) = "String"
end function

function capitalize(str as String) as String

    if str.Len() > 0
        return UCase(str.Left(1)) + str.Right(str.Len() - 1)
    end if
    return str
end function
