module NarratorDashboardApp.Models exposing (..)

import Browser.Navigation as Nav
import Common.Models exposing (Banner, NarrationOverview)


-- Just to parse the response
type alias NarratorOverview =
    { narrations : List NarrationOverview
    }


type alias Model =
    { key : Nav.Key
    , banner : Maybe Banner
    , narrations : Maybe (List NarrationOverview)
    }
