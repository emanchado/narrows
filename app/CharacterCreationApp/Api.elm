module CharacterCreationApp.Api exposing (..)

import Http
import Json.Encode

import Common.Api.Json exposing (parseNarration, parseCharacter)
import CharacterCreationApp.Messages exposing (Msg, Msg(..))


fetchNarration : Int -> Cmd Msg
fetchNarration narrationId =
  let
    getNarrationUrl = "/api/narrations/" ++ (toString narrationId)
  in
    Http.send FetchNarrationResult <|
      Http.get getNarrationUrl parseNarration


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
      Http.post
        postNarrationCharacter
        (Http.jsonBody jsonEncodedBody)
        parseCharacter
