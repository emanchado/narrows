module NarrationCreationApp.Messages exposing (..)

import Http
import Json.Encode

import Common.Models exposing (MediaType, FileUploadError, FileUploadSuccess, Narration, Banner)
import NarrationCreationApp.Models exposing (CreateNarrationResponse)


type MediaTarget = NarrationIntroTarget | NarrationDefaultTarget

type Msg
    = NoOp
    | NavigateTo String
    | UpdateTitle String
    | UpdateIntro Json.Encode.Value
    | UpdateSelectedIntroBackgroundImage String
    | UpdateSelectedIntroAudio String
    | UpdateSelectedDefaultBackgroundImage String
    | UpdateSelectedDefaultAudio String
    | OpenMediaFileSelector String
    | AddMediaFile MediaType MediaTarget String
    | AddMediaFileError MediaTarget FileUploadError
    | AddMediaFileSuccess MediaTarget FileUploadSuccess
    | PlayPauseAudioPreview
    | CreateNarration
    | CreateNarrationResult (Result Http.Error CreateNarrationResponse)
    | SaveNarration
    | SaveNarrationResult (Result Http.Error Narration)
    | FetchNarrationResult (Result Http.Error Narration)
    | CancelCreateNarration
    | SetFlashMessage (Maybe Banner)
    | RemoveFlashMessage
