module ChapterControlApp.Views exposing (..)

import Html exposing (Html, main', h1, h2, nav, section, div, ul, li, textarea, input, button, label, a, strong, em, text)
import Html.Attributes exposing (id, class, href, type', value, disabled, checked, rows, cols)
import Html.Events exposing (onInput, onClick, onCheck)

import Common.Models exposing (Character, FullCharacter, Narration, Reaction, loadingPlaceholderChapter)
import Common.Views exposing (threadView)

import ChapterControlApp.Messages exposing (..)
import ChapterControlApp.Models exposing (Model, ChapterInteractions)

reactionView : Reaction -> Html Msg
reactionView reaction =
  li [ class "reaction" ]
    [ strong [] [ text reaction.character.name ]
    , div []
       [ case reaction.text of
           Just reactionText -> text reactionText
           Nothing -> em [] [ text "Not submitted yet." ]
       ]
    ]

loadingView : Model -> Html Msg
loadingView model =
  case model.banner of
    Just banner ->
      div [ class ("banner banner-" ++ banner.type') ]
        [ text banner.text ]
    Nothing ->
      div [] [ text "Loading" ]

recipientView : List Int -> FullCharacter -> Html Msg
recipientView currentRecipients character =
  label []
    [ input [ type' "checkbox"
            , value (toString character.id)
            , checked (List.any (\r -> r == character.id) currentRecipients)
            , onCheck (UpdateNewMessageRecipient character.id)
            ]
        []
    , text character.name
    ]

recipientListView : List FullCharacter -> List Int -> Html Msg
recipientListView possibleRecipients currentRecipients =
  div [ class "recipients" ]
    (List.map (recipientView currentRecipients) possibleRecipients)

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
            , div [ class "new-message" ]
                [ textarea [ rows 3
                           , onInput UpdateNewMessageText
                           , value model.newMessageText
                           ]
                    [ text model.newMessageText ]
                ]
            , recipientListView chapter.participants model.newMessageRecipients
            , div [ class "btn-bar" ]
              [ button [ class "btn"
                       , onClick SendMessage
                       ]
                  [ text "Send" ]
              ]
            , h2 []
              [ text "Actions" ]
            , ul [ class "reactions narrator" ]
              (List.map reactionView reactions)
          ]
          ]
      ]
