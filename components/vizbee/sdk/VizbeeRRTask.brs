'********************************************************************
' Vizbee Screen SDK
' Copyright (c) 2014-2020 Vizbee Inc.
' All Rights Reserved.
'
' VizbeeRRTask
' *******************************************************************

' -------------
' Init methods
' -------------

sub init()
    m.top.functionName = "execute"
end sub

function execute() as void
    m.top.onRRCmdResponse = vizbee_rr_controller().send(m.top.rrCommand)
end function