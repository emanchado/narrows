module NarrationCreationApp.Views exposing (..)

import Html exposing (Html, main_, h1, h2, div, input, label, button, ul, li, a, text)
import Html.Attributes exposing (id, class, href, type_, placeholder, value)
import Html.Events exposing (onInput, onClick)
import NarrationCreationApp.Messages exposing (..)
import NarrationCreationApp.Models exposing (..)


mainView : Model -> Html Msg
mainView model =
    main_
        [ id "narrator-app"
        , class "app-container app-container-simple"
        ]
        [ h1 [] [ text "New narration" ]
        , label [] [ text "Title:" ]
        , div []
            [ input
                [ class "large-text-input"
                , type_ "text"
                , placeholder "Title"
                , value model.title
                , onInput UpdateTitle
                ]
                []
            ]
        , div [ class "btn-bar" ]
            [ button
                [ class "btn btn-default"
                , onClick CreateNarration
                ]
                [ text "Create" ]
            , button
                [ class "btn"
                , onClick CancelCreateNarration
                ]
                [ text "Cancel" ]
            ]
        ]
