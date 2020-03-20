module NarrationIntroApp.Models exposing (..)

import Browser.Navigation as Nav
import Json.Decode

import Common.Models exposing (Banner, ParticipantCharacter, UserSession)
import Common.Models.Reading exposing (PageState)


type alias NarrationIntroResponse =
    { id : Int
    , title : String
    , characters : List ParticipantCharacter
    , intro : Json.Decode.Value
    , backgroundImage : Maybe String
    , audio : Maybe String
    }


type alias Model =
    { key : Nav.Key
    , state : PageState
    , banner : Maybe Banner
    , session : Maybe UserSession
    , narrationToken : String
    , narrationIntro : Maybe NarrationIntroResponse
    , backgroundMusic : Bool
    , musicPlaying : Bool
    , backgroundBlurriness : Int
    , email : String
    }
