sub init()
    m.top.functionName = "execute"
end sub

function execute() as void
    ? "NetworkHttpTask::execute"
    m.retryCount = 0
    m.maxRetryCount = 3
    handleHttpRequest()
end function

function handleHttpRequest() as void

    ? "NetworkHttpTask::handleHttpRequest"

    if m.top.request = invalid
        ? "NetworkHttpTask::handleHttpRequest - request is invalid"
        return
    end if

    ? "NetworkHttpTask::handleHttpRequest - m.top.request=" ; FormatJson(m.top.request)
    requestInfo = m.top.request
    httpUrlTransferResp = invalid
    reqPayload = FormatJson(requestInfo.payload)
    
    ' Create a new roUrlTransfer object
    port = createObject("roMessagePort")
    httpUrlTransfer = CreateObject("roUrlTransfer")
    httpUrlTransfer.setPort(port)
    httpUrlTransfer.setUrl(requestInfo.uri)
    httpUrlTransfer.setRequest(requestInfo.method)
    if requestInfo.headers <> invalid
        requestHeaders = requestInfo.headers
        for each header in requestHeaders
            httpUrlTransfer.addHeader(header, requestHeaders[header])
        end for
    end if

    ' Set the request headers and enable https connection
    httpUrlTransfer.enableFreshConnection(true)
    httpUrlTransfer.enablePeerVerification(false)
    httpUrlTransfer.setCertificatesFile("common:/certs/ca-bundle.crt")
    httpUrlTransfer.initClientCertificates()
    httpUrlTransfer.addHeader("Content-Type", "application/json")
    httpUrlTransfer.retainBodyOnError(true)

    if (httpUrlTransfer.AsyncPostFromString(reqPayload))
        ? "NetworkHttpTask::handleHttpRequest - waiting for response ..."
        event = wait(2500, httpUrlTransfer.GetPort())
        if (type(event) = "roUrlEvent")
            ? event
            if (event.GetResponseCode() = 200)
                httpUrlTransferResp = event.GetString()
            else
                ? "NetworkHttpTask::handleHttpRequest - FAILED with response code = "; event.GetResponseCode()
                httpUrlTransfer.AsyncCancel()
            end if
        else if (event = invalid)
            ? "NetworkHttpTask::handleHttpRequest - invalid response ..."
            httpUrlTransfer.AsyncCancel()
        end if
    end if

    if (httpUrlTransferResp <> invalid)
       ? "NetworkHttpTask::handleHttpRequest - response = "; httpUrlTransferResp
       httpUrlTransferResp = ParseJSON(httpUrlTransferResp)
    else
        if ((m.retryCount)< m.maxRetryCount) then
            m.retryCount = m.retryCount + 1
            ? "NetworkHttpTask::handleHttpRequest - retrying, attempt #"; m.retryCount; " of "; m.maxRetryCount
            handleHttpRequest()
        else
            ? "NetworkHttpTask::handleHttpRequest - max retry count reached"
            httpUrlTransferResp = {}
        end if
    end if

    m.top.response = httpUrlTransferResp
end function