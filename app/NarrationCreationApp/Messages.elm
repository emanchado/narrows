module NarrationCreationApp.Messages exposing (..)

import Http

import Common.Models exposing (MediaType, FileUploadError, FileUploadSuccess, Narration)
import NarrationCreationApp.Models exposing (CreateNarrationResponse)


type Msg
    = NoOp
    | UpdateTitle String
    | UpdateSelectedBackgroundImage String
    | UpdateSelectedAudio String
    | OpenMediaFileSelector String
    | AddMediaFile MediaType String
    | AddMediaFileError FileUploadError
    | AddMediaFileSuccess FileUploadSuccess
    | CreateNarration
    | CreateNarrationResult (Result Http.Error CreateNarrationResponse)
    | SaveNarration
    | SaveNarrationResult (Result Http.Error Narration)
    | FetchNarrationResult (Result Http.Error Narration)
    | CancelCreateNarration
