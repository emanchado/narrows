module NarratorDashboardApp.Messages exposing (..)

import Http

import NarratorDashboardApp.Models exposing (NarratorOverview)

type Msg
  = NoOp
  | NarratorOverviewFetchError Http.Error
  | NarratorOverviewFetchSuccess NarratorOverview
