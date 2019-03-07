module ReaderApp.Views exposing (mainView)

import Html exposing (Html, div, span, a, input, text, img, label, button, br)
import Html.Attributes exposing (id, class, for, src, href, type_, checked)
import Html.Events exposing (onClick)
import Common.Views exposing (bannerView, loadingView)
import Common.Models.Reading exposing (PageState(..))
import ReaderApp.Models exposing (Model, Banner, Chapter)
import ReaderApp.Messages exposing (..)
import ReaderApp.Views.Narration


loadedView : Chapter -> Bool -> Html Msg
loadedView chapter backgroundMusicOn =
  div [ id "loader-contents" ]
    [ div [ id "start-ui" ]
        [ button [ onClick StartNarration ]
            [ text "Start" ]
        , case chapter.audio of
            Just _ ->
              div []
                [ input [ id "music"
                        , type_ "checkbox"
                        , checked backgroundMusicOn
                        , onClick ToggleBackgroundMusic
                        ]
                    []
                , label [ for "music" ] [ text "Background music" ]
                ]
            Nothing ->
              text ""
        ]
    ]


mainView : Model -> Html Msg
mainView model =
  div [ id "reader-app" ]
    [ case model.state of
        Loader ->
          div [ id "loader" ]
            [ case model.chapter of
                Just chapter ->
                  loadedView chapter model.backgroundMusic
                Nothing ->
                  div [ id "loader-contents" ]
                    [ loadingView model.banner ]
            ]

        _ ->
          text ""
    , ReaderApp.Views.Narration.view model
    ]
