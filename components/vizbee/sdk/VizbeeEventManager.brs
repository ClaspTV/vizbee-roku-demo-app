sub init()
   m.eventNameAndHandlersMap = {} 
end sub

'------------
' Public API
'------------

function registerForEvent(eventName as string, eventHandler as object) as void

    ? "VizbeeEventHandler::registerForEvent"
    if not m.eventNameAndHandlersMap.DoesExist(eventName) then
        m.eventNameAndHandlersMap[eventName] = []
    end if
    m.eventNameAndHandlersMap[eventName].push(eventHandler)
end function

function unregisterForEvent(eventName as string, eventHandler as object) as void

   if m.eventNameAndHandlersMap.DoesExist(eventName) then
        ' TODO: remove particular event handler from the list
        m.eventNameAndHandlersMap[eventName].clear()
   end if
end function

function onEvent(eventInfo as object) as void
    
    eventName = eventInfo.type
    eventData = eventInfo.data
    if m.eventNameAndHandlersMap.DoesExist(eventName) then
        eventHandlers = m.eventNameAndHandlersMap[eventName]
        for each eventHandler in eventHandlers
            eventHandler.callFunc("onEvent", eventInfo)
        end for
    else
        m.top.eventInfo = eventInfo
    end if
end function

