module NovelReaderApp.Messages exposing (..)

import Http

import NovelReaderApp.Models exposing (Novel)
import NovelReaderApp.Models exposing (..)

type Msg
  = NavigateTo String
  | StartNarration
  -- The parameter is useless here, but is a subscription so it needs it
  | NarrationStarted Int
  | NovelFetchError Http.Error
  | NovelFetchSuccess Novel
  | ToggleBackgroundMusic
  | PlayPauseMusic
  | PageScroll Int
  | NextChapter
  | PreviousChapter
  | ShowReferenceInformation
  | HideReferenceInformation
