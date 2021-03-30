module CharacterApp.Api exposing (..)

import Json.Encode
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


abandonCharacter : String -> Cmd Msg
abandonCharacter characterToken =
  Http.request { method = "DELETE"
               , url = "/api/characters/" ++ characterToken ++ "/claim"
               , headers = []
               , body = Http.emptyBody
               , expect = Http.expectStringResponse AbandonCharacterResult Ok
               , timeout = Nothing
               , tracker = Nothing
               }


sendNotes : String -> String -> Cmd Msg
sendNotes characterToken updatedNotes =
  let
    sendNotesApiUrl = "/api/notes/" ++ characterToken

    jsonEncodedBody =
      (Json.Encode.object [ ( "notes", Json.Encode.string updatedNotes ) ])
  in
    Http.request
      { method = "PUT"
      , url = sendNotesApiUrl
      , headers = []
      , body = Http.jsonBody jsonEncodedBody
      , expect = Http.expectStringResponse SendNotesResult (\_ -> Ok "")
      , timeout = Nothing
      , tracker = Nothing
      }
