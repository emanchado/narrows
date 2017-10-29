port module CharacterEditApp.Ports exposing (..)

import Json.Encode

type alias UploadError =
  { status : Int
  , message : String
  }


port narratorDescriptionContentChanged : (Json.Encode.Value -> msg) -> Sub msg
port narratorBackstoryContentChanged : (Json.Encode.Value -> msg) -> Sub msg

port narratorReceiveAvatarAsUrl : (String -> msg) -> Sub msg
port narratorUploadAvatarSuccess : (String -> msg) -> Sub msg
port narratorUploadAvatarError : (UploadError -> msg) -> Sub msg
