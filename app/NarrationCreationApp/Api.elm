module NarrationCreationApp.Api exposing (..)

import Http

import Common.Api.Json exposing (parseNarration)
import NarrationCreationApp.Messages exposing (Msg, Msg(..))
import NarrationCreationApp.Models exposing (NewNarrationProperties, NarrationUpdateProperties)
import NarrationCreationApp.Api.Json exposing (encodeNewNarration, encodeNarrationUpdate, parseCreateNarrationResponse)


fetchNarration : Int -> Cmd Msg
fetchNarration narrationId =
  let
    narrationApiUrl = "/api/narrations/" ++ (toString narrationId)
  in
    Http.send FetchNarrationResult <|
      Http.get narrationApiUrl parseNarration

createNarration : NewNarrationProperties -> Cmd Msg
createNarration props =
  Http.send CreateNarrationResult <|
  Http.request { method = "POST"
               , url = "/api/narrations/"
               , headers = []
               , body = Http.jsonBody <| encodeNewNarration props
               , expect = Http.expectJson parseCreateNarrationResponse
               , timeout = Nothing
               , withCredentials = False
               }

saveNarration : Int -> NarrationUpdateProperties -> Cmd Msg
saveNarration narrationId props =
  let
    narrationApiUrl = "/api/narrations/" ++ (toString narrationId)
  in
    Http.send SaveNarrationResult <|
    Http.request { method = "PUT"
                 , url = narrationApiUrl
                 , headers = []
                 , body = Http.jsonBody <| encodeNarrationUpdate props
                 , expect = Http.expectJson parseNarration
                 , timeout = Nothing
                 , withCredentials = False
                 }
