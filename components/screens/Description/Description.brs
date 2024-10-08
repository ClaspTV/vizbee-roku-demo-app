' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
sub Init()
    'setting top interfaces
    m.top.Title = m.top.findNode("Title")
    m.top.Description = m.top.findNode("Description")
end sub

' Content change handler
' All fields population
sub OnContentchanged()
    item = m.top.content

    title = item.title
    if title <> invalid then
        m.top.Title.text = title.toStr()
    end if

    value = item.description
    if value <> invalid then
        if value.toStr() <> "" then
            m.top.Description.text = value.toStr()
        else
            m.top.Description.text = "No description"
        end if
    end if
end sub
