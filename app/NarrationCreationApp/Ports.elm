port module NarrationCreationApp.Ports exposing (..)

import Json.Encode
import Common.Models exposing (FileUploadError, FileUploadSuccess)

port narrationIntroContentChanged : (Json.Encode.Value -> msg) -> Sub msg
port narrationIntroEditUploadFileError : (FileUploadError -> msg) -> Sub msg
port narrationIntroEditUploadFileSuccess : (FileUploadSuccess -> msg) -> Sub msg
port narrationDefaultEditUploadFileError : (FileUploadError -> msg) -> Sub msg
port narrationDefaultEditUploadFileSuccess : (FileUploadSuccess -> msg) -> Sub msg
