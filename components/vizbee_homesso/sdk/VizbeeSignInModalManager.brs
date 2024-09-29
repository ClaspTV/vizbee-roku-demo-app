'********************************************************************
' Vizbee HomeSSO SDK
'
' @class VizbeeSignInModalManager
' @description
' This class is responsible for managing UI modal per sign in status of the user.
' This class supports the below public APIs:
' 1. 'updateSignInStatus' function is called when the sign in status changes from VizbeeSignInModalManager.
' *******************************************************************

sub init()
    m.vizbeeModalManager = CreateObject("roSGNode", "VizbeeModalManager")
    m.vizbeeHomeSSOThemeOptions = CreateObject("roSGNode", "VizbeeHomeSSOTheme")
    m.vizbeeHomeSSOModalConfigOptions = CreateObject("roSGNode", "VizbeeHomeSSOModalConfig")
    m.vizbeeHomeSSOSignInModalConfigOptions = CreateObject("roSGNode", "VizbeeHomeSSOSignInModalConfig")
    m.previousSignInState = ""
end sub

' @function updateSignInStatus
' @param {Object}  modalPreferences
'        {Boolean}  modalPreferences.enable
'        {String}  modalPreferences.title
'        {String}  modalPreferences.desc
'        {String}  modalPreferences.titleTextColor
'        {String}  modalPreferences.descTextColor
'        {String}  modalPreferences.titleFontUri
'        {String}  modalPreferences.descFontUri
'        {Integer}  modalPreferences.titleTextFontSize
'        {Integer}  modalPreferences.descTextFontSize
'        {String}  modalPreferences.bgColor
'        {String}  modalPreferences.borderColor
'        {String}  modalPreferences.iconUrl
'        {Boolean}  modalPreferences.isProgressIcon
'        {Object}  modalPreferences.options
' @param {String}  signInState
' @param {Object}  signInStatusInfo
'        {String}  signInStatusInfo.type
'        {String}  signInStatusInfo.data
' @param {Boolean}  isSenderSignedIn
' @description
' This method is invoked when the sign in status changes from VizbeeSignInModalManager.

function updateSignInStatus(modalPreferences, signInState, signInStatusInfo, isSenderSignedIn) as void
    if signInState = VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_IN_PROGRESS then
        ' avoid duplicate modals
        if m.previousSignInState <> invalid and m.previousSignInState <> VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_IN_PROGRESS then
            showSignInProgressModal(modalPreferences, isSenderSignedIn)
        end if
        m.previousSignInState = signInState
    else if signInState = VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_COMPLETED then
        m.vizbeeModalManager.callFunc("hide")
        showSignInSuccessModal(modalPreferences, signInStatusInfo)
        m.previousSignInState = signInState
    else if signInState = VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_FAILED or signInState = VizbeeHomeSSOConstants().VizbeeSignInState.SIGN_IN_CANCELLED then
        m.vizbeeModalManager.callFunc("hide")
        m.previousSignInState = signInState
    end if
end function

'-----------------
' Helper Methods
'-----------------

function showSignInProgressModal(modalPreferences as dynamic, isSenderSignedIn as boolean) as void

    VizbeeHomeSSOLog("VERB", "VizbeeSignInModalManager::showSignInProgressModal")

    if modalPreferences = invalid or modalPreferences.enable <> true then
        VizbeeHomeSSOLog("INFO", "VizbeeSignInModalManager::showSignInProgressModal - shouldShowVizbeeModal is false")
        return
    end if

    if isSenderSignedIn then
        vizbeeSignInModalOptions = getModalOptionsForSignInProgress()
    else
        vizbeeSignInModalOptions = getModalOptionsForSignInInformation()
    end if
    if modalPreferences.options <> invalid then
        vizbeeSignInModalOptions = updateModalPreferences(modalPreferences.options, vizbeeSignInModalOptions)
    end if

    m.vizbeeModalManager.callFunc("setOptions", vizbeeSignInModalOptions)
    m.vizbeeModalManager.callFunc("show", 3600)
end function

