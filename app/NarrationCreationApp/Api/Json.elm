module NarrationCreationApp.Api.Json exposing (..)

import Json.Decode as Json exposing (..)
import Json.Encode
import Common.Models exposing (Narration)
import NarrationCreationApp.Models exposing (NewNarrationProperties, NarrationUpdateProperties, CreateNarrationResponse)


parseCreateNarrationResponse : Json.Decoder CreateNarrationResponse
parseCreateNarrationResponse =
  Json.map2 CreateNarrationResponse
      (field "id" int)
      (field "title" string)


encodeNewNarration : NewNarrationProperties -> Value
encodeNewNarration props =
  (Json.Encode.object
     [ ( "title", Json.Encode.string props.title )
     ])


encodeNarrationUpdate : NarrationUpdateProperties -> Value
encodeNarrationUpdate props =
  let
    newEncodedDefaultBackgroundImage =
      case props.defaultBackgroundImage of
        Just bgImage -> Json.Encode.string bgImage
        Nothing -> Json.Encode.null
    newEncodedDefaultAudio =
      case props.defaultAudio of
        Just audio -> Json.Encode.string audio
        Nothing -> Json.Encode.null
  in
    (Json.Encode.object
       [ ( "title", Json.Encode.string props.title )
       , ( "defaultBackgroundImage", newEncodedDefaultBackgroundImage )
       , ( "defaultAudio", newEncodedDefaultAudio )
       ])
