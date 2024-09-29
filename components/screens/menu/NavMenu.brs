sub init()
  ? "NavMenu::init"
  m.menu = m.top.findNode("menu")
  m.buttonList = m.top.findNode("buttonList")
  m.separator = m.top.findNode("separator")
  m.background = m.top.findNode("background")
  loadMenuConfig()
  m.lastSelectedItem = "HomeScreen"
  m.lastSelectedId = 0
  menuHasFocus(true)
  itemSelected(0)
  m.mainContainer = m.top.getScene() 'TODO: rename mainContainer to screenContainer or ...
end sub

sub loadMenuConfig()
  ? "NavMenu::loadMenuConfig"
  jsonAsString = ReadAsciiFile("pkg:/components/screens/Menu/mainMenuConfig.json")
  data = ParseJSON(jsonAsString)
  m.top.config = data
end sub

sub onMainMenuConfig(msg as object)
  ? "NavMenu: onMainMenuConfig"
  model = getMainMenuConfig(msg.getData())
  ? "NavMenu: onMainMenuConfig:: model, - "; model.labels
  m.model = model
  m.icons = model.icons
  m.names = model.names
  m.iconsFocused = model.iconsFocused
  m.iconsSelected = model.iconsSelected
  m.labels = model.labels

  ' m.logo =  createObject("RoSGNode", "MenuItem")
  ' ? "NavMenu: onMainMenuConfig:: model.logo, - "; model.logo
  ' m.logo.color = model.logo.color
  ' m.logo.width = model.logo.width 
  ' m.logo.height = model.logo.height
  ' ' m.logo.imageUri = model.logo.imageUri
  ' ' m.logo.imageWidth = model.logo.imageWidth
  ' ' m.logo.imageHeight = model.logo.imageHeight
  ' ' m.logo.imageTranslation = model.logo.imageTranslation
  ' m.logo.translation = model.logo.translation
  ' 'm.menu.appendChild(m.logo)
  ' ' m.buttonList.appendChild(m.logo)

  'set menu menu
  setMenuContent(model)
end sub

sub setMenuContent(model as object)
    model = m.model
    content = createObject("RoSGNode", "ContentNode")

    index = 0
    y = 42
    m.buttons = []
    defaultFocus = model.defaultFocus
    
    for each icon in m.icons
        button = createObject("RoSGNode", "MenuItem")
        button.id = "m.button_" + index.toStr()
        itemContent = {}
        id = "button_" + index.toStr()
        itemContent.Append({
            "id": id,
            "name": model.names[index],
            "index": index,
            "default": defaultFocus,
            "width": model.itemSizeExpanded[0],
            "height": model.itemSizeExpanded[1],
            "color": model.color[index],
            "focusedColor":  model.focusedColor[index],
            "selectedColor": model.selectedColor,
            "imageUri": model.icons[index],
            "imageWidth": model.iconWidth[index],
            "imageHeight": model.iconHeight[index],
            "imageTranslation": model.iconTranslation[index],
            "text": m.labels[index],
            "textColor": model.labelColor[index],
            "textFocusedColor": model.labelFocusedColor[index],
            "textSelectedColor": model.labelSelectedColor[index],
            "textTranslation": model.labelTranslaton[index],
            "textSize": model.labelTextSize[index]
        })
        index += 1
        y += model.itemSizeExpanded[1]
        button.translation = [0, y]
        button.itemContent = itemContent
        m.buttons.push(button)
        m.buttonList.appendChild(button)
    end for
    m.top.currentIndex = defaultFocus
end sub

sub menuHasFocus(focused)
  for each button in m.buttons
     button.menuHasFocus = focused
  end for
  ' itemHasFocus(m.top.currentIndex, focused)
end sub

sub itemHasFocus(index, focused)
  if focused = true
    buttonName = m.top.config.items[index.toStr()].label
    m.buttons[index].itemHasFocus = true
  else
    m.buttons[index].itemHasFocus = false
  end if
end sub