function showSignInSuccessModal(modalPreferences as dynamic, signInStatusInfo as dynamic) as void

    VizbeeHomeSSOLog("VERB", "VizbeeSignInModalManager::showSignInSuccessModal")

    if modalPreferences = invalid or modalPreferences.enable <> true then
        VizbeeHomeSSOLog("INFO", "VizbeeSignInModalManager::showSignInSuccessModal - shouldShowVizbeeModal is false")
        return
    end if

    vizbeeSignInModalOptions = getOptionsForSignInSuccess()
    if modalPreferences.options <> invalid then
        vizbeeSignInModalOptions = updateModalPreferences(modalPreferences.options, vizbeeSignInModalOptions)
    end if
    if signInStatusInfo <> invalid then
        ttl = 8
    end if
    m.vizbeeModalManager.callFunc("setOptions", vizbeeSignInModalOptions)
    m.vizbeeModalManager.callFunc("show", ttl)
end function

function getInfoModalOptionsMap() as object
    return {
        "width": {
            "type": "integer"
            "value": ["infoSignInModalWidth", "width", ""]
        }
        "borderColor": {
            "type": "string"
            "value": ["infoSignInModalBorderColor", "borderColor", "secondaryColor"]
        }
        "marginBottom": {
            "type": "integer"
            "value": ["infoSignInModalMarginBottom", "marginBottom", ""]
        }
        "marginRight": {
            "type": "integer"
            "value": ["infoSignInModalMarginRight", "marginRight", ""]
        }

        "iconUrl": {
            "type": "string"
            "value": ["infoSignInModalIconUri", "", ""]
        }
        "iconWidth": {
            "type": "integer"
            "value": ["infoSignInModalIconWidth", "iconWidth", ""]
        }
        "iconHeight": {
            "type": "integer"
            "value": ["infoSignInModalIconHeight", "iconHeight", ""]
        }
        "iconMarginRight": {
            "type": "integer"
            "value": ["infoSignInModalIconMarginRight", "iconMarginRight", ""]
        }

        "title": {
            "type": "string"
            "value": ["infoSignInModalTitleText", "", ""]
        }
        "titleTextColor": {
            "type": "string"
            "value": ["infoSignInModalTitleTextFontColor", "titleTextFontColor", "tertiaryColor"]
        }
        "titleFontUri": {
            "type": "string"
            "value": ["infoSignInModalTitleTextFontFamily", "titleTextFontFamily", "primaryFont"]
        }
        "titleTextFontSize": {
            "type": "integer"
            "value": ["infoSignInModalTitleTextFontSize", "titleTextFontSize", ""]
        }

        "desc": {
            "type": "string"
            "value": ["infoSignInModalDescText", "", ""]
        }
        "descTextColor": {
            "type": "string"
            "value": ["infoSignInModalDescTextFontColor", "descTextFontColor", "subTextColor", "tertiaryColor"]
        }
        "descFontUri": {
            "type": "string"
            "value": ["infoSignInModalDescTextFontFamily", "descTextFontFamily", "secondaryFont", "primaryFont"]
        }
        "descTextFontSize": {
            "type": "integer"
            "value": ["infoSignInModalDescTextFontSize", "descTextFontSize", ""]
        }
    }
end function

function getProgressModalOptionsMap() as object
    return {
        "width": {
            "type": "integer"
            "value": ["progressSignInModalWidth", "width", ""]
        }
        "borderColor": {
            "type": "string"
            "value": ["progressSignInModalBorderColor", "borderColor", "secondaryColor"]
        }
        "marginBottom": {
            "type": "integer"
            "value": ["progressSignInModalMarginBottom", "marginBottom", ""]
        }
        "marginRight": {
            "type": "integer"
            "value": ["progressSignInModalMarginRight", "marginRight", ""]
        }

        "iconUrl": {
            "type": "string"
            "value": ["progressSignInModalIconUri", "", ""]
        }
        "iconWidth": {
            "type": "integer"
            "value": ["progressSignInModalIconWidth", "iconWidth", ""]
        }
        "iconHeight": {
            "type": "integer"
            "value": ["progressSignInModalIconHeight", "iconHeight", ""]
        }
        "iconMarginRight": {
            "type": "integer"
            "value": ["progressSignInModalIconMarginRight", "iconMarginRight", ""]
        }

        "title": {
            "type": "string"
            "value": ["progressSignInModalTitleText", "", ""]
        }
        "titleTextColor": {
            "type": "string"
            "value": ["progressSignInModalTitleTextFontColor", "titleTextFontColor", "tertiaryColor"]
        }
        "titleFontUri": {
            "type": "string"
            "value": ["progressSignInModalTitleTextFontFamily", "titleTextFontFamily", "primaryFont"]
        }
        "titleTextFontSize": {
            "type": "integer"
            "value": ["progressSignInModalTitleTextFontSize", "titleTextFontSize", ""]
        }

        "desc": {
            "type": "string"
            "value": ["progressSignInModalDescText", "", ""]
        }
        "descTextColor": {
            "type": "string"
            "value": ["progressSignInModalDescTextFontColor", "descTextFontColor", "subTextColor", "tertiaryColor"]
        }
        "descFontUri": {
            "type": "string"
            "value": ["progressSignInModalDescTextFontFamily", "descTextFontFamily", "secondaryFont", "primaryFont"]
        }
        "descTextFontSize": {
            "type": "integer"
            "value": ["progressSignInModalDescTextFontSize", "descTextFontSize", ""]
        }
    }
