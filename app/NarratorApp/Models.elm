module NarratorApp.Models exposing (..)

import Json.Decode

import Routing

type alias Character =
  { id : Int
  , name : String
  }

type alias Chapter =
  { id : Int
  , narrationId : Int
  , title : String
  , audio : String
  , backgroundImage : String
  , text : Json.Decode.Value
  , participants : List Character
  , published : String
  }

type alias Banner =
  { type' : String
  , text : String
  }

type alias Model =
  { chapter : Maybe Chapter
  , banner : Maybe Banner
  }
