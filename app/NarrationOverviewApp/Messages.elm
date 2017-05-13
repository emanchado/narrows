module NarrationOverviewApp.Messages exposing (..)

import Http
import Common.Models exposing (Narration, NarrationStatus, NarrationOverview)
import NarrationOverviewApp.Models exposing (NarrationNovelsResponse)


type Msg
    = NoOp
    | NavigateTo String
    | NarrationOverviewFetchResult (Result Http.Error NarrationOverview)
    | NarrationNovelsFetchResult (Result Http.Error NarrationNovelsResponse)
    | MarkNarration NarrationStatus
    | MarkNarrationResult (Result Http.Error Narration)
