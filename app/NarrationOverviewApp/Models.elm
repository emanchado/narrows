module NarrationOverviewApp.Models exposing (..)

import Routing
import Common.Models exposing (Narration, Banner)

type alias Reaction =
  { chapterId : Int
  , characterId : Int
  , text : Maybe String
  }

type alias ChapterOverview =
  { id : Int
  , title : String
  , numberMessages : Int
  , published : Maybe Int
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
