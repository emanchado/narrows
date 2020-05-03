module NarrationCreationApp.Messages exposing (..)

import Http
import Json.Encode

import Common.Models exposing (MediaType, FileUploadError, FileUploadSuccess, Narration, Banner)
import NarrationCreationApp.Models exposing (CreateNarrationResponse, NarrationInternal)


type MediaTarget
  = NarrationIntroTarget
  | NarrationDefaultTarget
  | NarrationTitleStylesTarget
  | NarrationBodyTextStylesTarget

type Msg
    = NoOp
    | NavigateTo String
    | UpdateTitle String
    | UpdateIntro Json.Encode.Value
    | UpdateSelectedIntroBackgroundImage String
    | UpdateSelectedIntroAudio String
    | UpdateSelectedDefaultBackgroundImage String
    | UpdateSelectedDefaultAudio String
    | UpdateSelectedTitleFont String
    | ToggleCustomTitleFontSize
    | UpdateTitleFontSize String
    | ToggleCustomTitleColor
    | UpdateTitleColor String
    | ToggleCustomTitleShadowColor
    | UpdateTitleShadowColor String
    | UpdateSelectedBodyTextFont String
    | ToggleCustomBodyTextFontSize
    | UpdateBodyTextFontSize String
    | ToggleCustomBodyTextColor
    | UpdateBodyTextColor String
    | ToggleCustomBodyTextBackgroundColor
    | UpdateBodyTextBackgroundColor String
    | UpdateSelectedSeparatorImage String
    | OpenMediaFileSelector String
    | AddMediaFile MediaType MediaTarget String
    | AddMediaFileError MediaTarget FileUploadError
    | AddMediaFileSuccess MediaTarget FileUploadSuccess
    | PlayPauseAudioPreview
    | CreateNarration
    | CreateNarrationResult (Result Http.Error CreateNarrationResponse)
    | SaveNarration
    | SaveNarrationResult (Result Http.Error NarrationInternal)
    | FetchNarrationResult (Result Http.Error NarrationInternal)
    | CancelCreateNarration
    | SetFlashMessage (Maybe Banner)
    | RemoveFlashMessage
