module NarrationOverviewApp exposing (..)

import Html exposing (Html)

import Routing
import NarrationOverviewApp.Messages exposing (..)
import NarrationOverviewApp.Models exposing (..)
import NarrationOverviewApp.Update
import NarrationOverviewApp.Views

type alias Model = NarrationOverviewApp.Models.Model
type alias Msg = NarrationOverviewApp.Messages.Msg

initialState : Model
initialState =
  { narrationOverview = Nothing
  , banner = Nothing
  , narrationNovels = Nothing
  }

update : Msg -> Model -> (Model, Cmd Msg)
update = NarrationOverviewApp.Update.update

urlUpdate : Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate = NarrationOverviewApp.Update.urlUpdate

view : Model -> Html Msg
view = NarrationOverviewApp.Views.mainView

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none
