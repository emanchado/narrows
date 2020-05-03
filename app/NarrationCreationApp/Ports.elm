port module NarrationCreationApp.Ports exposing (..)

import Json.Encode
import Common.Models exposing (FileUploadError, FileUploadSuccess)

type alias FontFaceSettings =
  { fontFaceName : String
  , fontUrl : String
  }

port updateFontFaceDefinition : FontFaceSettings -> Cmd msg

port narrationIntroContentChanged : (Json.Encode.Value -> msg) -> Sub msg
port narrationIntroEditUploadFileError : (FileUploadError -> msg) -> Sub msg
port narrationIntroEditUploadFileSuccess : (FileUploadSuccess -> msg) -> Sub msg
port narrationDefaultEditUploadFileError : (FileUploadError -> msg) -> Sub msg
port narrationDefaultEditUploadFileSuccess : (FileUploadSuccess -> msg) -> Sub msg
port narrationTitleStylesEditUploadFileError : (FileUploadError -> msg) -> Sub msg
port narrationTitleStylesEditUploadFileSuccess : (FileUploadSuccess -> msg) -> Sub msg
port narrationBodyTextStylesEditUploadFileError : (FileUploadError -> msg) -> Sub msg
port narrationBodyTextStylesEditUploadFileSuccess : (FileUploadSuccess -> msg) -> Sub msg
