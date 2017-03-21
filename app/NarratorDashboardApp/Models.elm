module NarratorDashboardApp.Models exposing (..)

import Common.Models exposing (Banner, NarrationOverview)

type alias Model =
  { banner : Maybe Banner
  , narrations : Maybe (List NarrationOverview)
  }
