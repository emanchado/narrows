module NarratorApp.Views.ChapterEdit exposing (..)

import Html exposing (Html, div, main', nav, section, a, input, button, text)
import Html.Attributes exposing (id, class, href, type', value, placeholder, checked, disabled)
-- import Html.Events exposing (onClick)

import NarratorApp.Models exposing (Model, Chapter)
import NarratorApp.Messages exposing (..)

view : Model -> Html Msg
view model =
  let
    chapterTitle = case model.chapter of
                     Just chapter -> chapter.title
                     Nothing -> "Loading…"
    chapterNarrationId = case model.chapter of
                           Just chapter -> chapter.narrationId
                           Nothing -> 0
  in
    div []
      [ text "Narrator's app main view"
      , nav []
          [ a [ href ("/narrations/" ++ (toString chapterNarrationId)) ]
              [ text "Narration" ]
          , text " ⇢ "
          , text chapterTitle
          ]
      , main' [ class "page-aside" ]
          [ section []
              [ input [ class "chapter-title"
                      , type' "text"
                      , placeholder "Title"
                      , value chapterTitle
                      , disabled (case model.chapter of
                                    Nothing -> True
                                    _ -> False)
                      -- , onInput UpdateChapterTitle
                      ]
                  []
              , div [ id "editor-container" ] []
              -- , addImageView
              -- , markForCharacter
              , div [ class "btn-row" ]
                  [ button [ class "btn"
                           -- , onClick SaveChapter
                           ]
                      [ text "Save" ]
                  , button [ class "btn btn-default"
                           -- , onClick PublishChapter
                           ]
                      [ text "Publish" ]
                  ]
              ]
          ]
      ]
