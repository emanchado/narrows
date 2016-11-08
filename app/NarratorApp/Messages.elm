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
  | AddParticipant Character
  | AddParticipantError Http.RawError
  | AddParticipantSuccess Http.Response
  | RemoveParticipant Character
  | RemoveParticipantError Http.RawError
  | RemoveParticipantSuccess Http.Response
  | SaveChapter
  | SaveChapterError Http.RawError
  | SaveChapterSuccess Http.Response
