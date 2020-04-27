module DashboardApp.Api exposing (..)

import Http
import DashboardApp.Messages exposing (Msg, Msg(..))
import DashboardApp.Api.Json exposing (parseNarratorOverview)


fetchNarratorOverview : Cmd Msg
fetchNarratorOverview =
  Http.get { url = "/api/narrations/overview"
           , expect = Http.expectJson NarratorOverviewFetchResult parseNarratorOverview
           }
