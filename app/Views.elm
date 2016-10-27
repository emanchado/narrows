module Views exposing (mainApplicationView)

import Html exposing (Html, div, span, a, input, text, img, label, button, br)
import Html.Attributes exposing (id, class, for, src, href, type', checked)
import Html.Events exposing (onClick)

import Routing
import Models exposing (Model)
import Messages exposing (..)
import NarrationView

notFoundView : Html Msg
notFoundView =
  div []
    [ div [] [ text "404 Not Found" ]
    ]

loadingView : Html Msg
loadingView =
  div [ id "loader" ]
    [ div [ id "spinner" ] [ text "Loading…" ] ]

loadedView : Model -> Html Msg
loadedView model =
  div [ id "loader" ]
    [ div [ id "start-ui" ]
        [ button [ onClick StartNarration ]
            [ text "Start" ]
        , br [] []
        , input
            [ id "music"
            , type' "checkbox"
            , checked model.backgroundMusic
            , onClick ToggleBackgroundMusic
            ]
            []
        , label [ for "music" ] [ text "Background music" ]
        ]
    ]

validView : Model -> Html Msg
validView model =
  div []
    [ case model.state of
        Models.Loader ->
          case model.chapter of
            Just data ->
              loadedView model
            Nothing ->
              loadingView
        _ ->
          text ""
    , NarrationView.view model
    ]

mainApplicationView : Model -> Html Msg
mainApplicationView model =
  case model.route of
    Routing.ChapterPage chapterId characterToken ->
      validView model
    Routing.NotFoundRoute ->
      notFoundView
