module NarratorApp.Messages exposing (..)

import Http

import NarratorApp.Models exposing (..)

type Msg
  = NoOp
  | ChapterFetchError Http.Error
  | ChapterFetchSuccess Chapter
  | NarrationFetchError Http.Error
  | NarrationFetchSuccess Narration
  | UpdateChapterTitle String
  | UpdateNewImageUrl String
  | AddImage
  | AddParticipant Character
  | AddParticipantError Http.RawError
  | AddParticipantSuccess Http.Response
  | RemoveParticipant Character
  | RemoveParticipantError Http.RawError
  | RemoveParticipantSuccess Http.Response
  | UpdateSelectedBackgroundImage String
  | UpdateSelectedAudio String
  | SaveChapter
  | SaveChapterError Http.RawError
  | SaveChapterSuccess Http.Response
