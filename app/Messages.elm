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
  | UpdateNotesText String
  | SendNotes
  | SendNotesError Http.RawError
  | SendNotesSuccess Http.Response
  | UpdateNewMessageText String
  | UpdateNewMessageRecipient Int Bool
  | SendMessage
  | SendMessageError Http.RawError
  | SendMessageSuccess Http.Response
  | UpdateReactionText String
  | SendReaction
  | SendReactionError Http.RawError
  | SendReactionSuccess Http.Response
