module CharacterCreationApp.Api exposing (..)

import Http
import Json.Encode

import CharacterCreationApp.Messages exposing (Msg, Msg(..))


createCharacter : Int -> String -> String -> Cmd Msg
createCharacter narrationId characterName playerEmail =
  let
    postNarrationCharacter =
      "/api/narrations/" ++ (toString narrationId) ++ "/characters"

    jsonEncodedBody =
      (Json.Encode.object
         [ ( "name", Json.Encode.string characterName )
         , ( "email", Json.Encode.string playerEmail )
         ])
  in
    Http.send CreateCharacterResult <|
      Http.request { method = "POST"
                   , url = postNarrationCharacter
                   , headers = []
                   , body = Http.jsonBody jsonEncodedBody
                   , expect = Http.expectStringResponse Ok
                   , timeout = Nothing
                   , withCredentials = False
                   }
