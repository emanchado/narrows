module ProfileApp.Api exposing (..)

import Http
import Json.Decode as Json exposing (..)
import Json.Encode
import Common.Models exposing (UserInfo)
import Common.Api.Json exposing (parseUserInfo)
import ProfileApp.Messages exposing (Msg, Msg(..))


encodeUserChanges : String -> Value
encodeUserChanges newPassword =
  Json.Encode.object
    [ ( "password", Json.Encode.string newPassword )
    ]


fetchCurrentUser : Cmd Msg
fetchCurrentUser =
  Http.send UserFetchResult <|
  Http.get "/api/session" parseUserInfo


saveUser : Int -> String -> Cmd Msg
saveUser userId newPassword =
  Http.send SaveUserResult <|
  Http.request
    { method = "PUT"
    , headers = []
    , url = "/api/users/" ++ (toString userId)
    , body = Http.jsonBody <| encodeUserChanges newPassword
    , expect = Http.expectStringResponse Ok
    , timeout = Nothing
    , withCredentials = False
    }
