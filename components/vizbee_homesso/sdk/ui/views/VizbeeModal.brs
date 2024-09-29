' This component is used to show a modal with title, description and icon
' The modal must have either title or message or both
' Configurable options
'   title               - string
'   desc                - string
'   titleTextColor      - hexCode
'   descTextColor       - hexCode
'   titleTextFontSize   - integer
'   descTextFontSize    - integer
'   bgColor             - hexCode
'   borderColor         - hexCode
'   iconUrl             - string
'   isProgressIcon      - boolean

sub init()
    m.vizbeeModalOuterNode = m.top.findNode("vizbeeModalOuterNode")
    m.vizbeeModalInnerNode = m.top.findNode("vizbeeModalInnerNode")
    m.modalTextContainer = m.top.findNode("modalTextContainer")
    m.vizbeeModalMainContainer = m.top.findNode("vizbeeModalMainContainer")

    m.titleTextNode = m.top.findNode("titleTextNode")
    m.descTextNode = m.top.findNode("descTextNode")

    m.iconImage = m.top.findNode("iconImage")
    m.currentAnimationIconIndex = 0
    m.iconImageTimer = m.top.findNode("iconImageTimer")

    m.animationIconImage = m.top.findNode("animationIconImage")

    m.modalAnimation = m.top.findNode("modalAnimation")
    m.fieldInterpolator = m.top.findNode("fieldInterpolator")

    di = CreateObject("roDeviceInfo")
    m.screenWidth = di.GetDisplaySize().w
    m.screenHeight = di.GetDisplaySize().h
    m.screenRatio = m.screenWidth / 1280
end sub

'--------------------
' UI set up methods
'--------------------

function setOptions(options) as void
    
    if options = invalid then return
    
    isTitleAvailable = options.title <> invalid and options.title <> ""
    isDescAvailable = options.desc <> invalid and options.desc <> ""
    isIconAvailable = options.iconUrl <> invalid and options.iconUrl <> ""
    if isTitleAvailable = false and isDescAvailable = false then return

    ' NOTE: Always reset the text and size of the text nodes before setting the new values
    '      because the boundingRect() method is giving the old values if the text is not reset
    reset()

    ' default/static values
    defaultDimensionsForNodes = getDefaultDimensionsForNodes()
    defaultDimensionsForNodes.titleOrDescMaxWidth = updateTitleDescTextWidthFromOptions(options, defaultDimensionsForNodes)

    ' icon
    setIconImage(options, defaultDimensionsForNodes)

    defaultDimensionsForNodes.modalTextContainerLeftPadding = updateTextContainerLeftPadding(options, defaultDimensionsForNodes)
    m.modalTextContainer.translation = [m.iconImage.width + defaultDimensionsForNodes.modalTextContainerLeftPadding, 0]

    ' title
    setTitleText(options, isTitleAvailable, isDescAvailable, defaultDimensionsForNodes)

    ' desc
    setDescText(options, isTitleAvailable, isDescAvailable, defaultDimensionsForNodes)

    m.vizbeeModalMainContainer.translation = [defaultDimensionsForNodes.containerLefttPadding, defaultDimensionsForNodes.containerTopPadding]

    ' rectangle with title + desc + icon
    setModalInnerNode(options, defaultDimensionsForNodes, isTitleAvailable, isDescAvailable)

    ' rectangle with border
    setModalOuterNode(options, defaultDimensionsForNodes)

    ' set icon position vertically middle after modal size is set
    updateIconPosition(options, defaultDimensionsForNodes)

    ' animation
    if isModalAnimationAvailable() = false or m.fieldInterpolator = invalid then return
    m.modalAnimation.duration = 0.5

    modalRightMargin = defaultDimensionsForNodes.modalRightMargin
    if options.marginRight <> invalid and options.marginRight > 0 then
        modalRightMargin = options.marginRight
    end if
    modalBottomMargin = defaultDimensionsForNodes.modalBottomMargin
    if options.marginBottom <> invalid and options.marginBottom > 0 then
        modalBottomMargin = options.marginBottom
    end if

    m.fieldInterpolator.keyValue = [ [(m.screenWidth - (m.vizbeeModalOuterNode.width + modalRightMargin)), m.screenHeight], [(m.screenWidth - (m.vizbeeModalOuterNode.width + modalRightMargin)), (m.screenHeight -(m.vizbeeModalOuterNode.height + modalBottomMargin))]]
end function

function show() as void
    if isModalAnimationAvailable() = true then
        m.modalAnimation.control = "start"
    end if

    if isModalNodeAvailable() = false then return
    m.vizbeeModalOuterNode.visible = true
    m.vizbeeModalOuterNode.opacity = 1
end function

function hide() as void
    if isModalNodeAvailable() = false then return

    m.iconImageTimer.UnobserveField("fire")
    m.iconImageTimer.control = "stop"
    m.vizbeeModalOuterNode.visible = false
    m.vizbeeModalOuterNode.opacity = 0
