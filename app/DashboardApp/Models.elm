module DashboardApp.Models exposing (..)

import Browser.Navigation as Nav
import Common.Models exposing (Banner, NarrationOverview, CharacterInfo)


-- Just to parse the response
type alias NarratorOverview =
    { narrations : List NarrationOverview
    , characters : List CharacterInfo
    }


type alias Model =
    { key : Nav.Key
    , banner : Maybe Banner
    , narrations : Maybe (List NarrationOverview)
    , characters : Maybe (List CharacterInfo)
    }
