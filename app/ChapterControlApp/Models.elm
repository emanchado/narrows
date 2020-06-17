module ChapterControlApp.Models exposing (..)

import Browser.Navigation as Nav
import Common.Models exposing (Narration, Chapter, Banner, MessageThread, ReplyInformation)


type alias ChapterInteractions =
    { chapter : Chapter
    , messageThreads : List MessageThread
    }


type alias Model =
    { key : Nav.Key
    , nowMilliseconds : Int
    , narration : Maybe Narration
    , interactions : Maybe ChapterInteractions
    , banner : Maybe Banner
    , reply : Maybe ReplyInformation
    , replySending : Bool
    , newMessageText : String
    , newMessageRecipients : List Int
    , newMessageSending : Bool
    }
