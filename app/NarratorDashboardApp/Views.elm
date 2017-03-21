module NarratorDashboardApp.Views exposing (..)

import List
import Html exposing (Html, main', h1, div, ul, li, a, text)
import Html.Attributes exposing (id, class, href)

import NarratorDashboardApp.Messages exposing (..)
import NarratorDashboardApp.Models exposing (..)

loadingView : Model -> Html Msg
loadingView model =
  case model.banner of
    Just banner ->
      div [ class ("banner banner-" ++ banner.type') ]
        [ text banner.text ]
    Nothing ->
      div [] [ text "Loading" ]

mainView : Model -> Html Msg
mainView model =
  div [] [ text "Dashboard" ]