end function

'-------------------
' Private methods
'-------------------

function isModalNodeAvailable() as boolean
    return m.vizbeeModalOuterNode <> invalid
end function

function isModalAnimationAvailable() as boolean
    return m.modalAnimation <> invalid
end function

function getDefaultDimensionsForNodes() as object
    return {
        modalRightMargin: 40 * m.screenRatio
        modalBottomMargin: 40 * m.screenRatio
        
        containerTopPadding: 20 * m.screenRatio
        containerRightPadding: 20 * m.screenRatio
        containerBottomPadding: 20 * m.screenRatio
        containerLefttPadding: 20 * m.screenRatio
        containerBorderRadius: 2 * m.screenRatio

        iconWidth: 28 * m.screenRatio ' this is different from height because the icon is not square
        iconHeight: 24 * m.screenRatio

        modalTextContainerLeftPadding: 12 * m.screenRatio
        ' 33% minus (modalRightMargin + containerLefttPadding + containerRightPadding + iconWidth + modalTextContainerLeftPadding)
        titleOrDescMaxWidth: ((35/100) * 1280 * m.screenRatio) - (20 * m.screenRatio) - (2 * 20 * m.screenRatio) - (36 * m.screenRatio) - (12 * m.screenRatio)
        descTopPadding: 4 * m.screenRatio
        titleTextFontSize: 24 * m.screenRatio
        descTextFontSize: 20 * m.screenRatio
    }
end function

function updateTitleDescTextWidthFromOptions(options as object, defaultDimensionsForNodes as object) as integer
    titleOrDescMaxWidth = defaultDimensionsForNodes.titleOrDescMaxWidth
    if options.width <> invalid and options.width > 0 then
        titleOrDescMaxWidth = options.width - (defaultDimensionsForNodes.containerLefttPadding + m.iconImage.width + defaultDimensionsForNodes.modalTextContainerLeftPadding + defaultDimensionsForNodes.containerRightPadding)
    end if
    return titleOrDescMaxWidth
end function

function updateTextContainerLeftPadding(options as Object, defaultDimensionsForNodes as Object) as integer
    modalTextContainerLeftPadding = defaultDimensionsForNodes.modalTextContainerLeftPadding
    if options.iconMarginRight <> invalid and options.iconMarginRight > 0 then
        modalTextContainerLeftPadding = options.iconMarginRight
    end if
    return modalTextContainerLeftPadding
end function

function setIconImage(options as object, defaultDimensionsForNodes as object) as void

    m.iconImage.width = defaultDimensionsForNodes.iconWidth
    if options.iconWidth <> invalid and options.iconWidth > 0 then
        m.iconImage.width = options.iconWidth
    end if

    m.iconImage.height = defaultDimensionsForNodes.iconHeight
    if options.iconHeight <> invalid and options.iconHeight > 0 then
        m.iconImage.height = options.iconHeight
    end if

    if options.iconUrl <> invalid and options.iconUrl <> "" then
        m.iconImage.uri = options.iconUrl
    end if
    m.iconImage.visible = true

    if options.isProgressIcon = true then
        showConnectingAnimation()
    end if
end function

function setTitleText(options as object, isTitleAvailable as boolean, isDescAvailable as boolean, defaultDimensionsForNodes as object) as void

    if m.titleTextNode <> invalid and isTitleAvailable then

        m.titleTextNode.text = options.title

        if options.titleFontUri <> invalid and options.titleFontUri <> "" then
            m.titleTextNode.font.uri = options.titleFontUri
        end if
        m.titleTextNode.font.size = defaultDimensionsForNodes.titleTextFontSize
        if options.titleTextFontSize <> invalid and options.titleTextFontSize > 0 then
            m.titleTextNode.font.size = options.titleTextFontSize
        end if

        m.titleTextNode.width = m.titleTextNode.boundingRect().width
        if m.titleTextNode.boundingRect().width > defaultDimensionsForNodes.titleOrDescMaxWidth then
            m.titleTextNode.width = defaultDimensionsForNodes.titleOrDescMaxWidth
        end if

        m.titleTextNode.height = m.titleTextNode.boundingRect().height
        if options.titleTextColor <> invalid and options.titleTextColor <> "" then
            m.titleTextNode.color = options.titleTextColor
        end if
        m.titleTextNode.translation = [0, 0]
        if isDescAvailable <> true then
            m.titleTextNode.translation = [0, (m.iconImage.height - m.titleTextNode.height) / 2]
        end if
    end if
end function

