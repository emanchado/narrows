module NovelReaderApp exposing (..)

import Html exposing (Html)

import Routing
import Common.Ports
import NovelReaderApp.Messages exposing (..)
import NovelReaderApp.Models exposing (..)
import NovelReaderApp.Update
import NovelReaderApp.Views

type alias Model = NovelReaderApp.Models.Model
type alias Msg = NovelReaderApp.Messages.Msg

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

update : Msg -> Model -> (Model, Cmd Msg)
update = NovelReaderApp.Update.update

urlUpdate : Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate = NovelReaderApp.Update.urlUpdate

view : Model -> Html Msg
view = NovelReaderApp.Views.mainView

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch [ Common.Ports.pageScrollListener PageScroll
            , Common.Ports.markNarrationAsStarted NarrationStarted
            ]
