module UserManagementApp.Api exposing (..)

import Http
import Json.Decode as Json exposing (..)
import Json.Encode
import Common.Api.Json exposing (parseUserInfo)
import UserManagementApp.Models exposing (UserChanges, UserListResponse)
import UserManagementApp.Messages exposing (Msg, Msg(..))


parseUsers : Json.Decoder UserListResponse
parseUsers =
    Json.map UserListResponse (field "users" <| list parseUserInfo)


encodeUserChanges : UserChanges -> Value
encodeUserChanges userChanges =
  let
    role = if userChanges.isAdmin then "admin" else ""
  in
    Json.Encode.object
      [ ( "password", Json.Encode.string userChanges.password )
      , ( "role", Json.Encode.string role )
      ]


encodeNewUser : String -> Bool -> Value
encodeNewUser email isAdmin =
  let
    role = if isAdmin then "admin" else ""
  in
    Json.Encode.object
      [ ( "email", Json.Encode.string email )
      , ( "role", Json.Encode.string role )
      ]


fetchUsers : Cmd Msg
fetchUsers =
  Http.send UsersFetchResult <|
    Http.get "/api/users" parseUsers


saveUser : UserChanges -> Cmd Msg
saveUser userChanges =
  Http.send SaveUserResult <|
    Http.request
      { method = "PUT"
      , headers = []
      , url = "/api/users/" ++ (toString userChanges.userId)
      , body = Http.jsonBody <| encodeUserChanges userChanges
      , expect = Http.expectStringResponse Ok
      , timeout = Nothing
      , withCredentials = False
      }


saveNewUser : String -> Bool -> Cmd Msg
saveNewUser email isAdmin =
  Http.send SaveNewUserResult <|
    Http.post "/api/users" (Http.jsonBody <| encodeNewUser email isAdmin) parseUserInfo
