module Core.Api exposing (..)

import Http
import Task
import Json.Decode as Json exposing (..)
import Json.Encode

import Core.Models
import Core.Messages exposing (..)

parseSession : Json.Decoder Core.Models.UserSessionInfo
parseSession =
  Json.object3 Core.Models.UserSessionInfo
    ("id" := int)
    ("email" := string)
    ("role" := string)

refreshSession : Cmd Msg
refreshSession =
  Task.perform SessionFetchError SessionFetchSuccess
    (Http.get parseSession "/api/session")

login : String -> String -> Cmd Msg
login email password =
  let
    jsonEncodedBody =
      (Json.Encode.encode
         0
         (Json.Encode.object [ ("email", Json.Encode.string email)
                             , ("password", Json.Encode.string password) ]))
  in
    Task.perform
      LoginError
      LoginSuccess
      (Http.send
         Http.defaultSettings
         { verb = "POST"
         , url = "/api/session"
         , headers = [("Content-Type", "application/json")]
         , body = Http.string jsonEncodedBody
         })
