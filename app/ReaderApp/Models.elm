module ReaderApp.Models exposing (..)

import Json.Decode

import Common.Models exposing (Character, ReplyInformation)

type alias Banner = Common.Models.Banner

type PageState
  = Loader
  | StartingNarration
  | Narrating

type alias ParticipantCharacter =
  { id : Int
  , name : String
  , avatar : Maybe String
  , description : Json.Decode.Value
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
  , participants : List ParticipantCharacter
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
  , reply : Maybe ReplyInformation
  , showNewMessageUi : Bool
  , newMessageText : String
  , newMessageRecipients : List Int
  , reactionSent : Bool
  , reaction : String
  , banner : Maybe Banner
  , referenceInformationVisible : Bool
  }
