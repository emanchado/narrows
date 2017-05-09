module ReaderApp.Views.MessageThreads exposing (..)

import Html exposing (Html, div, text, textarea, input, button, ul, li, strong, span, label)
import Html.Attributes exposing (id, class, value, rows, type_, checked, disabled)
import Html.Events exposing (onClick, onInput, onCheck)
import Common.Views exposing (threadView)
import ReaderApp.Models exposing (Model, ParticipantCharacter)
import ReaderApp.Messages exposing (..)


recipientView : List Int -> ParticipantCharacter -> Html Msg
recipientView currentRecipients character =
    label []
        [ input
            [ type_ "checkbox"
            , value (toString character.id)
            , checked (List.any (\r -> r == character.id) currentRecipients)
            , onCheck (UpdateNewMessageRecipient character.id)
            ]
            []
        , text character.name
        ]


recipientListView : List ParticipantCharacter -> List Int -> Html Msg
recipientListView possibleRecipients currentRecipients =
    div [ class "recipients" ]
        ([ label [] [ text "Recipients:" ]
         , input [ type_ "checkbox", checked True, disabled True ] []
         , text "Narrator"
         ]
            ++ List.map (recipientView currentRecipients) possibleRecipients
        )


listView : Model -> Html Msg
listView model =
    let
        character =
            case model.chapter of
                Just chapter ->
                    chapter.character

                Nothing ->
                    { id = 0, name = "", token = "", notes = Nothing }

        otherParticipants =
            case model.chapter of
                Just chapter ->
                    List.filter
                        (\p -> p.id /= character.id)
                        chapter.participants

                Nothing ->
                    []
    in
        div []
            [ ul [ class "thread-list reader" ]
                (case model.messageThreads of
                    Just threads ->
                        List.map
                            (\t ->
                                threadView
                                    (Just character.id)
                                    (ShowReply t.participants)
                                    UpdateReplyText
                                    SendReply
                                    CloseReply
                                    model.reply
                                    t
                            )
                            threads

                    Nothing ->
                        []
                )
            , if model.showNewMessageUi then
                div [ class "new-message" ]
                    [ textarea
                        [ rows 4
                        , onInput UpdateNewMessageText
                        , value model.newMessageText
                        ]
                        [ text model.newMessageText ]
                    , recipientListView otherParticipants model.newMessageRecipients
                    , div [ class "btn-bar" ]
                        [ button
                            [ class "btn btn-default btn-small"
                            , onClick SendMessage
                            ]
                            [ text "Send" ]
                        , button
                            [ class "btn btn-small"
                            , onClick HideNewMessageUi
                            ]
                            [ text "Close" ]
                        ]
                    ]
              else
                div [ class "btn-bar" ]
                    [ button [ class "btn btn-small", onClick ShowNewMessageUi ]
                        [ text "New message" ]
                    ]
            ]
