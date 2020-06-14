module ReaderApp.Models exposing (..)

import Json.Decode
import Browser.Navigation as Nav

import Common.Models exposing (Character, ReplyInformation, ParticipantCharacter, MessageThread)
import Common.Models.Reading exposing (PageState)


type alias Banner =
  Common.Models.Banner


type alias OwnCharacter =
  { id : Int
  , name : String
  , token : String
  , notes : Maybe String
  }


type alias ApiErrorResponse =
  { errorMessage : String
  }


type alias Chapter =
  { id : Int
  , narrationId : Int
  , title : String
  , audio : Maybe String
  , backgroundImage : Maybe String
  , text : Json.Decode.Value
  , participants : List ParticipantCharacter
  , character : OwnCharacter
  }


type alias Model =
  { key : Nav.Key
  , state : PageState
  , chapter : Maybe Chapter
  , messageThreads : Maybe (List MessageThread)
  , backgroundMusic : Bool
  , musicPlaying : Bool
  , backgroundBlurriness : Int
  , reply : Maybe ReplyInformation
  , replySending : Bool
  , newMessageText : String
  , newMessageRecipients : List Int
  , newMessageSending : Bool
  , showReactionTip : Bool
  , banner : Maybe Banner
  , referenceInformationVisible : Bool
  }
