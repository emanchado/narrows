module CharacterEditApp.Views exposing (mainView)

import Html exposing (Html, main_, section, h2, h3, div, span, ul, li, img, input, button, a, label, em, text)
import Html.Attributes exposing (id, class, for, src, href, type_, value, checked, readonly, size, disabled, title)
import Html.Events exposing (onClick, onInput, on)

import Json.Decode
import ISO8601

import Common.Views exposing (breadcrumbNavView, bannerView, showDialog, avatarUrl)
import CharacterEditApp.Models exposing (Model, CharacterInfo, ChapterSummary)
import CharacterEditApp.Messages exposing (..)


chapterParticipation : String -> ChapterSummary -> Html Msg
chapterParticipation characterToken chapter =
  li []
    [ a [ href <| "/read/" ++ (String.fromInt chapter.id) ++ "/" ++ characterToken ]
        [ text chapter.title ]
    ]


formatDate : ISO8601.Time -> String
formatDate time =
  (String.fromInt <| ISO8601.day time) ++ "/" ++ (String.fromInt <| ISO8601.month time) ++
    "/" ++ (String.fromInt <| ISO8601.year time) ++ " at " ++
    (String.fromInt <| ISO8601.hour time) ++ ":" ++ (String.fromInt <| ISO8601.minute time)


mainView : Model -> Html Msg
mainView model =
  main_ [ class "app-container" ]
    [ breadcrumbNavView
        [ { title = "Home"
          , url = "/"
          }
        , case model.characterInfo of
            Just info -> { title = info.narration.title
                         , url = "/narrations/" ++ (String.fromInt info.narration.id)
                         }
            Nothing -> { title = "…"
                       , url = "#"
                       }
        ]
        (text <| case model.characterInfo of
                   Just characterInfo -> characterInfo.name
                   Nothing -> "…")
    , bannerView model.banner
    , div [ class "two-column" ]
        [ section []
            [ div [ class "vertical-form" ]
                [ case model.characterInfo of
                  Just characterInfo ->
                    div []
                      [ div [ class "avatars form-line" ]
                          [ div [ class "current-avatar" ]
                              [ img [ src <| avatarUrl characterInfo.narration.id characterInfo.avatar ] []
                              ]
                          , div [ class "upload-new-avatar" ]
                              [ div [ class "new-avatar-controls" ]
                                  [ label [] [ text "Upload new avatar:" ]
                                  , input [ id "new-avatar"
                                          , type_ "file"
                                          , on "change" (Json.Decode.succeed <| UpdateCharacterAvatar "new-avatar")
                                          ]
                                      []
                                  ]
                              , img [ src <| case model.newAvatarUrl of
                                               Just url -> url
                                               Nothing -> "/img/default-avatar.png"
                                    ]
                                  []
                              ]
                          ]
                      , div [ class "form-line" ]
                          [ label [] [ text "Name" ]
                          , input [ type_ "text"
                                  , class "character-name"
                                  , value characterInfo.name
                                  , onInput UpdateCharacterName
                                  ]
                              []
                          ]
                      ]

                  Nothing ->
                    text "Loading…"
                , div [ class "form-line" ]
                    [ label [] [ text "Description (public)" ]
                    , div [ id "description-editor"
                          , class "editor-container"
                          ] []
                    ]
                , div [ class "form-line" ]
                    [ label [] [ text "Backstory (private)" ]
                    , div [ id "backstory-editor"
                          , class "editor-container"
                          ] []
                    ]
                , div [ class "btn-bar" ]
                    [ button
                      [ class "btn btn-default"
                      , onClick SaveCharacter
                      , disabled (not model.characterModified)
                      ]
                      [ text "Save" ]
                    ]
                ]
            ]
        , section []
            [ case model.characterInfo of
                Just characterInfo ->
                  div [ class "vertical-form" ]
                    [ div [ class "form-line" ]
                        [ label [] [ text "Player" ]
                        , div [ class "one-line" ]
                            [ input [ class "large-text-input"
                                    , type_ "email"
                                    , size 36
                                    , value <| case characterInfo.email of
                                                 Just email -> email
                                                 Nothing -> ""
                                    , onInput UpdatePlayerEmail
                                    ]
                                []
                            ]
                        ]
                    , div [ class "form-line" ]
                        [ label [] [ text "Character token" ]
                        , div [ class "one-line" ]
                            [ input [ readonly True
                                    , class "large-text-input"
                                    , type_ "text"
                                    , size 36
                                    , value characterInfo.token
                                    ]
                                []
                            , button [ class "btn"
                                     , onClick ResetCharacterToken
                                     ]
                                [ text "Reset" ]
                            ]
                        , if model.showResetCharacterTokenDialog then
                            showDialog
                              "Reset character token?"
                              NoOp
                              "Reset"
                              ConfirmResetCharacterToken
                              "Cancel"
                              CancelResetCharacterToken
                          else
                            text ""
                        , div []
                            [ text "See the "
                            , a [ href <| "/characters/" ++ characterInfo.token ]
                                [ text <| "character sheet for " ++ characterInfo.name ]
                            , text ". "
                            , img [ src "/img/info-black.png"
                                  , class "help"
                                  , onClick ToggleTokenInfoBox
                                  ]
                                []
                            ]
                        , if model.showTokenInfoBox then
                            div [ class "floating-tip" ]
                              [ text "You can share the link above with the "
                              , text "player playing this character. The link "
                              , text "contains the character token, which is "
                              , text "meant to be secret (only known to the "
                              , text "narrator and the player). If you "
                              , text "suspect anyone else knows this token, "
                              , text "you can reset it with the button above."
                              ]
                          else
                            text ""
                        ]
                    , div [ class "form-line" ]
                        [ label [] [ text "Character novel token" ]
                        , input [ readonly True
                                , class "large-text-input"
                                , type_ "text"
                                , size 36
                                , value characterInfo.novelToken
                                ]
                            []
                        , span []
                            [ text "Read the "
                            , a [ href <| "/novels/" ++ characterInfo.novelToken ]
                                [ text characterInfo.narration.title ]
                            , text " "
                            , em [] [ text "novel" ]
                            , text " from this character’s point of view. "
                            , img [ src "/img/info-black.png"
                                  , class "help"
                                  , onClick ToggleNovelTokenInfoBox
                                  ]
                                []
                        , if model.showNovelTokenInfoBox then
                            div [ class "floating-tip" ]
                              [ text "Novels don’t have any way to interact "
                              , text "and can be read like a book. You can "
                              , text "share the link with anyone: they won’t "
                              , text "be able to post messages for the "
                              , text "character or change anything about it."
                              ]
                          else
                            text ""
                            ]
                        , div [ class "btn-bar btn-bar-extra" ]
                            [ button [ class "btn btn-remove"
                                     , onClick RemoveCharacter
                                     ]
                                [ text "Delete" ]
                            ]
                        , if model.showRemoveCharacterDialog then
                            showDialog
                              "Delete character?"
                              NoOp
                              "Delete"
                              ConfirmRemoveCharacter
                              "Cancel"
                              CancelRemoveCharacter
                          else
                            text ""
                        ]
                    ]

                Nothing ->
                  em [] [ text "Loading…" ]
            ]
        ]
    ]
