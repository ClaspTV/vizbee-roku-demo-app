sub init()
    'TODO: add doc blocs when menu is finalised
    m.background = m.top.findNode("background")
    m.backgroundSelected = m.top.findNode("backgroundSelected")
    m.poster = m.top.findNode("poster")
    ' m.posterSelected = m.top.findNode("posterSelected")
    ' m.posterFocused = m.top.findNode("posterFocused")
    m.label = m.top.findNode("label")
    ' m.label.opacity = 0.0
    m.active = m.top.findNode("active")
end sub

sub onWidth()
    m.background.width = m.top.width
end sub

sub onHeight()
    m.background.height = m.top.height
end sub

sub onColor()
    m.background.color = m.top.color
end sub

sub onImageUri()
    m.poster.uri = m.top.imageUri
end sub

sub onImageWidth()
    m.poster.loadWidth = m.top.imageWidth
end sub

sub onImageHeight()
    m.poster.loadHeight = m.top.imageHeight
end sub

sub onTextColor()
    ' m.label.color = m.top.textColor
end sub

sub onText()
    m.label = m.top.text
end sub

sub onImageTranslation()
    if  m.top.imageTranslation <> invalid
        m.poster.translation = m.top.imageTranslation
    end if
end sub

sub highlightIcon(selected as boolean)
    ' if selected
    '     if m.top.menuHasFocus
    '         m.poster.visible = false
    '         m.posterSelected.visible = false
    '         m.posterFocused.visible = true
    '     else
    '         m.poster.visible = false
    '         m.posterSelected.visible = true
    '         m.posterFocused.visible = false
    '         m.active.visible = true
    '     end if
    ' else
    '     m.poster.visible = true
    '     m.posterSelected.visible = false
    '     m.posterFocused.visible = false
    '     m.active.visible = false
    ' end if
end sub

sub resetMenuIcon()
    m.active.visible = false
    highlightIcon(false)
    m.background.color = m.top.itemContent.color
    m.label.color = m.top.itemContent.textColor
end sub

sub onContent()
    m.poster.translation = m.top.itemContent.imageTranslation
    m.poster.width = m.top.itemContent.imageWidth
    m.poster.height = m.top.itemContent.imageHeight
    m.poster.loadWidth = m.top.itemContent.imageWidth
    m.poster.loadHeight = m.top.itemContent.imageHeight
    m.poster.uri = m.top.itemContent.imageUri
    ' m.posterSelected.translation = m.top.itemContent.imageTranslation
    ' m.posterFocused.translation = m.top.itemContent.imageTranslation
    ' m.posterSelected.uri = m.top.itemContent.imageSelected
    ' m.posterFocused.uri = m.top.itemContent.imageFocused

    if m.top.itemContent.index = m.top.itemContent.default
        highlightIcon(true)
        m.active.visible = true
        m.top.itemHasFocus = true
    else
        highlightIcon(false)
    end if

    m.background.color = m.top.itemContent.color
    m.background.width = m.top.itemContent.width
    m.background.height = m.top.itemContent.height
    m.label.text = m.top.itemContent.text
    m.label.translation = m.top.itemContent.textTranslation
    m.label.font.size = m.top.itemContent.textSize
end sub

sub onMenuHasFocus()
    if m.top.menuHasFocus ' menu is expanded
        m.background.opacity = 1.0
        m.active.visible = false   
    else ' menu is closed
        m.background.opacity = 0.0
        if m.top.itemHasFocus
            m.active.visible = true
            highlightIcon(true)
        else
            highlightIcon(false)
        end if
    end if
end sub

sub onItemHasFocus()
  if m.top.itemHasFocus
    m.background.color = m.top.itemContent.focusedColor
    m.label.color = m.top.itemContent.textFocusedColor
    highlightIcon(true)
  else
    if m.top.menuHasFocus
      m.background.color = m.top.itemContent.color
      m.label.color = m.top.itemContent.textColor
      highlightIcon(false)
    end if
  end if
end sub

sub onItemSelected()
    if m.top.itemIsSelected
        m.backgroundSelected.visible = true
    else
        m.backgroundSelected.visible = false
    end if
  end sub
