module Common.Models exposing (..)

type alias Banner =
  { type' : String
  , text : String
  }

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
