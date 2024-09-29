function VizbeeHomeSSOConstants() as object
    return {
        VizbeeSignInState: {
            SIGN_IN_NOT_STARTED: "not_started"
            SIGN_IN_IN_PROGRESS: "in_progress"
            SIGN_IN_CANCELLED: "cancelled"
            SIGN_IN_COMPLETED: "completed"
            SIGN_IN_FAILED: "failed"
        }
        SignInEventType: {
            HOME_SSO: "tv.vizbee.homesso.signin"
        }
    }
end function