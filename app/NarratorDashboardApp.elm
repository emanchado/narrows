module NarratorDashboardApp exposing (..)

import Html exposing (Html)

import Routing
import NarratorDashboardApp.Messages exposing (..)
import NarratorDashboardApp.Models exposing (..)
import NarratorDashboardApp.Update
import NarratorDashboardApp.Views

type alias Model = NarratorDashboardApp.Models.Model
type alias Msg = NarratorDashboardApp.Messages.Msg

initialState : Model
initialState =
  { banner = Nothing
  , narrations = Nothing
  }

update : Msg -> Model -> (Model, Cmd Msg)
update = NarratorDashboardApp.Update.update

urlUpdate : Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate = NarratorDashboardApp.Update.urlUpdate

view : Model -> Html Msg
view = NarratorDashboardApp.Views.mainView

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none
