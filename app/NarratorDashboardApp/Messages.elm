module NarratorDashboardApp.Messages exposing (..)

import Http

import NarratorDashboardApp.Models exposing (NarratorOverview)

type Msg
  = NoOp
  | NavigateTo String
  | NarratorOverviewFetchError Http.Error
  | NarratorOverviewFetchSuccess NarratorOverview
  | NewNarration
