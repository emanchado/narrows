module ChapterControlApp.Models exposing (..)

import Routing
import Common.Models exposing (Narration, Chapter, Banner, Character, MessageThread, Reaction)

type alias ChapterInteractions =
  { chapter : Chapter
  , reactions: List Reaction
  , messageThreads: List MessageThread
  }

type alias Model =
  { narration : Maybe Narration
  , interactions : Maybe ChapterInteractions
  , banner : Maybe Banner
  }
