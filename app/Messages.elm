module Messages exposing (..)

import Http

import Models exposing (..)

type Msg
  = StartNarration
  | MarkNarrationStarted
  | ChapterFetchError Http.Error
  | ChapterFetchSuccess Chapter
  | ToggleBackgroundMusic
  | PlayPauseMusic
  | PageScroll Int
  | UpdateReactionText String
  | SendReaction
  | SendReactionError Http.RawError
  | SendReactionSuccess Http.Response
