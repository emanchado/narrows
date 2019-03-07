module CharacterCreationApp.Models exposing (..)

import Browser.Navigation as Nav
import Common.Models exposing (Banner, Narration)


type alias Model =
    { key : Nav.Key
    , banner : Maybe Banner
    , narrationId : Int
    , narration : Maybe Narration
    , playerEmail : String
    , characterName : String
    }
