module NarratorDashboardApp.Api exposing (..)

import Http
import NarratorDashboardApp.Messages exposing (Msg, Msg(..))
import NarratorDashboardApp.Api.Json exposing (parseNarratorOverview)


fetchNarratorOverview : Cmd Msg
fetchNarratorOverview =
  Http.send NarratorOverviewFetchResult <|
    Http.get "/api/narrations/overview" parseNarratorOverview
