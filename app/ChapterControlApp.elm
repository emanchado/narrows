module ChapterControlApp exposing (..)

import Html exposing (Html)

import Routing
import ChapterControlApp.Messages exposing (..)
import ChapterControlApp.Models exposing (..)
import ChapterControlApp.Update
import ChapterControlApp.Views

type alias Model = ChapterControlApp.Models.Model
type alias Msg = ChapterControlApp.Messages.Msg

initialState : Model
initialState =
  { narration = Nothing
  , interactions = Nothing
  , banner = Nothing
  }

update : Msg -> Model -> (Model, Cmd Msg)
update = ChapterControlApp.Update.update

urlUpdate : Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate = ChapterControlApp.Update.urlUpdate

view : Model -> Html Msg
view = ChapterControlApp.Views.mainView

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none
