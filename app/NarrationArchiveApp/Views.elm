module NarrationArchiveApp.Views exposing (..)

import List
import Html exposing (Html, main_, h1, h2, div, button, ul, li, a, text)
import Html.Attributes exposing (id, class, href)
import Common.Views exposing (linkTo, narrationOverviewView, loadingView, compactNarrationView)
import NarrationArchiveApp.Messages exposing (..)
import NarrationArchiveApp.Models exposing (..)


mainView : Model -> Html Msg
mainView model =
  main_ [ id "narrator-app"
        , class "app-container"
        ]
    [ h1 [] [ text "Narration archive" ]
    , case model.narrations of
        Just narrations ->
          div [ class "narration-list" ]
            (List.map (compactNarrationView NavigateTo) narrations)

        Nothing ->
          loadingView model.banner
    ]
