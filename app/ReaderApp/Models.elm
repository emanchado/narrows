module ReaderApp.Models exposing (..)

import Json.Decode

import Common.Models

type alias Banner = Common.Models.Banner

type PageState
  = Loader
  | StartingNarration
  | Narrating

type alias Character =
  { id : Int
  , name : String
  }

type alias OwnCharacter =
  { id : Int
  , name : String
  , token : String
  , notes : Maybe String
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
  , character : OwnCharacter
  }

type alias Model =
  { state : PageState
  , chapter : Maybe Chapter
  , messageThreads : Maybe (List MessageThread)
  , backgroundMusic : Bool
  , musicPlaying : Bool
  , backgroundBlurriness : Int
  , newMessageText : String
  , newMessageRecipients : List Int
  , reactionSent : Bool
  , reaction : String
  , banner : Maybe Banner
  }
