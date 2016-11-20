module ChapterControlApp.Messages exposing (..)

import Http

import ChapterControlApp.Models exposing (ChapterInteractions)

type Msg
  = NoOp
  | ChapterInteractionsFetchError Http.Error
  | ChapterInteractionsFetchSuccess ChapterInteractions
  -- | ChapterFetchError Http.Error
  -- | ChapterFetchSuccess Chapter
