module NarrationOverviewApp.Models exposing (..)

import Common.Models exposing (Narration, Banner, NarrationOverview)

type alias Model =
  { narrationOverview : Maybe NarrationOverview
  , banner : Maybe Banner
  }
