module NarrationCreationApp exposing (..)

import Html exposing (Html)
import Browser.Navigation as Nav
import Json.Encode

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
    , intro = Json.Encode.null
    , narrationId = Nothing
    , files = Nothing
    , introAudio = Nothing
    , introBackgroundImage = Nothing
    , introUrl = ""
    , defaultAudio = Nothing
    , defaultBackgroundImage = Nothing
    , uploadingAudio = False
    , uploadingBackgroundImage = False
    , narrationModified = False
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
    Sub.batch
        [ NarrationCreationApp.Ports.narrationIntroContentChanged UpdateIntro
        , NarrationCreationApp.Ports.narrationIntroEditUploadFileError (AddMediaFileError NarrationIntroTarget)
        , NarrationCreationApp.Ports.narrationIntroEditUploadFileSuccess (AddMediaFileSuccess NarrationIntroTarget)
        , NarrationCreationApp.Ports.narrationDefaultEditUploadFileError (AddMediaFileError NarrationDefaultTarget)
        , NarrationCreationApp.Ports.narrationDefaultEditUploadFileSuccess (AddMediaFileSuccess NarrationDefaultTarget)
        ]
