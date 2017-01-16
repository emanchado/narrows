module ChapterEditApp.Models exposing (..)

import Json.Encode

import Common.Models exposing (FullCharacter, Character, Narration, Chapter, Banner)

newEmptyChapter : Narration -> Chapter
newEmptyChapter narration =
  { id = 0
  , narrationId = narration.id
  , title = ""
  , audio = narration.defaultAudio
  , backgroundImage = narration.defaultBackgroundImage
  , text = Json.Encode.list []
  , participants = narration.characters
  , published = Nothing
  }

type alias LastReactionChapter =
  { id : Int
  , title : String
  }

type alias LastReaction =
  { chapterInfo : LastReactionChapter
  , character : Character
  , text : Maybe String
  }

type alias LastReactions =
  { chapterId : Int
  , reactions : List LastReaction
  }

type alias Model =
  { chapter : Maybe Chapter
  , narration : Maybe Narration
  , lastReactions : Maybe LastReactions
  , banner : Maybe Banner
  }
