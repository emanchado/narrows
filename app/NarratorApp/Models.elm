module NarratorApp.Models exposing (..)

import Routing

type alias Chapter =
  { text : String
  }

type alias Model =
  { route : Routing.Route
  , chapter : Maybe Chapter
  }
