module NarrationCreationApp.Api exposing (..)

import Http

import Common.Api.Json exposing (parseNarration)
import NarrationCreationApp.Messages exposing (Msg, Msg(..))
import NarrationCreationApp.Models exposing (NewNarrationProperties, NarrationUpdateProperties)
import NarrationCreationApp.Api.Json exposing (encodeNewNarration, encodeNarrationUpdate, parseCreateNarrationResponse)


fetchNarration : Int -> Cmd Msg
fetchNarration narrationId =
  let
    narrationApiUrl = "/api/narrations/" ++ (String.fromInt narrationId)
  in
    Http.get { url = narrationApiUrl
             , expect = Http.expectJson FetchNarrationResult parseNarration
             }

createNarration : NewNarrationProperties -> Cmd Msg
createNarration props =
  Http.request { method = "POST"
               , url = "/api/narrations/"
               , headers = []
               , body = Http.jsonBody  <| encodeNewNarration props
               , expect = Http.expectJson CreateNarrationResult parseCreateNarrationResponse
               , timeout = Nothing
               , tracker = Nothing
               }

saveNarration : Int -> NarrationUpdateProperties -> Cmd Msg
saveNarration narrationId props =
  let
    narrationApiUrl = "/api/narrations/" ++ (String.fromInt narrationId)
  in
    Http.request { method = "PUT"
                 , url = narrationApiUrl
                 , headers = []
                 , body = Http.jsonBody <| encodeNarrationUpdate props
                 , expect = Http.expectJson SaveNarrationResult parseNarration
                 , timeout = Nothing
                 , tracker = Nothing
                 }
