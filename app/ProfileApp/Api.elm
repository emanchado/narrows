module ProfileApp.Api exposing (..)

import Http
import Json.Decode as Json exposing (..)
import Json.Encode
import Common.Api.Json exposing (parseUserInfo)
import ProfileApp.Messages exposing (Msg, Msg(..))


encodeUserChanges : String -> Value
encodeUserChanges newPassword =
  Json.Encode.object
    [ ( "password", Json.Encode.string newPassword )
    ]


fetchCurrentUser : Cmd Msg
fetchCurrentUser =
  Http.get { url = "/api/session"
           , expect = Http.expectJson UserFetchResult parseUserInfo
           }


saveUser : Int -> String -> Cmd Msg
saveUser userId newPassword =
  Http.request
    { method = "PUT"
    , headers = []
    , url = "/api/users/" ++ (String.fromInt userId)
    , body = Http.jsonBody <| encodeUserChanges newPassword
    , expect = Http.expectStringResponse SaveUserResult Ok
    , timeout = Nothing
    , tracker = Nothing
    }
