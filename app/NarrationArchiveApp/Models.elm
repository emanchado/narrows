module NarrationArchiveApp.Models exposing (..)

import Common.Models exposing (Banner, NarrationOverview)


-- Just to parse the response
type alias NarrationArchive =
    { narrations : List NarrationOverview
    }


type alias Model =
    { banner : Maybe Banner
    , narrations : Maybe (List NarrationOverview)
    }
