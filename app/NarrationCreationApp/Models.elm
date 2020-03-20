module NarrationCreationApp.Models exposing (..)

import Json.Decode
import Browser.Navigation as Nav
import Common.Models exposing (Banner, FileSet)


type alias NewNarrationProperties =
    { title : String
    }


type alias NarrationUpdateProperties =
    { title : String
    , intro : Json.Decode.Value
    , introBackgroundImage : Maybe String
    , introAudio : Maybe String
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
    , intro : Json.Decode.Value
    , narrationId : Maybe Int
    , files : Maybe FileSet
    , introAudio : Maybe String
    , introBackgroundImage : Maybe String
    , introUrl : String
    , defaultAudio : Maybe String
    , defaultBackgroundImage : Maybe String
    , uploadingAudio : Bool
    , uploadingBackgroundImage : Bool
    }
