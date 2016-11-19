module ChapterControlApp.Models exposing (..)

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
  , published : Maybe String
  , reactions : List Reaction
  }

type alias ChapterControl =
  { chapters : List ChapterOverview
  }

type alias Model =
  { narration : Maybe Narration
  , chapterControl : Maybe ChapterControl
  , banner : Maybe Banner
  }

-- Text, reactions, messages, message sender
