module NarratorApp.Messages exposing (..)

import Http
import Json.Encode

import NarratorApp.Models exposing (..)

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
  | PlayPauseAudioPreview
  | SaveChapter
  | SaveChapterError Http.RawError
  | SaveChapterSuccess Http.Response
