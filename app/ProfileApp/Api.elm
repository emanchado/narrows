module ProfileApp.Api exposing (..)

import Http
import Json.Decode as Json exposing (..)
import Json.Encode
import Common.Api.Json exposing (parseUserInfo)
import ProfileApp.Messages exposing (Msg, Msg(..))


encodeUserChanges : String -> String -> Value
encodeUserChanges newDisplayName newPassword =
  Json.Encode.object
    [ ( "displayName", Json.Encode.string newDisplayName )
    , ( "password", Json.Encode.string newPassword )
    ]


fetchCurrentUser : Cmd Msg
fetchCurrentUser =
  Http.get { url = "/api/session"
           , expect = Http.expectJson UserFetchResult parseUserInfo
           }


saveUser : Int -> String -> String -> Cmd Msg
saveUser userId newDisplayName newPassword =
  Http.request
    { method = "PUT"
    , headers = []
    , url = "/api/users/" ++ (String.fromInt userId)
    , body = Http.jsonBody <| encodeUserChanges newDisplayName newPassword
    , expect = Http.expectStringResponse SaveUserResult Ok
    , timeout = Nothing
    , tracker = Nothing
    }
