module NovelReaderApp.Views.Novel exposing (view)

import String
import Html exposing (Html, h2, div, span, a, input, textarea, strong, text, img, label, button, br, audio, ul, li)
import Html.Attributes exposing (id, class, style, for, src, href, target, checked, preload, loop, alt, defaultValue, rows, placeholder)
import Html.Events exposing (onClick, onInput)
import Http exposing (encodeUri)
import NovelReaderApp.Models exposing (Model, Chapter, ParticipantCharacter, Novel, findChapter)
import NovelReaderApp.Messages exposing (..)


chapterContainerClass : Model -> String
chapterContainerClass model =
  case model.state of
    NovelReaderApp.Models.Loader -> "invisible transparent"
    NovelReaderApp.Models.StartingNarration -> "transparent"
    NovelReaderApp.Models.Narrating -> "fade-in"


backgroundImageStyle : Int -> Maybe String -> Int -> List ( String, String )
backgroundImageStyle narrationId maybeBgImage backgroundBlurriness =
  case maybeBgImage of
    Just backgroundImage ->
      let
        imageUrl = "/static/narrations/" ++
                     (toString narrationId) ++
                     "/background-images/" ++
                     (encodeUri backgroundImage)

        filter = "blur(" ++ (toString backgroundBlurriness) ++ "px)"
      in
        [ ( "background-image", "url(" ++ imageUrl ++ ")" )
        , ( "-webkit-filter", filter )
        , ( "-moz-filter", filter )
        , ( "filter", filter )
        ]
    Nothing ->
      []


characterView : Int -> ParticipantCharacter -> Html Msg
characterView narrationId participant =
  let
    avatarUrl =
      case participant.avatar of
        Just avatar ->
          "/static/narrations/" ++ (toString narrationId) ++ "/avatars/" ++ avatar

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
          , div [ id <| "description-character-" ++ (toString participant.id)
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
        Just chapter ->
          div [ id "chapter-container", class (chapterContainerClass model) ]
            [ div [ class "chapter-navigation chapter-navigation-previous"
                  , onClick PreviousChapter
                  ]
                [ div [ id "previous-chapter-arrow"
                      , class "chapter-navigation-arrow"
                      ]
                    []
                ]
            , div [ class "chapter-navigation chapter-navigation-next"
                  , onClick NextChapter
                  ]
                [ div [ id "next-chapter-arrow"
                      , class "chapter-navigation-arrow"
                      ]
                    []
                ]
            , div [ id "top-image"
                  , style (backgroundImageStyle novel.narration.id chapter.backgroundImage model.backgroundBlurriness)
                  ]
                [ text (if (String.isEmpty chapter.title) then
                          "Untitled"
                        else
                          chapter.title)
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
                          audio [ id <| "background-music-chapter-" ++ (toString i)
                                , src ("/static/narrations/" ++
                                         (toString novel.narration.id) ++
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
          div [ id "chapter-container", class (chapterContainerClass model) ]
            [ text <| "Internal Error: no such chapter " ++ (toString model.currentChapterIndex)
            ]

    Nothing ->
      div [ id "chapter-container", class (chapterContainerClass model) ]
        [ text "Internal Error: no novel." ]
