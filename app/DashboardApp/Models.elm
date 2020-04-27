module DashboardApp.Models exposing (..)

import Browser.Navigation as Nav
import Common.Models exposing (Banner, NarrationOverview, CharacterInfo)


type DashboardScreen
  = IndexScreen
  | NarrationArchiveScreen
  | CharacterArchiveScreen


-- Just to parse the response
type alias NarratorOverview =
    { narrations : List NarrationOverview
    , characters : List CharacterInfo
    }


-- Just to parse the response
type alias NarrationArchive =
    { narrations : List NarrationOverview
    }


-- Just to parse the response
type alias CharacterArchive =
    { characters : List CharacterInfo
    }


type alias Model =
    { key : Nav.Key
    , banner : Maybe Banner
    , screen : DashboardScreen
    , narrations : Maybe (List NarrationOverview)
    , characters : Maybe (List CharacterInfo)
    , allNarrations : Maybe (List NarrationOverview)
    , allCharacters : Maybe (List CharacterInfo)
    }
