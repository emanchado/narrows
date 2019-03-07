module ProfileApp exposing (..)

import Html exposing (Html)
import Browser.Navigation as Nav

import Core.Routes exposing (Route(..))
import ProfileApp.Messages exposing (..)
import ProfileApp.Models exposing (..)
import ProfileApp.Update
import ProfileApp.Views


type alias Model =
    ProfileApp.Models.Model


type alias Msg =
    ProfileApp.Messages.Msg


initialState : Nav.Key -> Model
initialState key =
    { key = key
    , banner = Nothing
    , user = Nothing
    , newPassword = ""
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    ProfileApp.Update.update


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate =
    ProfileApp.Update.urlUpdate


view : Model -> Html Msg
view =
    ProfileApp.Views.mainView


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
