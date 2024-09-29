sub init()
    m.top.observeField("regcode", "onRegcodeChange")
end sub

sub onRegcodeChange(regcodeChangeEvent as object)
    ? "[RegCodeScreen] setRegcode"
    regcode = regcodeChangeEvent.getData()
    regcodeScreenContent = m.top.findNode("regcodeLabel")
    regcodeScreenContent.drawingStyles = {
        "TitleText": {
            "fontSize": 48
            "fontUri": "font:MediumBoldSystemFont"
            "color": "#FFFFFF"
        }
        "MessageText": {
            "fontSize": 36
            "fontUri": "font:MediumSystemFont"
            "color": "#FFFFFF"
        }
        "RegcodeText": {
            "fontSize": 64
            "fontUri": "font:LargeBoldSystemFont"
            "color": "#FFFFFF"
        }
    }
    regcodeScreenContent.text = "<TitleText>Log into your cable provider.</TitleText>" + chr(10)+ chr(10) + "<MessageText>Please go to xyz.com on your computer or mobile and enter the code below</MessageText>" + chr(10) + chr(10) + "<RegcodeText>" + regcode + "</RegcodeText>"
end sub