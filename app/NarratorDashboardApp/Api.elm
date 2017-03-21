module NarratorDashboardApp.Api exposing (..)

import Task
import Http

import NarratorDashboardApp.Messages exposing (Msg, Msg(..))
import NarratorDashboardApp.Api.Json exposing (parseNarratorOverview)

fetchNarratorOverview : Cmd Msg
fetchNarratorOverview =
  let
    narrationApiUrl = "/api/narrations"
  in
    Task.perform NarratorOverviewFetchError NarratorOverviewFetchSuccess
      (Http.get parseNarratorOverview narrationApiUrl)
