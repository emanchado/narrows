module ChapterControlApp.Messages exposing (..)

import Http

import Common.Models exposing (Character)
import ChapterControlApp.Models exposing (ChapterInteractions)

type Msg
  = NoOp
  | ChapterInteractionsFetchError Http.Error
  | ChapterInteractionsFetchSuccess ChapterInteractions
  | UpdateNewMessageText String
  | UpdateNewMessageRecipient Int Bool
  | ShowReply (List Character)
  | UpdateReplyText String
  | SendReply
  | SendReplyError Http.RawError
  | SendReplySuccess Http.Response
  | CloseReply
  | SendMessage
  | SendMessageError Http.RawError
  | SendMessageSuccess Http.Response
