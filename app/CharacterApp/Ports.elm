port module CharacterApp.Ports exposing (..)

import Json.Encode

port descriptionContentChanged : (Json.Encode.Value -> msg) -> Sub msg
port backstoryContentChanged : (Json.Encode.Value -> msg) -> Sub msg
