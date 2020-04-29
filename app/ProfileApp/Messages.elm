module ProfileApp.Messages exposing (..)

import Http
import Common.Models exposing (UserInfo)

type Msg
  = NoOp
  | UserFetchResult (Result Http.Error UserInfo)
  | UpdatePassword String
  | UpdateDisplayName String
  | SaveUser
  | SaveUserResult (Result Http.Error (Http.Response String))
