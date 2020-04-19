module ChapterEditApp.Messages exposing (..)

import Http
import Json.Encode
import Time
import Common.Models exposing (FullCharacter, Narration, Chapter, Banner, MediaType, FileUploadError, FileUploadSuccess)
import ChapterEditApp.Models exposing (LastReactionsResponse, NarrationChapterSearchResponse)


type FlashMessageType
  = ChapterSaveFlash
  | NarrationNotesSaveFlash


type Msg
    = NoOp
    | NavigateTo String
    | SetFlashMessage FlashMessageType (Maybe Banner)
    | RemoveFlashMessage FlashMessageType
    | ChapterFetchResult (Result Http.Error Chapter)
    | InitNewChapter Narration
    | NarrationFetchResult (Result Http.Error Narration)
    | NarrationLastReactionsFetchResult (Result Http.Error LastReactionsResponse)
    | LastReactionsFetchResult (Result Http.Error LastReactionsResponse)
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
    | PublishChapterWithTime Time.Posix
    | PublishNewChapter
    | PublishNewChapterWithTime Time.Posix
    | UpdateChapterSearchTerm String
    | SearchNarrationChapters String
    | NarrationChapterSearchFetchResult (Result Http.Error NarrationChapterSearchResponse)
    | UpdateNarrationNotes String
    | SaveNarrationNotes
    | SaveNarrationNotesResult (Result Http.Error Narration)
