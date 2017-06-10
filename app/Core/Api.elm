module Core.Api exposing (..)

import Http
import Json.Decode as Json exposing (..)
import Json.Encode
import Core.Messages exposing (..)
import Core.Models exposing (ResetPasswordResponse)
import Common.Models exposing (UserInfo)


parseSession : Json.Decoder UserInfo
parseSession =
  Json.map3 UserInfo
    (field "id" int)
    (field "email" string)
    (field "role" string)


parseResetPasswordResponse : Json.Decoder ResetPasswordResponse
parseResetPasswordResponse =
  Json.map ResetPasswordResponse
    (field "email" string)


refreshSession : Cmd Msg
refreshSession =
  Http.send SessionFetchResult <|
    Http.get "/api/session" parseSession


login : String -> String -> Cmd Msg
login email password =
  let
    jsonEncodedBody = (Json.Encode.object
                         [ ( "email", Json.Encode.string email )
                         , ( "password", Json.Encode.string password )
                         ])
  in
    Http.send LoginResult <|
      Http.post "/api/session" (Http.jsonBody jsonEncodedBody) parseSession


resetPassword : String -> Cmd Msg
resetPassword email =
  let
    jsonEncodedBody = (Json.Encode.object
                         [ ( "email", Json.Encode.string email )
                         ])
  in
    Http.send ResetPasswordResult <|
      Http.post "/api/password-reset" (Http.jsonBody jsonEncodedBody) parseResetPasswordResponse


logout : Cmd Msg
logout =
  Http.send LogoutResult <|
      Http.request { method = "DELETE"
                   , url = "/api/session"
                   , headers = []
                   , body = Http.emptyBody
                   , expect = Http.expectString
                   , timeout = Nothing
                   , withCredentials = False
                   }
