module NarrationOverviewApp.Messages exposing (..)

import Http

import Common.Models exposing (Narration, NarrationOverview)

type Msg
  = NoOp
  | NarrationOverviewFetchError Http.Error
  | NarrationOverviewFetchSuccess NarrationOverview