end function

function getSuccessModalOptionsMap() as object
    return {
        "width": {
            "type": "integer"
            "value": ["successSignInModalWidth", "width", ""]
        }
        "borderColor": {
            "type": "string"
            "value": ["successSignInModalBorderColor", "borderColor", "secondaryColor"]
        }
        "marginBottom": {
            "type": "integer"
            "value": ["successSignInModalMarginBottom", "marginBottom", ""]
        }
        "marginRight": {
            "type": "integer"
            "value": ["successSignInModalMarginRight", "marginRight", ""]
        }

        "iconUrl": {
            "type": "string"
            "value": ["successSignInModalIconUri", "", ""]
        }
        "iconWidth": {
            "type": "integer"
            "value": ["successSignInModalIconWidth", "iconWidth", ""]
        }
        "iconHeight": {
            "type": "integer"
            "value": ["successSignInModalIconHeight", "iconHeight", ""]
        }
        "iconMarginRight": {
            "type": "integer"
            "value": ["successSignInModalIconMarginRight", "iconMarginRight", ""]
        }

        "title": {
            "type": "string"
            "value": ["successSignInModalTitleText", "", ""]
        }
        "titleTextColor": {
            "type": "string"
            "value": ["successSignInModalTitleTextFontColor", "titleTextFontColor", "tertiaryColor"]
        }
        "titleFontUri": {
            "type": "string"
            "value": ["successSignInModalTitleTextFontFamily", "titleTextFontFamily", "primaryFont"]
        }
        "titleTextFontSize": {
            "type": "integer"
            "value": ["successSignInModalTitleTextFontSize", "titleTextFontSize", ""]
        }

        "desc": {
            "type": "string"
            "value": ["successSignInModalDescText", "", ""]
        }
        "descTextColor": {
            "type": "string"
            "value": ["successSignInModalDescTextFontColor", "descTextFontColor", "subTextColor", "tertiaryColor"]
        }
        "descFontUri": {
            "type": "string"
            "value": ["successSignInModalDescTextFontFamily", "descTextFontFamily", "secondaryFont", "primaryFont"]
        }
        "descTextFontSize": {
            "type": "integer"
            "value": ["successSignInModalDescTextFontSize", "descTextFontSize", ""]
        }
    }
end function

