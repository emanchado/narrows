module NarrationOverviewApp.Messages exposing (..)

import Http

import Common.Models exposing (Narration, NarrationOverview)
import NarrationOverviewApp.Models exposing (NarrationNovelsResponse)

type Msg
  = NoOp
  | NavigateTo String
  | NarrationOverviewFetchError Http.Error
  | NarrationOverviewFetchSuccess NarrationOverview
  | NarrationNovelsFetchError Http.Error
  | NarrationNovelsFetchSuccess NarrationNovelsResponse
