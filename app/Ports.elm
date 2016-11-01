port module Ports exposing (..)

import Json.Decode

type alias RenderChapterInfo =
  { elemId : String
  , text : Json.Decode.Value
  }

type alias NarrationMediaInfo =
  { audioElemId : String
  }

port renderChapter : RenderChapterInfo -> Cmd msg
port startNarration : NarrationMediaInfo -> Cmd msg
port playPauseNarrationMusic : NarrationMediaInfo -> Cmd msg
port flashElement : String -> Cmd msg
port pageScrollListener : (Int -> msg) -> Sub msg
port markNarrationAsStarted : (Int -> msg) -> Sub msg