function getValueForField(fieldId as string, fieldIdConfigMap as object) as dynamic
    
    fieldTypeFromMap = fieldIdConfigMap[fieldId].type
    fieldValuesFromMap = fieldIdConfigMap[fieldId].value
    fieldValueFromSignInModalConfigOptions = m.vizbeeHomeSSOSignInModalConfigOptions[fieldValuesFromMap[0]]
    fieldValueFromModalConfigOptions = m.vizbeeHomeSSOModalConfigOptions[fieldValuesFromMap[1]]
    fieldValue1FromThemeConfigOptions = m.vizbeeHomeSSOThemeOptions[fieldValuesFromMap[2]]
    fieldValue2FromThemeConfigOptions = invalid
    if fieldValuesFromMap[3] <> invalid then
        fieldValue2FromThemeConfigOptions = m.vizbeeHomeSSOThemeOptions[fieldValuesFromMap[3]]
    end if
    if fieldTypeFromMap = "string" then
        if fieldValueFromSignInModalConfigOptions <> invalid and fieldValueFromSignInModalConfigOptions <> "" then
            return fieldValueFromSignInModalConfigOptions
        else if fieldValueFromModalConfigOptions <> invalid and fieldValueFromModalConfigOptions <> "" then
            return fieldValueFromModalConfigOptions
        else if fieldValue1FromThemeConfigOptions <> invalid and fieldValue1FromThemeConfigOptions <> "" then
            return fieldValue1FromThemeConfigOptions
        else if fieldValue2FromThemeConfigOptions <> invalid and fieldValue2FromThemeConfigOptions <> "" then
            return fieldValue2FromThemeConfigOptions
        end if
    else if fieldTypeFromMap = "integer" then
        if fieldValueFromSignInModalConfigOptions <> invalid and fieldValueFromSignInModalConfigOptions > 0 then
            return fieldValueFromSignInModalConfigOptions
        else if fieldValueFromModalConfigOptions <> invalid and fieldValueFromModalConfigOptions > 0 then
            return fieldValueFromModalConfigOptions
        else if fieldValue1FromThemeConfigOptions <> invalid and fieldValue1FromThemeConfigOptions > 0 then
            return fieldValue1FromThemeConfigOptions
        else if fieldValue2FromThemeConfigOptions <> invalid and fieldValue2FromThemeConfigOptions > 0 then
            return fieldValue2FromThemeConfigOptions
        end if
    end if
end function

function getModalOptionsForSignInProgress() as Object

    VizbeeHomeSSOLog("VERB", "VizbeeSignInModalManager::getModalOptionsForSignInProgress")

    fieldIdProgressConfigMap = getProgressModalOptionsMap()
    signInProgressOptions = CreateObject("roSGNode", "VizbeeModalOptions")
    signInProgressOptions.width = getValueForField("width", fieldIdProgressConfigMap)
    signInProgressOptions.borderColor = getValueForField("borderColor", fieldIdProgressConfigMap)
    signInProgressOptions.marginBottom = getValueForField("marginBottom", fieldIdProgressConfigMap)
    signInProgressOptions.marginRight = getValueForField("marginRight", fieldIdProgressConfigMap)

    signInProgressOptions.isProgressIcon = true
    signInProgressOptions.iconUrl = getValueForField("iconUrl", fieldIdProgressConfigMap)
    signInProgressOptions.iconWidth = getValueForField("iconWidth", fieldIdProgressConfigMap)
    signInProgressOptions.iconHeight = getValueForField("iconHeight", fieldIdProgressConfigMap)
    signInProgressOptions.iconMarginRight = getValueForField("iconMarginRight", fieldIdProgressConfigMap)
    
    signInProgressOptions.title = getValueForField("title", fieldIdProgressConfigMap)
    signInProgressOptions.titleTextColor = getValueForField("titleTextColor", fieldIdProgressConfigMap)
    signInProgressOptions.titleFontUri = getValueForField("titleFontUri", fieldIdProgressConfigMap)
    signInProgressOptions.titleTextFontSize = getValueForField("titleTextFontSize", fieldIdProgressConfigMap)

    signInProgressOptions.desc = getValueForField("desc", fieldIdProgressConfigMap)
    signInProgressOptions.descTextColor = getValueForField("descTextColor", fieldIdProgressConfigMap)
    signInProgressOptions.descFontUri = getValueForField("descFontUri", fieldIdProgressConfigMap)
    signInProgressOptions.descTextFontSize = getValueForField("descTextFontSize", fieldIdProgressConfigMap)

    return signInProgressOptions
end function

