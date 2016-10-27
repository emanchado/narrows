port module Ports exposing (renderChapter, RenderChapterInfo, pageScrollListener)

import Json.Decode

type alias RenderChapterInfo =
  { elemId : String
  , text : Json.Decode.Value
  }

port renderChapter : RenderChapterInfo -> Cmd msg
port pageScrollListener : (Int -> msg) -> Sub msg
