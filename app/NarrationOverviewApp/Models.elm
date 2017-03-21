module NarrationOverviewApp.Models exposing (..)

import Common.Models exposing (Narration, Banner, NarrationOverview)

type alias Model =
  { narration : Maybe Narration
  , narrationOverview : Maybe NarrationOverview
  , banner : Maybe Banner
  }
