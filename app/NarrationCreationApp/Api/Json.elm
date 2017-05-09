module NarrationCreationApp.Api.Json exposing (..)

import Json.Decode as Json exposing (..)
import Json.Encode
import NarrationCreationApp.Models exposing (NarrationProperties, CreateNarrationResponse)


parseNarrationResponse : Json.Decoder CreateNarrationResponse
parseNarrationResponse =
    Json.map2 CreateNarrationResponse
        (field "id" int)
        (field "title" string)


encodeNarrationProperties : NarrationProperties -> Value
encodeNarrationProperties props =
    (Json.Encode.object
       [ ( "title", Json.Encode.string props.title )
       ])
