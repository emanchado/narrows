module Messages exposing (..)

import Http

import Models exposing (..)

type Msg
  = StartNarration
  -- The parameter is useless here, but is a subscription so it needs it
  | NarrationStarted Int
  | ChapterFetchError Http.Error
  | ChapterFetchSuccess Chapter
  | ToggleBackgroundMusic
  | PlayPauseMusic
  | PageScroll Int
  | UpdateReactionText String
  | SendReaction
  | SendReactionError Http.RawError
  | SendReactionSuccess Http.Response
