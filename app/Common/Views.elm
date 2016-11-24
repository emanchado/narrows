module Common.Views exposing (..)

import String
import Html exposing (Html, div, span, li, strong, text)
import Html.Attributes exposing (class)

import Common.Models exposing (MessageThread, Message)

messageView : Message -> Html msg
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

threadView : MessageThread -> Int -> Html msg
threadView thread characterId =
  let
    participants =
      List.map
        (\c -> c.name)
        (List.filter
           (\c -> c.id /= characterId)
           thread.participants)
    participantString = String.join ", " participants
    participantStringEnd = if characterId == 0 then
                             if List.length participants > 1 then
                               ", and you"
                             else
                               " and you"
                           else
                             if List.length participants > 0 then
                               ", the narrator, and you"
                             else
                               "the narrator and you"
    participantsDiv =
                div [ class "thread-participants" ]
        [ text ("Between " ++ participantString ++ participantStringEnd) ]
  in
    li []
      (participantsDiv :: List.map messageView thread.messages)