function setDescText(options as object, isTitleAvailable as boolean, isDescAvailable as boolean, defaultDimensionsForNodes as object) as void

    if m.descTextNode <> invalid and isDescAvailable then

        m.descTextNode.text = options.desc
        
        if options.descFontUri <> invalid and options.descFontUri <> "" then
            m.descTextNode.font.uri = options.descFontUri
        end if
        m.descTextNode.font.size = defaultDimensionsForNodes.descTextFontSize
        if options.descTextFontSize <> invalid and options.descTextFontSize > 0 then
            m.descTextNode.font.size = options.descTextFontSize
        end if
        
        m.descTextNode.width = m.descTextNode.boundingRect().width
        if m.descTextNode.boundingRect().width > defaultDimensionsForNodes.titleOrDescMaxWidth then
            m.descTextNode.width = defaultDimensionsForNodes.titleOrDescMaxWidth
        end if
        
        m.descTextNode.height = m.descTextNode.boundingRect().height
        
        if isTitleAvailable then
            m.descTextNode.translation = [0, defaultDimensionsForNodes.descTopPadding + m.titleTextNode.boundingRect().height]
        else
            m.descTextNode.translation = [0, 0]
        end if
        
        if options.descTextColor <> invalid and options.descTextColor <> "" then
            m.descTextNode.color = options.descTextColor
        end if
    end if
end function

sub showConnectingAnimation()
    m.inputAnimationIcons = ["pkg:/components/vizbee_homesso/sdk/ui/assets/vzb_connection_progress_0.png", "pkg:/components/vizbee_homesso/sdk/ui/assets/vzb_connection_progress_1.png", "pkg:/components/vizbee_homesso/sdk/ui/assets/vzb_connection_progress_2.png", "pkg:/components/vizbee_homesso/sdk/ui/assets/vzb_connection_progress_1.png"]
    m.currentAnimationIconIndex = 0
    m.iconImageTimer.control = "start"
    m.iconImageTimer.ObserveField("fire","changeImage")
end sub

sub changeImage()
    m.currentAnimationIconIndex = m.currentAnimationIconIndex + 1
    if m.currentAnimationIconIndex = m.inputAnimationIcons.count() then
        m.currentAnimationIconIndex = 0
    end if
    m.iconImage.uri = m.inputAnimationIcons[m.currentAnimationIconIndex]
end sub

function setModalInnerNode(options as Object, defaultDimensionsForNodes as Object, isTitleAvailable as boolean, isDescAvailable as boolean) as void

    m.titleOrDescTextWidth = defaultDimensionsForNodes.titleOrDescMaxWidth
    if m.titleTextNode.width < m.descTextNode.width then
        m.titleOrDescTextWidth = m.descTextNode.width
    else
        m.titleOrDescTextWidth = m.titleTextNode.width
    end if

    descTopPadding = defaultDimensionsForNodes.descTopPadding
    if isTitleAvailable = false or isDescAvailable = false then
        descTopPadding = 0
    end if

    maxHeightOfIconAndTextContainer = m.titleTextNode.height + descTopPadding + m.descTextNode.height
    if m.iconImage.height > maxHeightOfIconAndTextContainer then
        maxHeightOfIconAndTextContainer = m.iconImage.height
    end if
    m.vizbeeModalInnerNode.width = defaultDimensionsForNodes.containerLefttPadding + m.iconImage.width + defaultDimensionsForNodes.modalTextContainerLeftPadding + m.titleOrDescTextWidth + defaultDimensionsForNodes.containerRightPadding - (2 * defaultDimensionsForNodes.containerBorderRadius)
    m.vizbeeModalInnerNode.height = defaultDimensionsForNodes.containerTopPadding + maxHeightOfIconAndTextContainer + defaultDimensionsForNodes.containerBottomPadding - (2 * defaultDimensionsForNodes.containerBorderRadius)
    m.vizbeeModalInnerNode.translation = [defaultDimensionsForNodes.containerBorderRadius, defaultDimensionsForNodes.containerBorderRadius]
end function

function setModalOuterNode(options as Object, defaultDimensionsForNodes as Object) as void

    m.vizbeeModalOuterNode.width = m.vizbeeModalInnerNode.width + (2 * defaultDimensionsForNodes.containerBorderRadius)
    m.vizbeeModalOuterNode.height = m.vizbeeModalInnerNode.height + (2 * defaultDimensionsForNodes.containerBorderRadius)
    m.vizbeeModalOuterNode.color = options.borderColor
end function

function updateIconPosition(options as Object, defaultDimensionsForNodes as Object) as void
    m.iconImage.translation = [0, 0]
end function

function reset() as void
    
    if m.titleTextNode <> invalid then
        m.titleTextNode.text = ""
        m.titleTextNode.width = 0
        m.titleTextNode.height = 0
    end if

    if m.descTextNode <> invalid then
        m.descTextNode.text = ""
        m.descTextNode.width = 0
        m.descTextNode.height = 0
        m.descTextNode.translation = [0, 0]
    end if

    m.titleOrDescTextWidth = 0
end function