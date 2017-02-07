module CharacterApp.Api exposing (..)

import Task
import Http

import CharacterApp.Api.Json exposing (parseCharacterInfo, encodeCharacterUpdate)
import CharacterApp.Messages exposing (Msg, Msg(..))
import CharacterApp.Models exposing (CharacterInfo)

fetchCharacterInfo : String -> Cmd Msg
fetchCharacterInfo characterToken =
  let
    characterApiUrl = "/api/characters/" ++ characterToken
  in
    Task.perform CharacterFetchError CharacterFetchSuccess
      (Http.get parseCharacterInfo characterApiUrl)

saveCharacter : String -> CharacterInfo -> Cmd Msg
saveCharacter characterToken characterInfo =
  Task.perform
    SaveCharacterError
    SaveCharacterSuccess
    (Http.send
       Http.defaultSettings
       { verb = "PUT"
       , url = "/api/characters/" ++ characterToken
       , headers = [("Content-Type", "application/json")]
       , body = Http.string <| encodeCharacterUpdate characterInfo
       })
