module NarratorApp exposing (..)

import Routing
import NarratorApp.Messages exposing (..)
import NarratorApp.Models exposing (..)
import NarratorApp.Update
import NarratorApp.Views

initialState : Result String Routing.Route -> (Model, Cmd Msg)
initialState result =
  let
    model =
      { route = Routing.NotFoundRoute
      , chapter = Nothing
      }
  in
    NarratorApp.Update.urlUpdate result model

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

update = NarratorApp.Update.update
view = NarratorApp.Views.mainView

type alias Model = NarratorApp.Models.Model
type alias Msg = NarratorApp.Messages.Msg
