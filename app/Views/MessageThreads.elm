module Views.MessageThreads exposing (..)

import String
import Html exposing (Html, div, text, textarea, input, button, ul, li, strong, span, label)
import Html.Attributes exposing (id, class, value, rows, type', checked, disabled)
import Html.Events exposing (onClick, onInput)

import Models exposing (Model, MessageThread, Message, Character)
import Messages exposing (..)

messageView : Message -> Html Msg
messageView message =
  div [ class "message" ]
    [ strong []
        [ text (case message.sender of
                  Just sender -> sender.name
                  Nothing -> "Narrator") ]
    , text ": "
    , span [ class (case message.sender of
                      Just sender -> ""
                      Nothing -> "narrator") ]
        [ text message.body ]
    ]

threadView : MessageThread -> Int -> Html Msg
threadView thread characterId =
  let
    participants =
      List.map
        (\c -> c.name)
        (List.filter
           (\c -> c.id /= characterId)
           thread.participants)
    participantString = String.join ", " participants
    participantStringEnd = if List.length participants > 0 then
                             ", the narrator, and you"
                           else
                             "the narrator and you"
    participantsDiv =
      div [ class "thread-participants" ]
        [ text ("Between " ++ participantString ++ participantStringEnd) ]
  in
    li []
      (participantsDiv :: List.map messageView thread.messages)

recipientView : List Int -> Character -> Html Msg
recipientView currentRecipients character =
  label []
    [ input [ type' "checkbox"
            , value (toString character.id)
            , checked (List.any (\r -> r == character.id) currentRecipients)
            ]
        []
    , text character.name
    ]

recipientListView : List Character -> List Int -> Html Msg
recipientListView possibleRecipients currentRecipients =
  div [ class "recipients" ]
    ([ label [] [ text "Recipients:" ]
     , input [ type' "checkbox", checked True, disabled True ] []
     , text "Narrator"
     ] ++ List.map (recipientView currentRecipients) possibleRecipients)

listView : Model -> Html Msg
listView model =
  let
    otherParticipants =
      case model.chapter of
        Just chapter ->
          case model.characterId of
            Just characterId ->
              List.filter
                (\p -> p.id /= characterId)
                chapter.participants
            Nothing ->
              []
        Nothing ->
          []
  in
    div []
      [ ul [ class "message-list" ]
          (case model.messageThreads of
             Just threads ->
               (case model.characterId of
                  Just characterId ->
                    (List.map
                       (\mt -> threadView mt characterId)
                       threads)
                  Nothing ->
                    [])
             Nothing ->
               [])
      , div [ class "new-message" ]
        [ textarea [ rows 2
                   , onInput UpdateNewMessageText
                   , value model.newMessageText
                   ]
            [ text model.newMessageText ]
        , recipientListView otherParticipants model.newMessageRecipients
        , button [ class "btn"
                 , onClick SendMessage
                 ]
            [ text "Send" ]
        ]
      ]
