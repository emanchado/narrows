module CharacterApp.Api exposing (..)

import Http
import CharacterApp.Api.Json exposing (parseCharacterInfo, encodeCharacterUpdate)
import CharacterApp.Messages exposing (Msg, Msg(..))
import CharacterApp.Models exposing (CharacterInfo)


fetchCharacterInfo : String -> Cmd Msg
fetchCharacterInfo characterToken =
  let
    characterApiUrl = "/api/characters/" ++ characterToken
  in
    Http.send CharacterFetchResult <|
      Http.get characterApiUrl parseCharacterInfo


saveCharacter : String -> CharacterInfo -> Cmd Msg
saveCharacter characterToken characterInfo =
  Http.send SaveCharacterResult <|
    Http.request { method = "PUT"
                 , url = "/api/characters/" ++ characterToken
                 , headers = []
                 , body = Http.jsonBody <| encodeCharacterUpdate characterInfo
                 , expect = Http.expectStringResponse Ok
                 , timeout = Nothing
                 , withCredentials = False
                 }
