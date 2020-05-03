module NarrationCreationApp.Models exposing (..)

import Json.Decode
import Browser.Navigation as Nav
import Common.Models exposing (Banner, FileSet, FullCharacter, NarrationStatus)


type alias StyleSet =
    { titleFont : Maybe String
    , titleFontSize : Maybe String
    , titleColor : Maybe String
    , titleShadowColor : Maybe String
    , bodyTextFont : Maybe String
    , bodyTextFontSize : Maybe String
    , bodyTextColor : Maybe String
    , bodyTextBackgroundColor : Maybe String
    , separatorImage : Maybe String
    }


type alias NarrationInternal =
    { id : Int
    , title : String
    , status : NarrationStatus
    , intro : Json.Decode.Value
    , introUrl : String
    , introAudio : Maybe String
    , introBackgroundImage : Maybe String
    , notes : String
    , characters : List FullCharacter
    , defaultAudio : Maybe String
    , defaultBackgroundImage : Maybe String
    , files : FileSet
    , styles : StyleSet
    }


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
    , styles : StyleSet
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
    , styles : StyleSet
    , uploadingAudio : Bool
    , uploadingBackgroundImage : Bool
    , uploadingImage : Bool
    , uploadingFont : Bool
    , narrationModified : Bool
    }
