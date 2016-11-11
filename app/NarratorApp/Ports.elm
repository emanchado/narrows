port module NarratorApp.Ports exposing (..)

import Json.Encode
import Json.Decode

import NarratorApp.Models exposing (Character)

type alias InitEditorInfo =
  { elemId : String
  , text : Json.Decode.Value
  }

type alias AddImageInfo =
  { editor : String
  , imageUrl : String
  }

type alias AddMentionInfo =
  { editor : String
  , targets : List Character
  }

port initEditor : InitEditorInfo -> Cmd msg
port addImage : AddImageInfo -> Cmd msg
port addMention : AddMentionInfo -> Cmd msg
port editorContentChanged : (Json.Encode.Value -> msg) -> Sub msg
