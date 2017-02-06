module CharacterApp.Views exposing (mainView)

import Html exposing (Html, section, h2, h3, div, ul, li, img, button, a, label, em, text)
import Html.Attributes exposing (id, class, for, src, href, type', checked)
import Html.Events exposing (onClick)

import Common.Views exposing (bannerView)

import CharacterApp.Models exposing (Model, CharacterInfo, ChapterSummary)
import CharacterApp.Messages exposing (..)

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
    [ a [ href <| "/read/" ++ (toString chapter.id) ++ "/" ++ characterToken ]
        [ text chapter.title ]
    ]

mainView : Model -> Html Msg
mainView model =
  div [ id "reader-app", class "app-container" ]
    [ bannerView model.banner
    , h2 []
      (case model.characterInfo of
           Just characterInfo ->
             [ text <| characterInfo.name ++ ", character in "
             , em [] [ text characterInfo.narration.title ]
             ]
           Nothing ->
             [ text "Loading"
             ])
    , div [ class "two-column" ]
        [ section []
            [ case model.characterInfo of
                Just characterInfo ->
                  div [ class "current-avatar" ]
                    [ img [ src <| avatarUrl characterInfo.narration.id characterInfo.avatar ] []
                    ]
                Nothing ->
                  text "Loading"
            , label [] [ text "Description" ]
            , div [ id "description-editor" ] []
            , label [] [ text "Backstory" ]
            , div [ id "backstory-editor" ] []
            , div [ class "btn-bar" ]
                [ button [ class "btn btn-default"
                         , onClick SaveCharacter
                         ]
                    [ text "Save" ]
                ]
            ]
        , section []
            [ h3 [] [ text "Appears in these chapters:" ]
            , case model.characterInfo of
                Just characterInfo ->
                  ul []
                    (List.map (chapterParticipation model.characterToken)
                       characterInfo.narration.chapters)
                Nothing ->
                  em [] [ text "None." ]
            ]
        ]
    ]
