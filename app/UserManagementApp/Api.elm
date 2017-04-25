module UserManagementApp.Api exposing (..)

import Task
import Http
import Json.Decode as Json exposing (..)
import Json.Encode

import Common.Models exposing (UserInfo)
import UserManagementApp.Models exposing (UserChanges, UserListResponse)
import UserManagementApp.Messages exposing (Msg, Msg(..))

parseUser : Json.Decoder UserInfo
parseUser =
  Json.object3 UserInfo ("id" := int) ("email" := string) ("role" := string)

parseUsers : Json.Decoder UserListResponse
parseUsers =
  Json.object1 UserListResponse ("users" := list parseUser)

encodeUserChanges : UserChanges -> String
encodeUserChanges userChanges =
  let
    role = if userChanges.isAdmin then "admin" else ""
  in
    (Json.Encode.encode
       0
       (Json.Encode.object
          [ ("password", Json.Encode.string userChanges.password)
          , ("role", Json.Encode.string role)
          ]))

encodeNewUser : String -> Bool -> String
encodeNewUser email isAdmin =
  let
    role = if isAdmin then "admin" else ""
  in
    (Json.Encode.encode
       0
       (Json.Encode.object [ ("email", Json.Encode.string email)
                           , ("role", Json.Encode.string role)
                           ]))

fetchUsers : Cmd Msg
fetchUsers =
  Task.perform UsersFetchError UsersFetchSuccess
    (Http.get parseUsers "/api/users")

saveUser : UserChanges -> Cmd Msg
saveUser userChanges =
  Task.perform
    SaveUserError
    SaveUserSuccess
    (Http.send
       Http.defaultSettings
       { verb = "PUT"
       , url = "/api/users/" ++ (toString userChanges.userId)
       , headers = [("Content-Type", "application/json")]
       , body = Http.string <| encodeUserChanges userChanges
       })

saveNewUser : String -> Bool -> Cmd Msg
saveNewUser email isAdmin =
  Task.perform
    SaveNewUserError
    SaveNewUserSuccess
    (Http.send
       Http.defaultSettings
       { verb = "POST"
       , url = "/api/users"
       , headers = [("Content-Type", "application/json")]
       , body = Http.string <| encodeNewUser email isAdmin
       })
