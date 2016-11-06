module NarratorApp.Messages exposing (..)

import Http

import NarratorApp.Models exposing (..)

type Msg
  = NoOp
  | ChapterFetchError Http.Error
  | ChapterFetchSuccess Chapter
  | UpdateChapterTitle String
  | SaveChapter
  | SaveChapterError Http.RawError
  | SaveChapterSuccess Http.Response
