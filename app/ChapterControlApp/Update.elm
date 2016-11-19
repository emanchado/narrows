module ChapterControlApp.Update exposing (..)

import Http

import Routing
-- import ChapterControlApp.Api
import ChapterControlApp.Messages exposing (..)
import ChapterControlApp.Models exposing (..)


urlUpdate : Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate route model =
    case route of
      Routing.NarrationPage narrationId ->
        ( model
        , Cmd.none -- ChapterControlApp.Api.fetchNarrationInfo narrationId
        )
      _ ->
        (model, Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)
