module CharacterApp exposing (..)

import Html exposing (Html)

import Routing
import CharacterApp.Messages exposing (..)
import CharacterApp.Models exposing (..)
import CharacterApp.Update
import CharacterApp.Views

type alias Model = CharacterApp.Models.Model
type alias Msg = CharacterApp.Messages.Msg

initialState : Model
initialState =
  { characterToken = ""
  , characterInfo = Nothing
  , banner = Nothing
  }

update : Msg -> Model -> (Model, Cmd Msg)
update = CharacterApp.Update.update

urlUpdate : Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate = CharacterApp.Update.urlUpdate

view : Model -> Html Msg
view = CharacterApp.Views.mainView

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none
