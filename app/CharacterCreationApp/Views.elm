module CharacterCreationApp.Views exposing (..)

import Html exposing (Html, main_, h1, h2, div, input, label, button, ul, li, a, text)
import Html.Attributes exposing (id, class, href, type_, placeholder, value)
import Html.Events exposing (onInput, onClick)
import CharacterCreationApp.Messages exposing (..)
import CharacterCreationApp.Models exposing (..)


mainView : Model -> Html Msg
mainView model =
    main_
        [ id "narrator-app"
        , class "app-container app-container-simple"
        ]
        [ h1 [] [ text "New character" ]
        , label [] [ text "Name:" ]
        , div []
            [ input
                [ class "large-text-input"
                , type_ "text"
                , placeholder "Name"
                , value model.characterName
                , onInput UpdateName
                ]
                []
            ]
        , label [] [ text "Email:" ]
        , div []
            [ input
                [ class "large-text-input"
                , type_ "text"
                , placeholder "Email"
                , value model.playerEmail
                , onInput UpdateEmail
                ]
                []
            ]
        , div [ class "btn-bar" ]
            [ button
                [ class "btn btn-default"
                , onClick CreateCharacter
                ]
                [ text "Create" ]
            , button
                [ class "btn"
                , onClick CancelCreateCharacter
                ]
                [ text "Cancel" ]
            ]
        ]
