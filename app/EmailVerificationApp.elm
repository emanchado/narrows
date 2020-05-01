module EmailVerificationApp exposing (..)

import Html exposing (Html)
import Browser.Navigation as Nav

import Core.Routes exposing (Route(..))
import EmailVerificationApp.Messages exposing (..)
import EmailVerificationApp.Models exposing (..)
import EmailVerificationApp.Update
import EmailVerificationApp.Views


type alias Model =
    EmailVerificationApp.Models.Model


type alias Msg =
    EmailVerificationApp.Messages.Msg


initialState : Nav.Key -> Model
initialState key =
    { key = key
    , checking = False
    , error = Nothing
    , token = ""
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    EmailVerificationApp.Update.update


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate =
    EmailVerificationApp.Update.urlUpdate


view : Model -> Html Msg
view =
    EmailVerificationApp.Views.mainView


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
