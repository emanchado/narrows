module EmailVerificationApp.Messages exposing (..)

import Http
import Common.Models exposing (UserInfo)

type Msg
  = NoOp
  | VerifyEmailTokenResult (Result Http.Error String)
