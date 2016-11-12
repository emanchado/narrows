module NarratorApp.Models exposing (..)

import Json.Decode

import Common.Models exposing (Character, Narration, Banner)

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
