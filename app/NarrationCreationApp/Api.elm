module NarrationCreationApp.Api exposing (..)

import Task
import Http

import NarrationCreationApp.Messages exposing (Msg, Msg(..))
import NarrationCreationApp.Models exposing (NarrationProperties)
import NarrationCreationApp.Api.Json exposing (encodeNarrationProperties)

createNarration : NarrationProperties -> Cmd Msg
createNarration props =
  Task.perform
    CreateNarrationError
    CreateNarrationSuccess
    (Http.send
       Http.defaultSettings
       { verb = "POST"
       , url = "/api/narrations"
       , headers = [("Content-Type", "application/json")]
       , body = Http.string <| encodeNarrationProperties props
       })
