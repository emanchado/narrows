port module Common.Ports exposing (..)

import Json.Decode

type alias RenderChapterInfo =
  { elemId : String
  , text : Json.Decode.Value
  }

port renderChapter : RenderChapterInfo -> Cmd msg
