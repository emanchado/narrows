module CharacterApp.Api exposing (..)

import Http

import Common.Models exposing (CharacterInfo)
import Common.Api.Json exposing (parseCharacterInfo)
import CharacterApp.Api.Json exposing (encodeCharacterUpdate)
import CharacterApp.Messages exposing (Msg, Msg(..))


fetchCharacterInfo : String -> Cmd Msg
fetchCharacterInfo characterToken =
  let
    characterApiUrl = "/api/characters/" ++ characterToken
  in
    Http.get { url = characterApiUrl
             , expect = Http.expectJson CharacterFetchResult parseCharacterInfo
             }


saveCharacter : String -> CharacterInfo -> Cmd Msg
saveCharacter characterToken characterInfo =
  Http.request { method = "PUT"
               , url = "/api/characters/" ++ characterToken
               , headers = []
               , body = Http.jsonBody <| encodeCharacterUpdate characterInfo
               , expect = Http.expectStringResponse SaveCharacterResult Ok
               , timeout = Nothing
               , tracker = Nothing
               }
