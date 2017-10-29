port module CharacterApp.Ports exposing (..)

import Json.Encode

type alias UploadError =
  { status : Int
  , message : String
  }


port descriptionContentChanged : (Json.Encode.Value -> msg) -> Sub msg
port backstoryContentChanged : (Json.Encode.Value -> msg) -> Sub msg

port userReceiveAvatarAsUrl : (String -> msg) -> Sub msg
port userUploadAvatarSuccess : (String -> msg) -> Sub msg
port userUploadAvatarError : (UploadError -> msg) -> Sub msg
