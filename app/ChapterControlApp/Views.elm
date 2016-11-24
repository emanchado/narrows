module ChapterControlApp.Views exposing (..)

import Html exposing (Html, main', h1, h2, nav, section, div, ul, li, a, text)
import Html.Attributes exposing (id, class, href)

import Common.Models exposing (Narration, Reaction, loadingPlaceholderChapter)
import Common.Views exposing (threadView)

import ChapterControlApp.Messages exposing (..)
import ChapterControlApp.Models exposing (Model, ChapterInteractions)

reactionView : Reaction -> Html Msg
reactionView reaction =
  case reaction.text of
    Just reactionText ->
      div [ class "reaction" ]
        [ text <| "From: " ++ reaction.character.name
        , div []
          [ text reactionText
          ]
        ]
    Nothing ->
      text ""

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
  let
    (chapter, messageThreads, reactions) =
      case model.interactions of
        Just interactions -> ( interactions.chapter
                             , interactions.messageThreads
                             , interactions.reactions
                             )
        Nothing -> ( loadingPlaceholderChapter
                   , []
                   , []
                   )
  in
    main' [ id "narrator-app" ]
      [ h1 []
          [ text <| chapter.title ]
      , nav []
          [ a [ href <| "/narrations/" ++ (toString chapter.narrationId) ]
              [ text "Narration" ]
          , text " ⇢ "
          , a [ href <| "/chapters/" ++ (toString chapter.id) ++ "/edit" ]
              [ text "Edit" ]
          ]
      , div [ class "two-column" ]
          [ section []
            [ h2 [] [ text "Chapter text" ]
            , div [ id "chapter-text"
                  , class "chapter"
                  ]
                []
            ]
          , section []
            [ h2 [] [ text "Conversation" ]
            , ul [ class "thread-list narrator" ]
              (List.map
                 (\mt -> threadView mt 0)
                 messageThreads)
            , h2 []
              [ text "Actions" ]
            , ul [ class "reactions" ]
              (List.map reactionView reactions)
          ]
          ]
      ]
