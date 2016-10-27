module Models exposing (..)

import Json.Decode

import Routing

type PageState
  = Loader
  | StartingNarration
  | Narrating
  | ActionSubmitted

type alias CharacterToken = String

type alias Participant =
  { id : Int
  , name : String
  , token : String
  }

type alias Chapter =
  { id : Int
  , narrationId : Int
  , title : String
  , audio : String
  , backgroundImage : String
  , text : Json.Decode.Value
  , participants : List Participant
  , reaction : Maybe String
  }

type alias Model =
  { route : Routing.Route
  , state : PageState
  , chapter : Maybe Chapter
  , errorMessage : Maybe String
  , backgroundMusic : Bool
  , musicPlaying : Bool
  , backgroundBlurriness : Int
  , characterToken : String
  , reactionSent : Bool
  , reaction : String
  }
