module NarratorDashboardApp.Api exposing (..)

import Http
import NarratorDashboardApp.Messages exposing (Msg, Msg(..))
import NarratorDashboardApp.Api.Json exposing (parseNarratorOverview)


fetchNarratorOverview : Cmd Msg
fetchNarratorOverview =
  Http.get { url = "/api/narrations/overview"
           , expect = Http.expectJson NarratorOverviewFetchResult parseNarratorOverview
           }
