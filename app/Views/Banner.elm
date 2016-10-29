module Views.Banner exposing (view)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class)

import Messages exposing (..)
import Models exposing (Banner)

view : Banner -> Html Msg
view banner =
  div [ class ("banner banner-" ++ banner.type') ]
    [ text banner.text ]
