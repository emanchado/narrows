module NarrationCreationApp exposing (..)

import Html exposing (Html)
import Core.Routes exposing (Route(..))
import NarrationCreationApp.Messages exposing (..)
import NarrationCreationApp.Models exposing (..)
import NarrationCreationApp.Update
import NarrationCreationApp.Views


type alias Model =
    NarrationCreationApp.Models.Model


type alias Msg =
    NarrationCreationApp.Messages.Msg


initialState : Model
initialState =
    { banner = Nothing
    , title = ""
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    NarrationCreationApp.Update.update


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate =
    NarrationCreationApp.Update.urlUpdate


view : Model -> Html Msg
view =
    NarrationCreationApp.Views.mainView


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
