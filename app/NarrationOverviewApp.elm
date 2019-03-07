module NarrationOverviewApp exposing (..)

import Html exposing (Html)
import Browser.Navigation as Nav

import Core.Routes exposing (Route(..))
import NarrationOverviewApp.Messages exposing (..)
import NarrationOverviewApp.Models exposing (..)
import NarrationOverviewApp.Update
import NarrationOverviewApp.Views


type alias Model =
    NarrationOverviewApp.Models.Model


type alias Msg =
    NarrationOverviewApp.Messages.Msg


initialState : Nav.Key -> Model
initialState key =
    { key = key
    , narrationOverview = Nothing
    , sendingPendingIntroEmails = False
    , banner = Nothing
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    NarrationOverviewApp.Update.update


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate =
    NarrationOverviewApp.Update.urlUpdate


view : Model -> Html Msg
view =
    NarrationOverviewApp.Views.mainView


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
