module ChapterControlApp exposing (..)

import Html exposing (Html)
import Browser.Navigation as Nav

import Core.Routes exposing (Route(..))
import ChapterControlApp.Messages exposing (..)
import ChapterControlApp.Models exposing (..)
import ChapterControlApp.Update
import ChapterControlApp.Views


type alias Model =
    ChapterControlApp.Models.Model


type alias Msg =
    ChapterControlApp.Messages.Msg


initialState : Nav.Key -> Model
initialState key =
    { key = key
    , nowMilliseconds = -1
    , narration = Nothing
    , interactions = Nothing
    , banner = Nothing
    , reply = Nothing
    , replySending = False
    , newMessageText = ""
    , newMessageRecipients = []
    , newMessageSending = False
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    ChapterControlApp.Update.update


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate =
    ChapterControlApp.Update.urlUpdate


view : Model -> Html Msg
view =
    ChapterControlApp.Views.mainView


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
