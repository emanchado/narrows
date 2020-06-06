module CharacterEditApp.Api exposing (..)

import Http
import CharacterEditApp.Api.Json exposing (parseCharacterInfo, parseCharacterToken, encodeCharacterUpdate)
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


removeCharacter : Int -> Cmd Msg
removeCharacter characterId =
  Http.request { method = "DELETE"
               , url = "/api/characters/by-id/" ++ (String.fromInt characterId)
               , headers = []
               , body = Http.emptyBody
               , expect = Http.expectWhatever RemoveCharacterResult
               , timeout = Nothing
               , tracker = Nothing
               }


unclaimCharacter : Int -> Cmd Msg
unclaimCharacter characterId =
  Http.request { method = "DELETE"
               , url = "/api/characters/by-id/" ++ (String.fromInt characterId) ++ "/claim"
               , headers = []
               , body = Http.emptyBody
               , expect = Http.expectJson UnclaimCharacterResult parseCharacterInfo
               , timeout = Nothing
               , tracker = Nothing
               }
