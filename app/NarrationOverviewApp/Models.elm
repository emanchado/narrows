module NarrationOverviewApp.Models exposing (..)

import Common.Models exposing (Narration, Banner, NarrationOverview)


type alias NarrationNovel =
    { id : Int
    , characterId : Int
    , token : String
    , created : String
    }


type alias NarrationNovelsResponse =
    { narrationId : Int
    , novels : List NarrationNovel
    }


type alias Model =
    { narrationOverview : Maybe NarrationOverview
    , banner : Maybe Banner
    , narrationNovels : Maybe (List NarrationNovel)
    }
