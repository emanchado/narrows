module ReaderApp.Messages exposing (..)

import Http
import Common.Models exposing (Character)
import ReaderApp.Models exposing (..)


type Msg
    = NavigateTo String
    | StartNarration
      -- The parameter is useless here, but is a subscription so it needs it
    | NarrationStarted Int
    | ChapterFetchResult (Result Http.Error Chapter)
    | ChapterMessagesFetchResult (Result Http.Error ChapterMessages)
    | ToggleBackgroundMusic
    | PlayPauseMusic
    | PageScroll Int
    | UpdateNotesText String
    | SendNotes
    | SendNotesResult (Result Http.Error String)
    | ShowReply (List Character)
    | UpdateReplyText String
    | SendReply
    | SendReplyResult (Result Http.Error ChapterMessages)
    | CloseReply
    | ShowNewMessageUi
    | HideNewMessageUi
    | UpdateNewMessageText String
    | UpdateNewMessageRecipient Int Bool
    | SendMessage
    | SendMessageResult (Result Http.Error ChapterMessages)
    | UpdateReactionText String
    | SendReaction
    | SendReactionResult (Result Http.Error (Http.Response String))
    | ShowReferenceInformation
    | HideReferenceInformation
