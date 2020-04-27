module DashboardApp.Messages exposing (..)

import Http
import DashboardApp.Models exposing (NarratorOverview, NarrationArchive, CharacterArchive)


type Msg
    = NoOp
    | NavigateTo String
    | NarratorOverviewFetchResult (Result Http.Error NarratorOverview)
    | NarrationArchive
    | NewNarration
    | NarrationArchiveFetchResult (Result Http.Error NarrationArchive)
    | CharacterArchive
    | CharacterArchiveFetchResult (Result Http.Error CharacterArchive)
