port module Common.Ports exposing (..)

import Json.Decode

import Common.Models exposing (FullCharacter)

type alias RenderChapterInfo =
  { elemId : String
  , text : Json.Decode.Value
  }

type alias InitEditorInfo =
  { elemId : String
  , narrationId : Int
  , narrationImages : List String
  , chapterParticipants : List FullCharacter
  , text : Json.Decode.Value
  }

port renderChapter : RenderChapterInfo -> Cmd msg
port initEditor : InitEditorInfo -> Cmd msg
