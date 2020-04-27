module DashboardApp exposing (..)

import Html exposing (Html)
import Browser.Navigation as Nav

import Core.Routes exposing (Route(..))
import DashboardApp.Messages exposing (..)
import DashboardApp.Models exposing (..)
import DashboardApp.Update
import DashboardApp.Views


type alias Model =
    DashboardApp.Models.Model


type alias Msg =
    DashboardApp.Messages.Msg


initialState : Nav.Key -> Model
initialState key =
    { key = key
    , banner = Nothing
    , screen = IndexScreen
    , narrations = Nothing
    , characters = Nothing
    , allNarrations = Nothing
    , allCharacters = Nothing
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    DashboardApp.Update.update


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate =
    DashboardApp.Update.urlUpdate


view : Model -> Html Msg
view =
    DashboardApp.Views.mainView


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
