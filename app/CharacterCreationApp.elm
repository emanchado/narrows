module CharacterCreationApp exposing (..)

import Html exposing (Html)
import Core.Routes exposing (Route(..))
import CharacterCreationApp.Messages exposing (..)
import CharacterCreationApp.Models exposing (..)
import CharacterCreationApp.Update
import CharacterCreationApp.Views


type alias Model =
    CharacterCreationApp.Models.Model


type alias Msg =
    CharacterCreationApp.Messages.Msg


initialState : Model
initialState =
    { banner = Nothing
    , narrationId = 0
    , narration = Nothing
    , playerEmail = ""
    , characterName = ""
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    CharacterCreationApp.Update.update


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate =
    CharacterCreationApp.Update.urlUpdate


view : Model -> Html Msg
view =
    CharacterCreationApp.Views.mainView


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
