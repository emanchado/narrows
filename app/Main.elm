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


initialState : Result String Routing.Route -> (Model, Cmd Msg)
initialState result =
  combinedUrlUpdate result { route = Routing.NotFoundRoute
                           , readerApp = ReaderApp.initialState
                           , narratorApp = NarratorApp.initialState
                           }

combinedUrlUpdate : Result String Routing.Route -> Model -> (Model, Cmd Msg)
combinedUrlUpdate result model =
  let
    currentRoute = Routing.routeFromResult result
    (updatedReaderModel, readerCmd) = ReaderApp.urlUpdate currentRoute model.readerApp
    (updatedNarratorModel, narratorCmd) = NarratorApp.urlUpdate currentRoute model.narratorApp
  in
    ( { model | route = currentRoute
              , readerApp = updatedReaderModel
              , narratorApp = updatedNarratorModel }
    , Cmd.batch [ Cmd.map ReaderMsg readerCmd
                , Cmd.map NarratorMsg narratorCmd ] )

combinedUpdate : Msg -> Model -> (Model, Cmd Msg)
combinedUpdate msg model =
  case msg of
    ReaderMsg readerMsg ->
      let
        (newReaderModel, cmd) = ReaderApp.update readerMsg model.readerApp
      in
        ({ model | readerApp = newReaderModel }, Cmd.map ReaderMsg cmd)
    NarratorMsg narratorMsg ->
      let
        (newNarratorModel, cmd) = NarratorApp.update narratorMsg model.narratorApp
      in
        ({ model | narratorApp = newNarratorModel }, Cmd.map NarratorMsg cmd)
    _ ->
      (model, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch [ Sub.map ReaderMsg (ReaderApp.subscriptions model.readerApp)
            ]

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
    { init = initialState
    , update = combinedUpdate
    , urlUpdate = combinedUrlUpdate
    , subscriptions = subscriptions
    , view = mainApplicationView
    }
