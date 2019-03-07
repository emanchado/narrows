module NarrationCreationApp.Models exposing (..)

import Browser.Navigation as Nav
import Common.Models exposing (Banner, FileSet)


type alias NewNarrationProperties =
    { title : String
    }


type alias NarrationUpdateProperties =
    { title : String
    , defaultBackgroundImage : Maybe String
    , defaultAudio : Maybe String
    }


type alias FetchNarrationResponse =
    { id : Int
    , title : String
    }


type alias CreateNarrationResponse =
    { id : Int
    , title : String
    }


type alias Model =
    { key : Nav.Key
    , banner : Maybe Banner
    , title : String
    , narrationId : Maybe Int
    , files : Maybe FileSet
    , defaultAudio : Maybe String
    , defaultBackgroundImage : Maybe String
    , uploadingAudio : Bool
    , uploadingBackgroundImage : Bool
    }
