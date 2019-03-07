module NovelReaderApp.Views.Novel exposing (view)

import String
import Html exposing (Html, h2, div, a, strong, text, img, br, audio, ul, li)
import Html.Attributes exposing (id, class, style, src, preload, loop, alt)
import Html.Events exposing (onClick)
import Common.Models exposing (ParticipantCharacter)
import Common.Views.Reading exposing (backgroundImageStyle, chapterContainerClass)
import NovelReaderApp.Models exposing (Model, findChapter, isFirstChapter, isLastChapter)
import NovelReaderApp.Messages exposing (..)


characterView : Int -> ParticipantCharacter -> Html Msg
characterView narrationId participant =
  let
    avatarUrl =
      case participant.avatar of
        Just avatar ->
          "/static/narrations/" ++ (String.fromInt narrationId) ++ "/avatars/" ++ avatar

        Nothing ->
          "/img/default-avatar.png"
  in
    li []
      [ img [ class "avatar"
            , src avatarUrl
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


view : Model -> Html Msg
view model =
  case model.novel of
    Just novel ->
      case findChapter novel model.currentChapterIndex of
        Just currentChapter ->
          div [ id "chapter-container", class (chapterContainerClass model.state) ]
            [ if isFirstChapter novel model.currentChapterIndex then
                text ""
              else
                div [ class "chapter-navigation chapter-navigation-previous"
                    , onClick PreviousChapter
                    ]
                  [ div [ id "previous-chapter-arrow"
                        , class "chapter-navigation-arrow"
                        ]
                      []
                  ]
            , if isLastChapter novel model.currentChapterIndex then
                text ""
              else
                div [ class "chapter-navigation chapter-navigation-next"
                    , onClick NextChapter
                    ]
                  [ div [ id "next-chapter-arrow"
                        , class "chapter-navigation-arrow"
                        ]
                      []
                  ]
            , div (List.append
                     [ id "top-image" ]
                     (backgroundImageStyle novel.narration.id currentChapter.backgroundImage model.backgroundBlurriness))
                [ text (if (String.isEmpty currentChapter.title) then
                          "Untitled"
                        else
                          currentChapter.title)
                ]
            , img [ id "play-icon"
                  , src ("/img/" ++ (if model.musicPlaying then
                                       "play"
                                     else
                                       "mute") ++
                           "-small.png")
                  , alt (if model.musicPlaying then "Stop" else "Start")
                  , onClick PlayPauseMusic
                  ]
                []
            , div [ id "chapter-text", class "chapter" ]
                [ text "Chapter contents go here" ]
            , div [ class "interaction" ]
                [ h2 [] [ text "Dramatis personae" ]
                , ul [ class "dramatis-personae" ]
                    (List.map
                      (characterView novel.narration.id)
                      novel.narration.characters)
                ]
            , div []
                (List.indexedMap
                   (\i chapter ->
                      case chapter.audio of
                        Just audioUrl ->
                          audio [ id <| "background-music-chapter-" ++ (String.fromInt i)
                                , src ("/static/narrations/" ++
                                         (String.fromInt novel.narration.id) ++
                                         "/audio/" ++ audioUrl)
                                , loop True
                                , preload (if model.backgroundMusic then
                                             "auto"
                                           else
                                             "none")
                                ]
                            []
                        Nothing ->
                          text "")
                   novel.chapters)
            ]

        Nothing ->
          div [ id "chapter-container", class (chapterContainerClass model.state) ]
            [ text <| "Internal Error: no such chapter " ++ (String.fromInt model.currentChapterIndex)
            ]

    Nothing ->
      div [ id "chapter-container", class (chapterContainerClass model.state) ]
        [ text "Internal Error: no novel." ]
