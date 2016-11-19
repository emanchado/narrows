module ChapterEditApp.Views exposing (mainView)

import Html exposing (Html, div, span, a, input, text, img, label, button, br)
-- import Html.Attributes exposing (id, class, for, src, href, type', checked)
-- import Html.Events exposing (onClick)

import ChapterEditApp.Models exposing (Model)
import ChapterEditApp.Messages exposing (..)
import ChapterEditApp.Views.ChapterEdit

mainView : Model -> Html Msg
mainView model =
  ChapterEditApp.Views.ChapterEdit.view model
