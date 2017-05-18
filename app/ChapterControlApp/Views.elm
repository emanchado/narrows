module ChapterControlApp.Views exposing (..)

import Html exposing (Html, main_, h1, h2, nav, section, div, ul, li, textarea, input, button, label, a, strong, em, text)
import Html.Attributes exposing (id, class, href, type_, value, disabled, checked, rows, cols)
import Html.Events exposing (onInput, onClick, onCheck)
import Common.Models exposing (Character, FullCharacter, Narration, NarrationStatus(..), Reaction, loadingPlaceholderChapter)
import Common.Views exposing (threadView, breadcrumbNavView)
import ChapterControlApp.Messages exposing (..)
import ChapterControlApp.Models exposing (Model, ChapterInteractions)


reactionView : Reaction -> Html Msg
reactionView reaction =
    li [ class "reaction" ]
        [ strong [] [ text reaction.character.name ]
        , div []
            [ case reaction.text of
                Just reactionText ->
                    text reactionText

                Nothing ->
                    em [] [ text "Not submitted yet." ]
            ]
        ]


recipientView : List Int -> FullCharacter -> Html Msg
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


recipientListView : List FullCharacter -> List Int -> Html Msg
recipientListView possibleRecipients currentRecipients =
    div [ class "recipients" ]
        (List.map (recipientView currentRecipients) possibleRecipients)


mainView : Model -> Html Msg
mainView model =
    let
        ( chapter, messageThreads, reactions ) =
            case model.interactions of
                Just interactions ->
                    ( interactions.chapter
                    , interactions.messageThreads
                    , interactions.reactions
                    )

                Nothing ->
                    ( loadingPlaceholderChapter
                    , []
                    , []
                    )

        narration =
            case model.narration of
                Just narration ->
                    narration

                Nothing ->
                    { id = 0
                    , title = "…"
                    , status = Active
                    , characters = []
                    , defaultAudio = Nothing
                    , defaultBackgroundImage = Nothing
                    , files =
                        { audio = []
                        , backgroundImages = []
                        , images = []
                        }
                    }
    in
        main_ [ id "narrator-app", class "app-container" ]
            [ h1 []
                [ text <| chapter.title ]
            , breadcrumbNavView
                NavigateTo
                [ { title = "Home"
                  , url = "/"
                  }
                , { title = narration.title
                  , url = "/narrations/" ++ (toString chapter.narrationId)
                  }
                , { title = chapter.title
                  , url = "/chapters/" ++ (toString chapter.id) ++ "/edit"
                  }
                ]
                (text "Control")
            , div [ class "two-column" ]
                [ section []
                    [ h2 [] [ text "Chapter text" ]
                    , div
                        [ id "chapter-text"
                        , class "chapter"
                        ]
                        []
                    ]
                , section []
                    [ h2 [] [ text "Conversation" ]
                    , ul [ class "thread-list narrator" ]
                        (List.map
                            (\mt ->
                                threadView
                                    Nothing
                                    (ShowReply mt.participants)
                                    UpdateReplyText
                                    SendReply
                                    CloseReply
                                    model.reply
                                    mt
                            )
                            messageThreads
                        )
                    , div [ class "new-message" ]
                        [ textarea
                            [ rows 3
                            , onInput UpdateNewMessageText
                            , value model.newMessageText
                            ]
                            [ text model.newMessageText ]
                        ]
                    , recipientListView chapter.participants model.newMessageRecipients
                    , div [ class "btn-bar" ]
                        [ button
                            [ class "btn"
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
