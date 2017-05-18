module NarrationArchiveApp exposing (..)

import Html exposing (Html)
import Core.Routes exposing (Route(..))
import NarrationArchiveApp.Messages exposing (..)
import NarrationArchiveApp.Models exposing (..)
import NarrationArchiveApp.Update
import NarrationArchiveApp.Views


type alias Model =
    NarrationArchiveApp.Models.Model


type alias Msg =
    NarrationArchiveApp.Messages.Msg


initialState : Model
initialState =
    { banner = Nothing
    , narrations = Nothing
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    NarrationArchiveApp.Update.update


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate =
    NarrationArchiveApp.Update.urlUpdate


view : Model -> Html Msg
view =
    NarrationArchiveApp.Views.mainView


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
