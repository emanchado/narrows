port module CharacterApp.Ports exposing (..)

import Json.Encode

type alias AvatarElementInfo =
  { fileInputId : String
  }

type alias AvatarUploadInfo =
  { fileInputId : String
  , characterToken : String
  }

type alias UploadError =
  { status : Int
  , message : String
  }


port descriptionContentChanged : (Json.Encode.Value -> msg) -> Sub msg
port backstoryContentChanged : (Json.Encode.Value -> msg) -> Sub msg

port readAvatarAsUrl : AvatarElementInfo -> Cmd msg
port receiveAvatarAsUrl : (String -> msg) -> Sub msg
port uploadAvatar : AvatarUploadInfo -> Cmd msg
port uploadAvatarSuccess : (String -> msg) -> Sub msg
port uploadAvatarError : (UploadError -> msg) -> Sub msg
