module NarrationCreationApp.Api.Json exposing (..)

import Json.Decode as Json exposing (..)
import Json.Encode

import NarrationCreationApp.Models exposing (NarrationProperties, CreateNarrationResponse)

parseNarrationResponse : Json.Decoder CreateNarrationResponse
parseNarrationResponse =
  Json.object2 CreateNarrationResponse
    ("id" := int)
    ("title" := string)

encodeNarrationProperties : NarrationProperties -> String
encodeNarrationProperties props =
    (Json.Encode.encode
       0
       (Json.Encode.object [ ("title", Json.Encode.string props.title)
                           ]))
