module ChapterControlApp.Messages exposing (..)

import Http
import Common.Models exposing (Character, Narration, ChapterMessages)
import ChapterControlApp.Models exposing (ChapterInteractions)


type Msg
    = NoOp
    | NavigateTo String
    | ChapterInteractionsFetchResult (Result Http.Error ChapterInteractions)
    | NarrationFetchResult (Result Http.Error Narration)
    | UpdateNewMessageText String
    | UpdateNewMessageRecipient Int Bool
    | ShowReply (List Character)
    | UpdateReplyText String
    | SendReply
    | SendReplyResult (Result Http.Error ChapterMessages)
    | CloseReply
    | SendMessage
    | SendMessageResult (Result Http.Error ChapterMessages)
