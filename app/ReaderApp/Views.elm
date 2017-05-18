module ReaderApp.Views exposing (mainView)

import Html exposing (Html, div, span, a, input, text, img, label, button, br)
import Html.Attributes exposing (id, class, for, src, href, type_, checked)
import Html.Events exposing (onClick)
import Common.Views exposing (bannerView, loadingView)
import ReaderApp.Models exposing (Model, Banner)
import ReaderApp.Messages exposing (..)
import ReaderApp.Views.Narration


loadedView : Model -> Html Msg
loadedView model =
    div [ id "loader-contents" ]
        [ div [ id "start-ui" ]
            [ button [ onClick StartNarration ]
                [ text "Start" ]
            , br [] []
            , input
                [ id "music"
                , type_ "checkbox"
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
                        div [ id "loader-contents" ]
                          [ loadingView model.banner
                          ]
                ]

          _ ->
              text ""
      , ReaderApp.Views.Narration.view model
      ]
