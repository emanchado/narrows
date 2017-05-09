module NarrationCreationApp.Models exposing (..)

import Common.Models exposing (Banner)


type alias NarrationProperties =
    { title : String
    }


type alias CreateNarrationResponse =
    { id : Int
    , title : String
    }


type alias Model =
    { banner : Maybe Banner
    , title : String
    }
