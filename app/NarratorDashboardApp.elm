module NarratorDashboardApp exposing (..)

import Html exposing (Html)
import Browser.Navigation as Nav

import Core.Routes exposing (Route(..))
import NarratorDashboardApp.Messages exposing (..)
import NarratorDashboardApp.Models exposing (..)
import NarratorDashboardApp.Update
import NarratorDashboardApp.Views


type alias Model =
    NarratorDashboardApp.Models.Model


type alias Msg =
    NarratorDashboardApp.Messages.Msg


initialState : Nav.Key -> Model
initialState key =
    { key = key
    , banner = Nothing
    , narrations = Nothing
    , characters = Nothing
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    NarratorDashboardApp.Update.update


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate =
    NarratorDashboardApp.Update.urlUpdate


view : Model -> Html Msg
view =
    NarratorDashboardApp.Views.mainView


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
