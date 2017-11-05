module CharacterEditApp.Views exposing (mainView)

import Html exposing (Html, main_, section, h2, h3, div, span, ul, li, img, input, button, a, label, em, text)
import Html.Attributes exposing (id, class, for, src, href, type_, value, checked, readonly, size)
import Html.Events exposing (onClick, onInput, on)

import Json.Decode

import Common.Views exposing (breadcrumbNavView, bannerView, linkTo)
import CharacterEditApp.Models exposing (Model, CharacterInfo, ChapterSummary)
import CharacterEditApp.Messages exposing (..)


avatarUrl : Int -> Maybe String -> String
avatarUrl narrationId maybeAvatar =
  case maybeAvatar of
    Just avatar ->
      "/static/narrations/" ++ (toString narrationId) ++ "/avatars/" ++ avatar
    Nothing ->
      "/img/default-avatar.png"


chapterParticipation : String -> ChapterSummary -> Html Msg
chapterParticipation characterToken chapter =
  li []
    [ a
      (linkTo
        NavigateTo
        ("/read/" ++ (toString chapter.id) ++ "/" ++ characterToken)
      )
      [ text chapter.title ]
    ]


mainView : Model -> Html Msg
mainView model =
  main_ [ class "app-container" ]
    [ breadcrumbNavView
        NavigateTo
        [ { title = "Home"
          , url = "/"
          }
        , case model.characterInfo of
            Just info -> { title = info.narration.title
                         , url = "/narrations/" ++ (toString info.narration.id)
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
                        , input [ class "large-text-input"
                                , type_ "email"
                                , size 36
                                , value characterInfo.email
                                , onInput UpdatePlayerEmail
                                ]
                            []
                        ]
                    , div [ class "form-line" ]
                        [ label [] [ text "Character token" ]
                        , input [ readonly True
                                , class "large-text-input"
                                , type_ "text"
                                , size 36
                                , value characterInfo.token
                                ]
                            []
                        , div []
                            [ text "See "
                            , a [ href <| "/characters/" ++ characterInfo.token ]
                              [ text characterInfo.name ]
                            , text " from the player's perspective."
                            ]
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
                            ]
                        ]
                    ]

                Nothing ->
                  em [] [ text "Loading…" ]
            ]
        ]
    ]
