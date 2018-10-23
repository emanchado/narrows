module NovelReaderApp exposing (..)

import Html exposing (Html)
import Core.Routes exposing (Route(..))
import Common.Ports
import Common.Models.Reading exposing (PageState(Loader))
import NovelReaderApp.Ports
import NovelReaderApp.Messages exposing (..)
import NovelReaderApp.Models exposing (..)
import NovelReaderApp.Update
import NovelReaderApp.Views


type alias Model =
    NovelReaderApp.Models.Model


type alias Msg =
    NovelReaderApp.Messages.Msg


initialState : Model
initialState =
    { state = Loader
    , novel = Nothing
    , currentChapterIndex = 0
    , backgroundMusic = True
    , musicPlaying = True
    , backgroundBlurriness = 0
    , banner = Nothing
    , referenceInformationVisible = False
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update =
    NovelReaderApp.Update.update


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate =
    NovelReaderApp.Update.urlUpdate


view : Model -> Html Msg
view =
    NovelReaderApp.Views.mainView


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Common.Ports.pageScrollListener PageScroll
        , Common.Ports.markNarrationAsStarted NarrationStarted
        , NovelReaderApp.Ports.receiveDeviceSettingsNovelReader ReceiveDeviceSettings
        ]
