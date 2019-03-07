module NarrationCreationApp exposing (..)

import Html exposing (Html)
import Browser.Navigation as Nav

import Core.Routes exposing (Route(..))
import NarrationCreationApp.Messages exposing (..)
import NarrationCreationApp.Models exposing (..)
import NarrationCreationApp.Update
import NarrationCreationApp.Views
import NarrationCreationApp.Ports


type alias Model =
    NarrationCreationApp.Models.Model


type alias Msg =
    NarrationCreationApp.Messages.Msg


initialState : Nav.Key -> Model
initialState key =
    { key = key
    , banner = Nothing
    , title = ""
    , narrationId = Nothing
    , files = Nothing
    , defaultAudio = Nothing
    , defaultBackgroundImage = Nothing
    , uploadingAudio = False
    , uploadingBackgroundImage = False
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
    Sub.batch [ NarrationCreationApp.Ports.narrationEditUploadFileError AddMediaFileError
              , NarrationCreationApp.Ports.narrationEditUploadFileSuccess AddMediaFileSuccess
              ]
