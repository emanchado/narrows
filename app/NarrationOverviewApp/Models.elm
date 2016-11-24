module NarrationOverviewApp.Models exposing (..)

import Common.Models exposing (Narration, Banner)

type alias Reaction =
  { characterId : Int
  , text : Maybe String
  }

type alias ChapterOverview =
  { id : Int
  , title : String
  , numberMessages : Int
  , published : Maybe String
  , reactions : List Reaction
  }

type alias NarrationOverview =
  { chapters : List ChapterOverview
  }

type alias Model =
  { narration : Maybe Narration
  , narrationOverview : Maybe NarrationOverview
  , banner : Maybe Banner
  }
