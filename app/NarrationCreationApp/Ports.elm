port module NarrationCreationApp.Ports exposing (..)

import Common.Models exposing (FileUploadError, FileUploadSuccess)

port narrationEditUploadFileError : (FileUploadError -> msg) -> Sub msg
port narrationEditUploadFileSuccess : (FileUploadSuccess -> msg) -> Sub msg
