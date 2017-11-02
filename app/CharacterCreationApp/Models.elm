module CharacterCreationApp.Models exposing (..)

import Common.Models exposing (Banner, Narration)


type alias Model =
    { banner : Maybe Banner
    , narrationId : Int
    , narration : Maybe Narration
    , playerEmail : String
    , characterName : String
    }
