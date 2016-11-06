module NarratorApp.Views exposing (mainView)

import Html exposing (Html, div, span, a, input, text, img, label, button, br)
-- import Html.Attributes exposing (id, class, for, src, href, type', checked)
-- import Html.Events exposing (onClick)

import NarratorApp.Models exposing (Model)
import NarratorApp.Messages exposing (..)
import NarratorApp.Views.ChapterEdit

mainView : Model -> Html Msg
mainView model =
  NarratorApp.Views.ChapterEdit.view model
