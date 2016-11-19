import Navigation

import Html.App as App
import Html exposing (Html, div, span, a, input, text, img, label, button, br)

import Routing
import ReaderApp
import ChapterEditApp
import NarrationOverviewApp

type alias Model =
  { route : Routing.Route
  , readerApp : ReaderApp.Model
  , chapterEditApp : ChapterEditApp.Model
  , narrationOverviewApp : NarrationOverviewApp.Model
  }

type Msg
  = NoOp
  | ReaderMsg ReaderApp.Msg
  | ChapterEditMsg ChapterEditApp.Msg
  | NarrationOverviewMsg NarrationOverviewApp.Msg


initialState : Result String Routing.Route -> (Model, Cmd Msg)
initialState result =
  combinedUrlUpdate result { route = Routing.NotFoundRoute
                           , readerApp = ReaderApp.initialState
                           , chapterEditApp = ChapterEditApp.initialState
                           , narrationOverviewApp = NarrationOverviewApp.initialState
                           }

combinedUrlUpdate : Result String Routing.Route -> Model -> (Model, Cmd Msg)
combinedUrlUpdate result model =
  let
    currentRoute = Routing.routeFromResult result
    (updatedReaderModel, readerCmd) = ReaderApp.urlUpdate currentRoute model.readerApp
    (updatedNarratorModel, narratorCmd) = ChapterEditApp.urlUpdate currentRoute model.chapterEditApp
    (updatedNarrationOverviewModel, narrationOverviewCmd) = NarrationOverviewApp.urlUpdate currentRoute model.narrationOverviewApp
  in
    ( { model | route = currentRoute
              , readerApp = updatedReaderModel
              , chapterEditApp = updatedNarratorModel
              , narrationOverviewApp = updatedNarrationOverviewModel }
    , Cmd.batch [ Cmd.map ReaderMsg readerCmd
                , Cmd.map ChapterEditMsg narratorCmd
                , Cmd.map NarrationOverviewMsg narrationOverviewCmd
                ]
    )

combinedUpdate : Msg -> Model -> (Model, Cmd Msg)
combinedUpdate msg model =
  case msg of
    ReaderMsg readerMsg ->
      let
        (newReaderModel, cmd) = ReaderApp.update readerMsg model.readerApp
      in
        ({ model | readerApp = newReaderModel }, Cmd.map ReaderMsg cmd)
    ChapterEditMsg chapterEditMsg ->
      let
        (newNarratorModel, cmd) = ChapterEditApp.update chapterEditMsg model.chapterEditApp
      in
        ({ model | chapterEditApp = newNarratorModel }, Cmd.map ChapterEditMsg cmd)
    NarrationOverviewMsg narrationOverviewMsg ->
      let
        (newNarrationOverviewModel, cmd) = NarrationOverviewApp.update narrationOverviewMsg model.narrationOverviewApp
      in
        ({ model | narrationOverviewApp = newNarrationOverviewModel }, Cmd.map NarrationOverviewMsg cmd)
    _ ->
      (model, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch [ Sub.map ReaderMsg (ReaderApp.subscriptions model.readerApp)
            , Sub.map ChapterEditMsg (ChapterEditApp.subscriptions model.chapterEditApp)
            , Sub.map NarrationOverviewMsg (NarrationOverviewApp.subscriptions model.narrationOverviewApp)
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
      App.map ChapterEditMsg (ChapterEditApp.view model.chapterEditApp)
    Routing.CreateChapterPage narrationId ->
      App.map ChapterEditMsg (ChapterEditApp.view model.chapterEditApp)
    Routing.NarrationPage narrationId ->
      App.map NarrationOverviewMsg (NarrationOverviewApp.view model.narrationOverviewApp)
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
