module NarrationOverviewApp.Api exposing (..)

import Task
import Http

import NarrationOverviewApp.Messages exposing (Msg, Msg(..))
import Common.Api.Json exposing (parseNarration, parseNarrationOverview)

fetchNarrationOverview : Int -> Cmd Msg
fetchNarrationOverview narrationId =
  let
    narrationApiUrl = "/api/narrations/" ++ (toString narrationId) ++ "/chapters"
  in
    Task.perform NarrationOverviewFetchError NarrationOverviewFetchSuccess
      (Http.get parseNarrationOverview narrationApiUrl)
