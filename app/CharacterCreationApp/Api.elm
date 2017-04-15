module CharacterCreationApp.Api exposing (..)

import Task
import Http
import Json.Decode as Json exposing (..)
import Json.Encode

-- import Common.Api.Json exposing (parseChapter, parseReaction, parseMessageThread)

import CharacterCreationApp.Messages exposing (Msg, Msg(..))

createCharacter : Int -> String -> String -> Cmd Msg
createCharacter narrationId characterName playerEmail =
  let
    postNarrationCharacter =
      "/api/narrations/" ++ (toString narrationId) ++ "/characters"
    jsonEncodedBody =
      (Json.Encode.encode
         0
         (Json.Encode.object [ ("name", Json.Encode.string characterName)
                             , ("email", Json.Encode.string playerEmail)
                             ]))
  in
    Task.perform
      CreateCharacterError
      CreateCharacterSuccess
      (Http.send
         Http.defaultSettings
         { verb = "POST"
         , url = postNarrationCharacter
         , headers = [("Content-Type", "application/json")]
         , body = Http.string jsonEncodedBody
         })
