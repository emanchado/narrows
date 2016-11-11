port module NarratorApp.Ports exposing (..)

import Json.Decode

type alias InitEditorInfo =
  { elemId : String
  , text : Json.Decode.Value
  }

type alias AddImageInfo =
  { editor : String
  , imageUrl : String
  }

port initEditor : InitEditorInfo -> Cmd msg
port addImage : AddImageInfo -> Cmd msg
