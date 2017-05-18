module NarratorDashboardApp.Messages exposing (..)

import Http
import NarratorDashboardApp.Models exposing (NarratorOverview)


type Msg
    = NoOp
    | NavigateTo String
    | NarratorOverviewFetchResult (Result Http.Error NarratorOverview)
    | NarrationArchive
    | NewNarration
