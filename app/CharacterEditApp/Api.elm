module CharacterEditApp.Api exposing (..)

import Http
import CharacterEditApp.Api.Json exposing (parseCharacterInfo, encodeCharacterUpdate)
import CharacterEditApp.Messages exposing (Msg, Msg(..))
import CharacterEditApp.Models exposing (CharacterInfo)


fetchCharacterInfo : Int -> Cmd Msg
fetchCharacterInfo characterId =
  let
    characterApiUrl = "/api/characters/by-id/" ++ (toString characterId)
  in
    Http.send CharacterFetchResult <|
      Http.get characterApiUrl parseCharacterInfo


saveCharacter : Int -> CharacterInfo -> Cmd Msg
saveCharacter characterId characterInfo =
  Http.send SaveCharacterResult <|
    Http.request { method = "PUT"
                 , url = "/api/characters/by-id/" ++ (toString characterId)
                 , headers = []
                 , body = Http.jsonBody <| encodeCharacterUpdate characterInfo
                 , expect = Http.expectStringResponse Ok
                 , timeout = Nothing
                 , withCredentials = False
                 }
