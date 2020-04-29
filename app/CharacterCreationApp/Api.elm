module CharacterCreationApp.Api exposing (..)

import Http
import Json.Encode

import Common.Api.Json exposing (parseNarration, parseCharacter)
import CharacterCreationApp.Messages exposing (Msg, Msg(..))


fetchNarration : Int -> Cmd Msg
fetchNarration narrationId =
  let
    getNarrationUrl = "/api/narrations/" ++ (String.fromInt narrationId)
  in
    Http.get { url = getNarrationUrl
             , expect = Http.expectJson FetchNarrationResult parseNarration
             }


createCharacter : Int -> String -> Cmd Msg
createCharacter narrationId characterName =
  let
    postNarrationCharacter =
      "/api/narrations/" ++ (String.fromInt narrationId) ++ "/characters"

    jsonEncodedBody =
      (Json.Encode.object
         [ ( "name", Json.Encode.string characterName )
         ])
  in
    Http.post { url = postNarrationCharacter
              , expect = Http.expectJson CreateCharacterResult parseCharacter
              , body = (Http.jsonBody jsonEncodedBody)
              }
