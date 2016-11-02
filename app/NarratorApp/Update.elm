module NarratorApp.Update exposing (..)

import Routing
-- import NarratorApp.Api
import NarratorApp.Messages exposing (..)
import NarratorApp.Models exposing (..)


urlUpdate : Result String Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate result model =
  let
    currentRoute =
      Routing.routeFromResult result
  in
    ({ model | route = currentRoute }, Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp -> (model, Cmd.none)
