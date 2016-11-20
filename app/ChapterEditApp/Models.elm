module ChapterEditApp.Models exposing (..)

import Json.Decode
import Json.Encode

import Common.Models exposing (FullCharacter, Narration, Chapter, Banner)

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

type alias EditorToolState =
  { newImageUrl : String
  , newMentionTargets : List FullCharacter
  }

type alias Model =
  { chapter : Maybe Chapter
  , narration : Maybe Narration
  , banner : Maybe Banner
  , editorToolState : EditorToolState
  }
