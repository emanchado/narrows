port module NarratorApp.Ports exposing (..)

import Json.Decode

type alias InitEditorInfo =
  { elemId : String
  , text : Json.Decode.Value
  }

port initEditor : InitEditorInfo -> Cmd msg
