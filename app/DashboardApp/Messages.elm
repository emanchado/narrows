module DashboardApp.Messages exposing (..)

import Http
import DashboardApp.Models exposing (NarratorOverview)


type Msg
    = NoOp
    | NavigateTo String
    | NarratorOverviewFetchResult (Result Http.Error NarratorOverview)
    | NarrationArchive
    | NewNarration
