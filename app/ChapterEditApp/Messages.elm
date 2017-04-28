module ChapterEditApp.Messages exposing (..)

import Http
import Json.Encode
import Time exposing (Time)

import Common.Models exposing (FullCharacter, Narration, Chapter, Banner)
import ChapterEditApp.Models exposing (LastReactions)
import ChapterEditApp.Ports

type Msg
  = NoOp
  | SetFlashMessage (Maybe Banner)
  | RemoveFlashMessage
  | ChapterFetchError Http.Error
  | ChapterFetchSuccess Chapter
  | NarrationFetchError Http.Error
  | NarrationFetchSuccess Narration
  | LastReactionsFetchError Http.Error
  | LastReactionsFetchSuccess LastReactions
  | UpdateChapterTitle String
  | UpdateEditorContent Json.Encode.Value
  | AddParticipant FullCharacter
  | RemoveParticipant FullCharacter
  | UpdateSelectedBackgroundImage String
  | UpdateSelectedAudio String
  | OpenMediaFileSelector String
  | AddMediaFile String
  | AddMediaFileError ChapterEditApp.Ports.FileUploadError
  | AddMediaFileSuccess ChapterEditApp.Ports.FileUploadSuccess
  | PlayPauseAudioPreview
  | SaveChapter
  | SaveChapterError Http.RawError
  | SaveChapterSuccess Http.Response
  | SaveNewChapter
  | SaveNewChapterError Http.RawError
  | SaveNewChapterSuccess Http.Response
  | PublishChapter
  | PublishChapterWithTime Time
  | PublishNewChapter
  | PublishNewChapterWithTime Time