sub itemSelected(index)
  for i = 0 to m.buttons.count() - 1
    if i = index
        m.buttons[i].itemIsSelected = true
    else
        m.buttons[i].itemIsSelected = false
    end if
  end for
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  handled = false
  if press = true
    key = LCase(key)
    ? "NavMenu::onKeyEvent - key="; key
    if m.mainContainer.currentViewFocused <> Constants().Views.MENU
      return false
    end if

    if key = "back"
      if m.top.currentIndex = 0
        m.mainContainer.callFunc("setMenuTimerControl", "stop")
        m.mainContainer.callFunc("exitApp")
        m.top.setFocus(false)
      else
        ' m.global.navMenuIndex = 0
        itemHasFocus(0, true)
        itemHasFocus(m.top.currentIndex, false)
        m.top.currentIndex = 0
      end if
      handled = true
    else if key = "right"
        itemHasFocus(m.top.currentIndex, false)
        m.mainContainer.currentViewFocused = Constants().Views.GRID
        handled = true
    else if key = "down"
      if m.top.currentIndex < m.buttons.count() - 1
        m.top.currentIndex += 1
      end if
      itemHasFocus(m.top.currentIndex, true)
      itemHasFocus(m.top.currentIndex - 1, false)
      handled = true
    else if key = "up"
      if m.top.currentIndex > 0
        m.top.currentIndex -= 1
      end if
      itemHasFocus(m.top.currentIndex, true)
      itemHasFocus(m.top.currentIndex + 1, false)
      handled = true
    else if key = "ok"
      handleSelectedMenu()
      handled = true
    end if
  end if
  return handled
end function

function handleSelectedMenu() as void
  itemSelected(m.top.currentIndex)
  itemHasFocus(m.top.currentIndex, false)
  if m.names[m.top.currentIndex] = Constants().MenuOptions.PROFILE then
    m.mainContainer.callFunc("showProfileDialog")
  else if m.names[m.top.currentIndex] = Constants().MenuOptions.HOME then
    m.mainContainer.currentViewFocused = Constants().Views.GRID
  end if
end function



function getMainMenuConfig(json as dynamic) as object
  model = {}
  model.names = []
  model.icons = []
  model.iconsFocused = []
  model.iconsSelected = []
  model.labels = []
  model.labelColor = []
  model.labelFocusedColor = []
  model.labelSelectedColor = []
  model.labelTextSize = []
  model.labelTextFont = []
  model.labelTranslaton = []
  model.selected = []
  model.iconWidth = []
  model.iconHeight = []
  model.iconTranslation = []
  model.color = []
  model.focusedColor = []
  model.selectedColor = []
  model.logo = {}

  model.itemSize = json.itemSize
  model.itemSizeExpanded = json.itemSizeExpanded
  model.logo.color = json.logoColor
  model.logo.width = json.logoWidth
  model.logo.height = json.logoHeight
  model.logo.imageUri = json.logoUri
  model.logo.imageUriExpanded = json.logoUriExpanded
  model.logo.imageWidth = json.logoImageWidth
  model.logo.imageHeight = json.logoImageHeight
  model.logo.imageTranslation = json.logoImageTransation
  model.logo.logoImageTransationExpanded = json.logoImageTransationExpanded
  model.logo.translation = json.logoTranslation
  model.logo.translationExpanded = json.logoTranslationExpanded
  model.menuTransaltion = json.menuTranslation
  model.defaultFocus = json.defaultFocus
  model.rowSpacings = json.rowSpacings

  index = 0
  for each item in json.items
    model.names.push(json.items[index.toStr()]["name"])
    model.icons.push(json.items[index.toStr()]["icon"])
    model.iconsFocused.push(json.items[index.toStr()]["iconFocused"])
    model.iconsSelected.push(json.items[index.toStr()]["iconSelected"])
    model.labels.push(json.items[index.toStr()]["label"])
    model.labelColor.push(json.items[index.toStr()]["labelColor"])
    model.labelFocusedColor.push(json.items[index.toStr()]["labelFocusedColor"])
    model.labelSelectedColor.push(json.items[index.toStr()]["labelSelectedColor"])
    model.labelTextSize.push(json.items[index.toStr()]["labelTextSize"])
    model.labelTextFont.push(json.items[index.toStr()]["labelTextFont"])
    model.labelTranslaton.push(json.items[index.toStr()]["labelTranslaton"])
    model.selected.push(json.items[index.toStr()]["selected"])
    model.iconWidth.push(json.items[index.toStr()]["iconWidth"])
    model.iconHeight.push(json.items[index.toStr()]["iconHeight"])
    model.iconTranslation.push(json.items[index.toStr()]["iconTranslation"])
    model.color.push(json.items[index.toStr()]["color"])
    model.focusedColor.push(json.items[index.toStr()]["focusedColor"])
    model.selectedColor.push(json.items[index.toStr()]["selectedColor"])
    index += 1
  end for
  return model
  end function
  