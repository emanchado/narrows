module DashboardApp.Messages exposing (..)

import Http
import DashboardApp.Models exposing (NarratorOverview, NarrationArchive)


type Msg
    = NoOp
    | NavigateTo String
    | NarratorOverviewFetchResult (Result Http.Error NarratorOverview)
    | NarrationArchive
    | NewNarration
    | NarrationArchiveFetchResult (Result Http.Error NarrationArchive)
