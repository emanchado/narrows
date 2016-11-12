module NarrationOverviewApp.Messages exposing (..)

import Http

import Common.Models exposing (Narration)
import NarrationOverviewApp.Models exposing (NarrationOverview)

type Msg
  = NoOp
  | NarrationFetchError Http.Error
  | NarrationFetchSuccess Narration
  | NarrationOverviewFetchError Http.Error
  | NarrationOverviewFetchSuccess NarrationOverview
