module ReaderApp.Views.MessageThreads exposing (..)

import Html exposing (Html, h2, h3, div, text, textarea, img, input, button, ul, li, blockquote, p, strong, span, label)
import Html.Attributes exposing (id, class, src, value, rows, type_, checked, disabled, placeholder)
import Html.Events exposing (onClick, onInput, onCheck)
import Common.Views exposing (messageThreadInteractionView)
import Common.Models exposing (ParticipantCharacter)
import ReaderApp.Models exposing (Model)
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
        ([ text "Recipients:"
         , input [ type_ "checkbox", checked True, disabled True ] []
         , label [] [ text "Narrator" ]
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
                                messageThreadInteractionView
                                    (Just character.id)
                                    (ShowReply t.participants)
                                    UpdateReplyText
                                    SendReply
                                    CloseReply
                                    model.reply
                                    model.replySending
                                    t)
                            threads

                    Nothing ->
                        []
                )
            , div [ class "new-message" ]
                [ h2 []
                    [ text "New message "
                    , img [ src "/img/info.png"
                          , class "help"
                          , onClick ToggleReactionTip
                          ]
                        []
                    ]
                , if model.showReactionTip then
                    div [ class "floating-tip" ]
                      [ h3 [] [ text "Tips" ]
                      , p []
                          [ text <| "The most important things to convey " ++
                              "are what your character "
                          , strong [] [ text "does" ]
                          , text <| " and what they "
                          , strong [] [ text "think" ]
                          , text " or "
                          , strong [] [ text "feel" ]
                          , text ", eg:"
                          ]
                      , blockquote []
                          [ text <| "I’ll go up the ladder and search the " ++
                              "attic, listening for any signs of activity " ++
                              "up there as I climb. I don’t like this " ++
                              "place one bit so I’ll try to find the " ++
                              "chest or any clue, and leave as soon as I can."
                          ]
                      , p []
                          [ text <| "Often they include possibilities or " ++
                              "plans for the near future:"
                          ]
                      , blockquote []
                          [ text <| "I ask what’s the deal with the " ++
                              "victim’s tattoo and if she has seen it " ++
                              "before. She must be hiding something so " ++
                              "if she doesn’t speak up I will wait " ++
                              "outside and follow her to see if the " ++
                              "meets anyone or goes back to the club."
                          ]
                      , p []
                          [ text <| "Including direct quotes is a good way " ++
                              "to describe your character’s mood, too:"
                          ]
                      , blockquote []
                          [ text <| "“This is awful. We need to contact " ++
                              "him and make him stop.” I call Robert: " ++
                              "“Hi… you need to stop that. I *will* kick " ++
                              "you out if you don’t stop. She is *not* " ++
                              "ready. Do you hear me?”"
                          ]
                      ]
                  else
                    text ""
                , textarea [ rows 8
                           , onInput UpdateNewMessageText
                           , placeholder "Click on the information icon for tips…"
                           , value model.newMessageText
                           ]
                    [ text model.newMessageText ]
                , recipientListView otherParticipants model.newMessageRecipients
                , div [ class "btn-bar" ]
                    [ button
                        [ class "btn btn-default"
                        , onClick SendMessage
                        ]
                        [ text "Send" ]
                    ]
                ]
            ]
