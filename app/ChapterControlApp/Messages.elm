module ChapterControlApp.Messages exposing (..)

import Http

import ChapterControlApp.Models exposing (ChapterInteractions)

type Msg
  = NoOp
  | ChapterInteractionsFetchError Http.Error
  | ChapterInteractionsFetchSuccess ChapterInteractions
  | UpdateNewMessageText String
  | UpdateNewMessageRecipient Int Bool
  | SendMessage
  | SendMessageError Http.RawError
  | SendMessageSuccess Http.Response
