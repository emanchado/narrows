module NarratorApp.Models exposing (..)

import Json.Decode
import Json.Encode

import Common.Models exposing (Character, Narration, Banner)

loadingPlaceholderChapter : Chapter
loadingPlaceholderChapter =
  { id = 0
  , narrationId = 0
  , title = ""
  , audio = Nothing
  , backgroundImage = Nothing
  , text = Json.Encode.list []
  , participants = []
  , published = Nothing
  }

loadingPlaceholderNarration : Narration
loadingPlaceholderNarration =
  { id = 0
  , title = ""
  , characters = []
  , defaultAudio = Nothing
  , defaultBackgroundImage = Nothing
  , files = { audio = []
            , backgroundImages = []
            , images = []
            }
  }

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

type alias Chapter =
  { id : Int
  , narrationId : Int
  , title : String
  , audio : Maybe String
  , backgroundImage : Maybe String
  , text : Json.Decode.Value
  , participants : List Character
  , published : Maybe String
  }

type alias EditorToolState =
  { newImageUrl : String
  , newMentionTargets : List Character
  }

type alias Model =
  { chapter : Maybe Chapter
  , narration : Maybe Narration
  , banner : Maybe Banner
  , editorToolState : EditorToolState
  }
