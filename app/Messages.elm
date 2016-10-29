module Messages exposing (..)

import Http

import Models exposing (..)

type Msg
  = StartNarration
  -- The parameter is useless here, but is a subscription so it needs it
  | NarrationStarted Int
  | ChapterFetchError Http.Error
  | ChapterFetchSuccess Chapter
  | ChapterMessagesFetchError Http.Error
  | ChapterMessagesFetchSuccess ChapterMessages
  | ToggleBackgroundMusic
  | PlayPauseMusic
  | PageScroll Int
  | UpdateReactionText String
  | SendMessage
  | UpdateNewMessageText String
  | SendReaction
  | SendReactionError Http.RawError
  | SendReactionSuccess Http.Response
