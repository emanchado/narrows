module NarratorDashboardApp.Views exposing (..)

import List
import Html exposing (Html, main_, h1, h2, div, button, ul, li, a, text)
import Html.Attributes exposing (id, class, href)
import Html.Events exposing (onClick)
import Common.Views exposing (loadingView, compactNarrationView)
import NarratorDashboardApp.Messages exposing (..)
import NarratorDashboardApp.Models exposing (..)


mainView : Model -> Html Msg
mainView model =
  main_ [ id "narrator-app"
        , class "app-container"
        ]
    [ h1 [] [ text "Active narrations" ]
    , case model.narrations of
        Just narrations ->
          div [ class "narration-list" ]
            (List.map (compactNarrationView NavigateTo) narrations)

        Nothing ->
          loadingView model.banner
    , div [ class "btn-bar" ]
        [ button [ class "btn"
                 , onClick NarrationArchive
                 ]
            [ text "Narration Archive" ]
        , button [ class "btn btn-add"
                 , onClick NewNarration
                 ]
            [ text "New narration" ]
        ]
    ]
