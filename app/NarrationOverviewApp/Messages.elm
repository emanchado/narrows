module NarrationOverviewApp.Messages exposing (..)

import Http
import Common.Models exposing (Narration, NarrationOverview)
import NarrationOverviewApp.Models exposing (NarrationNovelsResponse)


type Msg
    = NoOp
    | NavigateTo String
    | NarrationOverviewFetchResult (Result Http.Error NarrationOverview)
    | NarrationNovelsFetchResult (Result Http.Error NarrationNovelsResponse)