function getModalOptionsForSignInInformation() as Object

    VizbeeHomeSSOLog("VERB", "VizbeeSignInModalManager::getModalOptionsForSignInProgress")

    fieldIdInformationConfigMap = getInfoModalOptionsMap()
    signInInformationOptions = CreateObject("roSGNode", "VizbeeModalOptions")
    signInInformationOptions.width = getValueForField("width", fieldIdInformationConfigMap)
    signInInformationOptions.borderColor = getValueForField("borderColor", fieldIdInformationConfigMap)
    signInInformationOptions.marginBottom = getValueForField("marginBottom", fieldIdInformationConfigMap)
    signInInformationOptions.marginRight = getValueForField("marginRight", fieldIdInformationConfigMap)
    
    signInInformationOptions.isProgressIcon = false
    signInInformationOptions.iconUrl = getValueForField("iconUrl", fieldIdInformationConfigMap)
    signInInformationOptions.iconWidth = getValueForField("iconWidth", fieldIdInformationConfigMap)
    signInInformationOptions.iconHeight = getValueForField("iconHeight", fieldIdInformationConfigMap)
    signInInformationOptions.iconMarginRight = getValueForField("iconMarginRight", fieldIdInformationConfigMap)
    
    signInInformationOptions.title = getValueForField("title", fieldIdInformationConfigMap)
    signInInformationOptions.titleTextColor = getValueForField("titleTextColor", fieldIdInformationConfigMap)
    signInInformationOptions.titleFontUri = getValueForField("titleFontUri", fieldIdInformationConfigMap)
    signInInformationOptions.titleTextFontSize = getValueForField("titleTextFontSize", fieldIdInformationConfigMap)

    signInInformationOptions.desc = getValueForField("desc", fieldIdInformationConfigMap)
    signInInformationOptions.descTextColor = getValueForField("descTextColor", fieldIdInformationConfigMap)
    signInInformationOptions.descFontUri = getValueForField("descFontUri", fieldIdInformationConfigMap)
    signInInformationOptions.descTextFontSize = getValueForField("descTextFontSize", fieldIdInformationConfigMap)

    return signInInformationOptions
end function

function getOptionsForSignInSuccess() as Object

    VizbeeHomeSSOLog("VERB", "VizbeeSignInModalManager::getModalOptionsForSignInProgress")

    fieldIdSuccessConfigMap = getSuccessModalOptionsMap()
    signInSuccessOptions = CreateObject("roSGNode", "VizbeeModalOptions")
    signInSuccessOptions.width = getValueForField("width", fieldIdSuccessConfigMap)
    signInSuccessOptions.borderColor = getValueForField("borderColor", fieldIdSuccessConfigMap)
    signInSuccessOptions.marginBottom = getValueForField("marginBottom", fieldIdSuccessConfigMap)
    signInSuccessOptions.marginRight = getValueForField("marginRight", fieldIdSuccessConfigMap)
    
    signInSuccessOptions.isProgressIcon = false
    signInSuccessOptions.iconUrl = getValueForField("iconUrl", fieldIdSuccessConfigMap)
    signInSuccessOptions.iconWidth = getValueForField("iconWidth", fieldIdSuccessConfigMap)
    signInSuccessOptions.iconHeight = getValueForField("iconHeight", fieldIdSuccessConfigMap)
    signInSuccessOptions.iconMarginRight = getValueForField("iconMarginRight", fieldIdSuccessConfigMap)
    
    signInSuccessOptions.title = getValueForField("title", fieldIdSuccessConfigMap)
    signInSuccessOptions.titleTextColor = getValueForField("titleTextColor", fieldIdSuccessConfigMap)
    signInSuccessOptions.titleFontUri = getValueForField("titleFontUri", fieldIdSuccessConfigMap)
    signInSuccessOptions.titleTextFontSize = getValueForField("titleTextFontSize", fieldIdSuccessConfigMap)

    signInSuccessOptions.desc = getValueForField("desc", fieldIdSuccessConfigMap)
    signInSuccessOptions.descTextColor = getValueForField("descTextColor", fieldIdSuccessConfigMap)
    signInSuccessOptions.descFontUri = getValueForField("descFontUri", fieldIdSuccessConfigMap)
    signInSuccessOptions.descTextFontSize = getValueForField("descTextFontSize", fieldIdSuccessConfigMap)

    return signInSuccessOptions
end function

function updateModalPreferences(modalPreferences as dynamic, vizbeeSignInModalOptions as object) as object
    if modalPreferences = invalid then
        return vizbeeSignInModalOptions
    end if

    ' text
    if modalPreferences.title <> invalid and modalPreferences.title <> "" then
        vizbeeSignInModalOptions.title = modalPreferences.title
    end if
    if modalPreferences.desc <> invalid and modalPreferences.desc <> "" then
        vizbeeSignInModalOptions.desc = modalPreferences.desc
    end if
    return vizbeeSignInModalOptions
end function