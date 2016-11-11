module NarratorApp.Models exposing (..)

import Json.Decode

import Routing

type alias Character =
  { id : Int
  , name : String
  , token : String
  }

type alias FileSet =
  { audio : List String
  , backgroundImages : List String
  , images : List String
  }

type alias Narration =
  { id : Int
  , title : String
  , characters : List Character
  , defaultAudio : Maybe String
  , defaultBackgroundImage : Maybe String
  , files : FileSet
  }

type alias Chapter =
  { id : Int
  , narrationId : Int
  , title : String
  , audio : Maybe String
  , backgroundImage : Maybe String
  , text : Json.Decode.Value
  , participants : List Character
  , published : Maybe String
  }

type alias Banner =
  { type' : String
  , text : String
  }

type alias Model =
  { chapter : Maybe Chapter
  , narration : Maybe Narration
  , banner : Maybe Banner
  , newImageUrl : String
  }
