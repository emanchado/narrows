module CharacterEditApp.Api exposing (..)

import Http
import CharacterEditApp.Api.Json exposing (parseCharacterInfo, parseCharacterToken, parseSendIntroResponse, encodeCharacterUpdate)
import CharacterEditApp.Messages exposing (Msg, Msg(..))
import CharacterEditApp.Models exposing (CharacterInfo)


fetchCharacterInfo : Int -> Cmd Msg
fetchCharacterInfo characterId =
  let
    characterApiUrl = "/api/characters/by-id/" ++ (String.fromInt characterId)
  in
    Http.get { url = characterApiUrl
             , expect = Http.expectJson CharacterFetchResult parseCharacterInfo
             }


resetCharacterToken : Int -> Cmd Msg
resetCharacterToken characterId =
  Http.post { url = ("/api/characters/by-id/" ++ (String.fromInt characterId) ++ "/token")
            , body = Http.emptyBody
            , expect = Http.expectJson ResetCharacterTokenResult parseCharacterToken
            }


sendIntroEmail : Int -> Cmd Msg
sendIntroEmail characterId =
  Http.post { url = ("/api/characters/by-id/" ++ (String.fromInt characterId) ++ "/intro-email")
            , body = Http.emptyBody
            , expect = Http.expectJson SendIntroEmailResult parseSendIntroResponse
            }


saveCharacter : Int -> CharacterInfo -> Cmd Msg
saveCharacter characterId characterInfo =
  Http.request { method = "PUT"
               , url = "/api/characters/by-id/" ++ (String.fromInt characterId)
               , headers = []
               , body = Http.jsonBody <| encodeCharacterUpdate characterInfo
               , expect = Http.expectWhatever SaveCharacterResult
               , timeout = Nothing
               , tracker = Nothing
               }
