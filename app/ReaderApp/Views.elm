module ReaderApp.Views exposing (mainView)

import Html exposing (Html, div, span, a, input, text, img, label, button, br)
import Html.Attributes exposing (id, class, for, src, href, type', checked)
import Html.Events exposing (onClick)

import ReaderApp.Models exposing (Model, Banner)
import ReaderApp.Messages exposing (..)
import ReaderApp.NarrationView
import ReaderApp.Views.Banner

loadingView : Maybe Banner -> Html Msg
loadingView maybeBanner =
  div [ id "loader-contents" ]
    [ div [ id "spinner" ] [ text "Loading…" ]
    , case maybeBanner of
        Just banner ->
          ReaderApp.Views.Banner.view banner
        Nothing ->
          text ""
    ]

loadedView : Model -> Html Msg
loadedView model =
  div [ id "loader-contents" ]
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

mainView : Model -> Html Msg
mainView model =
  div [ id "reader-app" ]
    [ case model.state of
        ReaderApp.Models.Loader ->
          div [ id "loader" ]
            [ case model.chapter of
                Just data ->
                  loadedView model
                Nothing ->
                  loadingView model.banner
            ]
        _ ->
          text ""
    , ReaderApp.NarrationView.view model
    ]
