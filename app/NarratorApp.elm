module NarratorApp exposing (..)

import Html exposing (Html)

import Routing
import NarratorApp.Messages exposing (..)
import NarratorApp.Models exposing (..)
import NarratorApp.Update
import NarratorApp.Views

type alias Model = NarratorApp.Models.Model
type alias Msg = NarratorApp.Messages.Msg

initialState : Model
initialState =
  { chapter = Nothing
  , narration = Nothing
  , banner = Nothing
  , newImageUrl = ""
  }

update : Msg -> Model -> (Model, Cmd Msg)
update = NarratorApp.Update.update

urlUpdate : Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate = NarratorApp.Update.urlUpdate

view : Model -> Html Msg
view = NarratorApp.Views.mainView

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none
