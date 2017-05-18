module NarratorDashboardApp.Views exposing (..)

import List
import Html exposing (Html, main_, h1, h2, div, button, ul, li, a, text)
import Html.Attributes exposing (id, class, href)
import Html.Events exposing (onClick)
import Common.Models exposing (NarrationOverview, ChapterOverview)
import Common.Views exposing (linkTo, narrationOverviewView, loadingView)
import NarratorDashboardApp.Messages exposing (..)
import NarratorDashboardApp.Models exposing (..)


narrationView : NarrationOverview -> Html Msg
narrationView overview =
    div [ class "narration-container" ]
        [ div [ class "narration-header" ]
            [ h2 []
                [ a
                    (linkTo
                        NavigateTo
                        ("/narrations/" ++ (toString overview.narration.id))
                    )
                    [ text overview.narration.title ]
                ]
            , button
                [ class "btn btn-add"
                , onClick (NavigateTo <| "/narrations/" ++ (toString overview.narration.id) ++ "/new")
                ]
                [ text "New chapter" ]
            ]
        , ul [ class "chapter-list" ] <|
            narrationOverviewView NavigateTo overview
        ]


mainView : Model -> Html Msg
mainView model =
    main_
        [ id "narrator-app"
        , class "app-container"
        ]
        [ h1 [] [ text "Narrations" ]
        , case model.narrations of
            Just narrations ->
                div [ class "narration-list" ]
                    (List.map narrationView narrations)

            Nothing ->
                loadingView model.banner
        , div [ class "btn-bar" ]
            [ button
                [ class "btn btn-add"
                , onClick NewNarration
                ]
                [ text "New narration" ]
            ]
        ]
