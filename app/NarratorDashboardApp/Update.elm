module NarratorDashboardApp.Update exposing (..)

import Http

import Routing
import NarratorDashboardApp.Messages exposing (..)
import NarratorDashboardApp.Models exposing (..)


urlUpdate : Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate route model =
    case route of
      Routing.NarratorIndex ->
        ( model
        , Cmd.none
        )
      _ ->
        (model, Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)
