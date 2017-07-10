module ChapterEditApp.Messages exposing (..)

import Http
import Json.Encode
import Time exposing (Time)
import Common.Models exposing (FullCharacter, Narration, Chapter, Banner, MediaType, FileUploadError, FileUploadSuccess)
import ChapterEditApp.Models exposing (LastReactions)


type Msg
    = NoOp
    | NavigateTo String
    | SetFlashMessage (Maybe Banner)
    | RemoveFlashMessage
    | ChapterFetchResult (Result Http.Error Chapter)
    | InitNewChapter Narration
    | NarrationFetchResult (Result Http.Error Narration)
    | NarrationLastReactionsFetchResult (Result Http.Error LastReactions)
    | LastReactionsFetchResult (Result Http.Error LastReactions)
    | UpdateChapterTitle String
    | UpdateEditorContent Json.Encode.Value
    | AddParticipant FullCharacter
    | RemoveParticipant FullCharacter
    | UpdateSelectedBackgroundImage String
    | UpdateSelectedAudio String
    | OpenMediaFileSelector String
    | AddMediaFile MediaType String
    | AddMediaFileError FileUploadError
    | AddMediaFileSuccess FileUploadSuccess
    | PlayPauseAudioPreview
    | SaveChapter
    | SaveChapterResult (Result Http.Error (Http.Response String))
    | SaveNewChapter
    | SaveNewChapterResult (Result Http.Error Chapter)
    | PublishChapter
    | ConfirmPublishChapter
    | CancelPublishChapter
    | PublishChapterWithTime Time
    | PublishNewChapter
    | PublishNewChapterWithTime Time
