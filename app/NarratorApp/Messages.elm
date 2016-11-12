module NarratorApp.Messages exposing (..)

import Http
import Json.Encode

import Common.Models exposing (Character, Narration)
import NarratorApp.Models exposing (..)
import NarratorApp.Ports

type Msg
  = NoOp
  | ChapterFetchError Http.Error
  | ChapterFetchSuccess Chapter
  | NarrationFetchError Http.Error
  | NarrationFetchSuccess Narration
  | UpdateChapterTitle String
  | UpdateEditorContent Json.Encode.Value
  | UpdateNewImageUrl String
  | AddImage
  | AddNewMentionCharacter Character
  | RemoveNewMentionCharacter Character
  | AddMention
  | AddParticipant Character
  | AddParticipantError Http.RawError
  | AddParticipantSuccess Http.Response
  | RemoveParticipant Character
  | RemoveParticipantError Http.RawError
  | RemoveParticipantSuccess Http.Response
  | UpdateSelectedBackgroundImage String
  | UpdateSelectedAudio String
  | OpenMediaFileSelector String
  | AddMediaFile String
  | AddMediaFileError NarratorApp.Ports.FileUploadError
  | AddMediaFileSuccess NarratorApp.Ports.FileUploadSuccess
  | PlayPauseAudioPreview
  | SaveChapter
  | SaveChapterError Http.RawError
  | SaveChapterSuccess Http.Response
