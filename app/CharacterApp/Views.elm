module CharacterApp.Views exposing (mainView)

import Html exposing (Html, main_, section, h2, h3, div, span, ul, li, img, input, button, a, label, em, text, br, strong)
import Html.Attributes exposing (id, class, for, src, href, type_, value, checked, width, height)
import Html.Events exposing (onClick, onInput, on)

import Json.Decode

import Common.Models exposing (ParticipantCharacter)
import Common.Views exposing (bannerView)
import CharacterApp.Models exposing (Model, CharacterInfo, ChapterSummary)
import CharacterApp.Messages exposing (..)


avatarUrl : Int -> Maybe String -> String
avatarUrl narrationId maybeAvatar =
  case maybeAvatar of
    Just avatar ->
      "/static/narrations/" ++ (String.fromInt narrationId) ++ "/avatars/" ++ avatar
    Nothing ->
      "/img/default-avatar.png"


chapterParticipation : String -> ChapterSummary -> Html Msg
chapterParticipation characterToken chapter =
  li []
    [ a [ href <| "/read/" ++ (String.fromInt chapter.id) ++ "/" ++ characterToken ]
        [ text chapter.title ]
    ]


characterView : Int -> ParticipantCharacter -> Html Msg
characterView narrationId participant =
  li []
    [ img [ class "avatar"
          , width 100
          , height 100
          , src <| avatarUrl narrationId participant.avatar
          ]
        []
    , div []
        [ strong [] [ text participant.name ]
        , br [] []
        , div [ id <| "description-character-" ++ (String.fromInt participant.id)
              , class "character-description"
              ]
            []
        ]
    ]


mainView : Model -> Html Msg
mainView model =
  main_ [ id "reader-app", class "app-container" ]
    [ h2 []
      (case model.characterInfo of
        Just characterInfo ->
          [ text <| characterInfo.name ++ ", character in "
          , em [] [ text characterInfo.narration.title ]
          ]

        Nothing ->
          [ text "Loading"
          ]
      )
    , bannerView model.banner
    , div [ class "two-column" ]
        [ section []
            [ div [ class "vertical-form" ]
              [ case model.characterInfo of
                Just characterInfo ->
                  div [ class "form-line" ]
                    [ div [ class "avatars" ]
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
                    , label [] [ text "Name" ]
                    , div []
                        [ input [ type_ "text"
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
            [ h3 [] [ text "Appears in these chapters:" ]
            , case model.characterInfo of
                Just characterInfo ->
                  div []
                    [ if List.length characterInfo.narration.chapters == 0 then
                        em [] [ text "None." ]
                      else
                        div []
                          [ ul []
                            (List.map (chapterParticipation model.characterToken)
                               characterInfo.narration.chapters)
                          , text "Or read the "
                          , a [ href <| "/novels/" ++ characterInfo.novelToken ]
                            [ text characterInfo.narration.title ]
                          , text " "
                          , em [] [ text "novel" ]
                          , text " from this character’s point of view. "
                          , img [ src "/img/info.png"
                                , class "help"
                                , onClick ToggleNovelTip
                                ]
                              []
                          , if model.showNovelTip then
                              div [ class "floating-tip" ]
                                [ text "Novels don’t have any way to interact "
                                , text "and can be read like a book. You can "
                                , text "share the link with others if you want: "
                                , text "they won’t be able to post messages for "
                                , text "you or change anything about your character."
                                ]
                            else
                              text ""
                          ]
                    , h3 [] [ text "Other characters in the story:" ]
                    , ul [ class "dramatis-personae" ]
                        (List.map (characterView characterInfo.narration.id) characterInfo.narration.characters)
                    ]

                Nothing ->
                  em [] [ text "None." ]
            ]
        ]
    ]
