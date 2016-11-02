import Navigation

import Html.App as App
import Html exposing (Html, div, span, a, input, text, img, label, button, br)

import Routing
import ReaderApp
import NarratorApp

type alias Model =
  { route : Routing.Route
  , readerApp : ReaderApp.Model
  , narratorApp : NarratorApp.Model
  }

type Msg
  = NoOp
  | ReaderMsg ReaderApp.Msg
  | NarratorMsg NarratorApp.Msg

notFoundView : Html Msg
notFoundView =
  div []
    [ div [] [ text "404 Not Found" ]
    ]

mainApplicationView : Model -> Html Msg
mainApplicationView model =
  case model.route of
    Routing.ChapterReaderPage chapterId characterToken ->
      App.map ReaderMsg (ReaderApp.view model.readerApp)
    Routing.ChapterNarratorPage chapterId ->
      App.map NarratorMsg (NarratorApp.view model.narratorApp)
    Routing.NotFoundRoute ->
      notFoundView

main : Program Never
main =
  Navigation.program Routing.parser
    { init = ReaderApp.initialState
    , view = ReaderApp.view
    , update = ReaderApp.update
    , urlUpdate = ReaderApp.urlUpdate
    , subscriptions = ReaderApp.subscriptions
    }
