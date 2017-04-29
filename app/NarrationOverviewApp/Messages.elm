module NarrationOverviewApp.Messages exposing (..)

import Http

import Common.Models exposing (Narration, NarrationOverview)

type Msg
  = NoOp
  | NavigateTo String
  | NarrationOverviewFetchError Http.Error
  | NarrationOverviewFetchSuccess NarrationOverview
