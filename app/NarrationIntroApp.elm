module NarrationIntroApp exposing (..)

import Html exposing (Html)
import Browser.Navigation as Nav

import Core.Routes exposing (Route(..))
import Common.Ports
import Common.Models.Reading exposing (PageState(..))
import NarrationIntroApp.Messages exposing (..)
import NarrationIntroApp.Models exposing (..)
import NarrationIntroApp.Update
import NarrationIntroApp.Views


type alias Model =
    NarrationIntroApp.Models.Model


type alias Msg =
    NarrationIntroApp.Messages.Msg


initialState : Nav.Key -> Model
initialState key =
    { key = key
    , state = Loader
    , banner = Nothing
    , session = Nothing
    , narrationToken = ""
    , narrationIntro = Nothing
    , backgroundMusic = True
    , musicPlaying = True
    , backgroundBlurriness = 0
    , email = ""
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    NarrationIntroApp.Update.update


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate =
    NarrationIntroApp.Update.urlUpdate


view : Model -> Html Msg
view =
    NarrationIntroApp.Views.mainView


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ Common.Ports.pageScrollListener PageScroll
    , Common.Ports.markNarrationAsStarted NarrationStarted
    ]
