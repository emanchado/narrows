module ChapterControlApp.Models exposing (..)

import Common.Models exposing (Narration, Chapter, Banner, Character, MessageThread, Reaction, ReplyInformation)


type alias ChapterInteractions =
    { chapter : Chapter
    , reactions : List Reaction
    , messageThreads : List MessageThread
    }


type alias Model =
    { narration : Maybe Narration
    , interactions : Maybe ChapterInteractions
    , banner : Maybe Banner
    , reply : Maybe ReplyInformation
    , newMessageText : String
    , newMessageRecipients : List Int
    }
