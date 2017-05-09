module NarratorDashboardApp.Models exposing (..)

import Common.Models exposing (Banner, NarrationOverview)


-- Just to parse the response


type alias NarratorOverview =
    { narrations : List NarrationOverview
    }


type alias Model =
    { banner : Maybe Banner
    , narrations : Maybe (List NarrationOverview)
    }
