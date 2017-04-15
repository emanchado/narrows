module CharacterCreationApp.Models exposing (..)

import Common.Models exposing (Banner)

type alias Model =
  { banner : Maybe Banner
  , narrationId : Int
  , playerEmail : String
  , characterName : String
  }
