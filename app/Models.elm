module Models exposing (..)

import Json.Decode

import Routing

type PageState
  = Loader
  | StartingNarration
  | Narrating
  | ActionSubmitted

type alias Character =
  { id : Int
  , name : String
  }

type alias Message =
  { id : Int
  , body : String
  , sentAt : String
  , sender : Maybe Character
  , recipients : Maybe (List Character)
  }

type alias MessageThread =
  { participants : List Character
  , messages : List Message
  }

-- Only used for JSON response decoding
type alias ChapterMessages =
  { messages : List MessageThread
  , characterId : Maybe Int
  }

type alias Chapter =
  { id : Int
  , narrationId : Int
  , title : String
  , audio : String
  , backgroundImage : String
  , text : Json.Decode.Value
  , participants : List Character
  , reaction : Maybe String
  }

type alias Banner =
  { type' : String
  , text : String
  }

type alias Model =
  { route : Routing.Route
  , state : PageState
  , chapter : Maybe Chapter
  , messageThreads : Maybe (List MessageThread)
  , backgroundMusic : Bool
  , musicPlaying : Bool
  , backgroundBlurriness : Int
  , characterId : Maybe Int
  , characterToken : String
  , newMessageText : String
  , newMessageRecipients : List Int
  , reactionSent : Bool
  , reaction : String
  , banner : Maybe Banner
  }
