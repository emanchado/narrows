module EmailVerificationApp.Models exposing (..)

import Browser.Navigation as Nav
import Common.Models exposing (Banner, UserInfo)


type alias Model =
    { key : Nav.Key
    , checking : Bool
    , error : Maybe Banner
    , token : String
    }
