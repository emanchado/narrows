module NarrationCreationApp.Api exposing (..)

import Http
import NarrationCreationApp.Messages exposing (Msg, Msg(..))
import NarrationCreationApp.Models exposing (NarrationProperties)
import NarrationCreationApp.Api.Json exposing (encodeNarrationProperties, parseNarrationResponse)


createNarration : NarrationProperties -> Cmd Msg
createNarration props =
    Http.send CreateNarrationResult <|
    Http.request { method = "POST"
                 , url = "/api/narrations/"
                 , headers = []
                 , body = Http.jsonBody <| encodeNarrationProperties props
                 , expect = Http.expectJson parseNarrationResponse
                 , timeout = Nothing
                 , withCredentials = False
                 }
