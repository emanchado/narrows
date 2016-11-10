module NarratorApp.Views.ChapterEdit exposing (..)

import Json.Encode

import Html exposing (Html, h2, div, main', nav, section, aside, ul, li, img, a, input, select, option, button, br, em, text)
import Html.Attributes exposing (id, class, href, src, target, type', value, placeholder, checked, disabled)
import Html.Events exposing (onClick, onInput)

import NarratorApp.Models exposing (Model, Chapter, Character, Narration)
import NarratorApp.Messages exposing (..)
import NarratorApp.Views.FileSelector exposing (fileSelector)

fakeChapter : Chapter
fakeChapter =
  { id = 0
  , narrationId = 0
  , title = ""
  , audio = Nothing
  , backgroundImage = Nothing
  , text = Json.Encode.list []
  , participants = []
  , published = Nothing
  }

fakeNarration : Narration
fakeNarration =
  { id = 0
  , title = ""
  , characters = []
  , defaultAudio = Nothing
  , defaultBackgroundImage = Nothing
  , files = { audio = []
            , backgroundImages = []
            , images = []
            }
  }

participantView : Character -> Html Msg
participantView character =
  li []
    [ a [ href ("/read/" ++ "1" ++ character.token)
        , target "_blank"
        ]
        [ text character.name ]
    , text " "
    , img [ src "/img/delete.png"
          , onClick (RemoveParticipant character)
          ]
        []
    ]

nonParticipantView : Character -> Html Msg
nonParticipantView character =
  li []
    [ text character.name
    , text " "
    , img [ src "/img/add.png"
          , onClick (AddParticipant character)
          ]
        []
    ]

participantListView : List Character -> List Character -> Html Msg
participantListView allCharacters currentParticipants =
  let
    nonParticipants =
      List.filter (\c -> not (List.member c currentParticipants)) allCharacters

    participantItems = List.map participantView currentParticipants

    nonParticipantItems = List.map nonParticipantView nonParticipants
  in
    ul []
      (List.append participantItems nonParticipantItems)

chapterView : Chapter -> Narration -> Html Msg
chapterView chapter narration =
  div [ id "narrator-app" ]
    [ nav []
        [ a [ href ("/narrations/" ++ (toString chapter.narrationId)) ]
            [ text "Narration" ]
        , text " ⇢ "
        , text chapter.title
        ]
    , main' [ class "page-aside" ]
        [ section []
            [ input [ class "chapter-title"
                    , type' "text"
                    , placeholder "Title"
                    , value chapter.title
                    , onInput UpdateChapterTitle
                    ]
                []
            , div [ id "editor-container" ] []
            -- , addImageView
            -- , markForCharacter
            , div [ class "btn-bar" ]
                [ button [ class "btn"
                         , onClick SaveChapter
                         ]
                    [ text "Save" ]
                , button [ class "btn btn-default"
                         -- , onClick PublishChapter
                         ]
                    [ text "Publish" ]
                ]
            ]
        , aside []
            [ div [ class "participants" ]
                [ h2 [] [ text "Participants" ]
                , participantListView narration.characters chapter.participants
                , h2 [] [ text "Media" ]
                , div [ class "image-selector" ]
                    [ fileSelector
                        UpdateSelectedBackgroundImage
                        (case chapter.backgroundImage of
                           Just image -> image
                           Nothing -> "")
                        (List.map
                           (\file -> (file, file))
                           narration.files.backgroundImages)
                    ]
                , em [] [ text "Preview" ]
                , text ":"
                , br [] []
                , img [ class "tiny-image-preview"
                      , src (case chapter.backgroundImage of
                               Just image ->
                                 "/static/narrations/" ++
                                   (toString chapter.narrationId) ++
                                   "/background-images/" ++
                                   image
                               Nothing ->
                                 "no-preview.png")
                      ]
                    []
                , div [ class "audio-selector" ]
                    [ fileSelector
                        UpdateSelectedAudio
                        (case chapter.audio of
                           Just audio -> audio
                           Nothing -> "")
                        (List.map
                           (\file -> (file, file))
                           narration.files.audio)
                    ]
                ]
            ]
        ]
    ]


view : Model -> Html Msg
view model =
  let
    chapter = case model.chapter of
                Just chapter -> chapter
                Nothing -> fakeChapter
    narration = case model.narration of
                  Just narration -> narration
                  Nothing -> fakeNarration
  in
    chapterView chapter narration
