module ChapterControlApp.Models exposing (..)

import Common.Models exposing (Narration, Chapter, Banner, Character, MessageThread, ReplyInformation)


type alias ChapterInteractions =
    { chapter : Chapter
    , messageThreads : List MessageThread
    }


type alias Model =
    { narration : Maybe Narration
    , interactions : Maybe ChapterInteractions
    , banner : Maybe Banner
    , reply : Maybe ReplyInformation
    , replySending : Bool
    , newMessageText : String
    , newMessageRecipients : List Int
    , newMessageSending : Bool
    }
