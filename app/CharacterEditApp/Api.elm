module CharacterEditApp.Api exposing (..)

import Http
import CharacterEditApp.Api.Json exposing (parseCharacterInfo, parseCharacterToken, parseSendIntroResponse, encodeCharacterUpdate)
import CharacterEditApp.Messages exposing (Msg, Msg(..))
import CharacterEditApp.Models exposing (CharacterInfo)


fetchCharacterInfo : Int -> Cmd Msg
fetchCharacterInfo characterId =
  let
    characterApiUrl = "/api/characters/by-id/" ++ (toString characterId)
  in
    Http.send CharacterFetchResult <|
      Http.get characterApiUrl parseCharacterInfo


resetCharacterToken : Int -> Cmd Msg
resetCharacterToken characterId =
  Http.send ResetCharacterTokenResult <|
    Http.post
      ("/api/characters/by-id/" ++ (toString characterId) ++ "/token")
      Http.emptyBody
      parseCharacterToken


sendIntroEmail : Int -> Cmd Msg
sendIntroEmail characterId =
  Http.send SendIntroEmailResult <|
    Http.post
      ("/api/characters/by-id/" ++ (toString characterId) ++ "/intro-email")
      Http.emptyBody
      parseSendIntroResponse


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
