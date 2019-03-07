module ProfileApp.Models exposing (..)

import Browser.Navigation as Nav
import Common.Models exposing (Banner, UserInfo)


type alias Model =
    { key : Nav.Key
    , banner : Maybe Banner
    , user : Maybe UserInfo
    , newPassword : String
    }
