module NarrationOverviewApp.Api exposing (..)

import Task
import Http

import NarrationOverviewApp.Messages exposing (Msg, Msg(..))
import NarrationOverviewApp.Api.Json exposing (parseNarration, parseNarrationOverview)

fetchNarrationInfo : Int -> Cmd Msg
fetchNarrationInfo narrationId =
  let
    narrationApiUrl = "/api/narrations/" ++ (toString narrationId)
  in
    Task.perform NarrationFetchError NarrationFetchSuccess
      (Http.get parseNarration narrationApiUrl)

fetchNarrationOverview : Int -> Cmd Msg
fetchNarrationOverview narrationId =
  let
    narrationApiUrl = "/api/narrations/" ++ (toString narrationId) ++ "/chapters"
  in
    Task.perform NarrationOverviewFetchError NarrationOverviewFetchSuccess
      (Http.get parseNarrationOverview narrationApiUrl)
