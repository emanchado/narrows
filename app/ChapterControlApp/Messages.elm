module ChapterControlApp.Messages exposing (..)

import Http

import Common.Models exposing (Character, Narration)
import ChapterControlApp.Models exposing (ChapterInteractions)

type Msg
  = NoOp
  | NavigateTo String
  | ChapterInteractionsFetchError Http.Error
  | ChapterInteractionsFetchSuccess ChapterInteractions
  | NarrationFetchError Http.Error
  | NarrationFetchSuccess Narration
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
