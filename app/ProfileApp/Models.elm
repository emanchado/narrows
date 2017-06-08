module ProfileApp.Models exposing (..)

import Common.Models exposing (Banner, UserInfo)


type alias Model =
    { banner : Maybe Banner
    , user : Maybe UserInfo
    , newPassword : String
    }
