module Common.Views exposing (..)

import String
import Html exposing (Html, div, textarea, button, span, li, strong, text)
import Html.Attributes exposing (class, rows, value)
import Html.Events exposing (onClick, onInput)

import Common.Models exposing (MessageThread, Message, Banner, ReplyInformation)

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

threadView : Maybe Int -> msg -> (String -> msg) -> msg -> msg -> Maybe ReplyInformation -> MessageThread -> Html msg
threadView maybeCharacterId showReplyMessage updateReplyMessage sendReplyMessage closeReplyMessage maybeReply thread =
  let
    participants =
      List.map
        (\c -> c.name)
        (case maybeCharacterId of
           Just characterId ->
             (List.filter
                (\c -> c.id /= characterId)
                thread.participants)
           Nothing ->
             thread.participants)
    participantString = String.join ", " participants
    participantStringEnd = case maybeCharacterId of
                             Nothing ->
                               if List.length participants > 1 then
                                 ", and you"
                               else
                                 " and you"
                             Just _ ->
                               if List.length participants > 0 then
                                 ", the narrator, and you"
                               else
                                 "the narrator and you"
    participantsDiv =
      div [ class "thread-participants" ]
        [ text ("Between " ++ participantString ++ participantStringEnd) ]

    replyButtonDiv =
      div [ class "btn-bar" ]
        [ button [ class "btn btn-small"
                 , onClick showReplyMessage
                 ]
            [ text "Reply" ] ]

    replyBoxDiv =
      case maybeReply of
        Just reply ->
          if reply.recipients == thread.participants then
            div []
              [ textarea [ rows 4
                         , value reply.body
                         , onInput updateReplyMessage
                         ]
                  [ text reply.body ]
              , div [ class "btn-bar" ]
                  [ button [ class "btn btn-default btn-small"
                           , onClick sendReplyMessage
                           ]
                      [ text "Send" ]
                  , button [ class "btn btn-small"
                           , onClick closeReplyMessage
                           ]
                      [ text "Close" ]
                  ]
              ]
          else
            replyButtonDiv
        Nothing ->
          replyButtonDiv
  in
    li []
      (List.concat [ [ participantsDiv ]
                   , List.map messageView thread.messages
                   , [ replyBoxDiv ]
                   ])

bannerView : Maybe Banner -> Html msg
bannerView maybeBanner =
  case maybeBanner of
    Just banner ->
      div [ class <| "banner banner-" ++ banner.type' ]
        [ text banner.text ]
    Nothing ->
      text ""
