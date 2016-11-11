module NarratorApp.Views.ChapterEdit exposing (..)

import Json.Encode

import Html exposing (Html, h2, div, main', nav, section, aside, ul, li, img, a, input, button, audio, br, span, label, em, text)
import Html.Attributes exposing (id, class, href, src, target, type', value, placeholder, checked, disabled)
import Html.Events exposing (onClick, onInput)

import NarratorApp.Models exposing (Model, Chapter, Character, Narration, EditorToolState)
import NarratorApp.Messages exposing (..)
import NarratorApp.Views.FileSelector exposing (fileSelector)
import NarratorApp.Views.Participants exposing (participantListView)

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

addImageView : String -> Html Msg
addImageView newImageUrl =
  div [ class "add-image" ]
    [ input [ type' "text"
            , onInput UpdateNewImageUrl
            , value newImageUrl
            ]
        []
    , button [ onClick AddImage ]
        [ text "Add Image" ]
    ]

characterForMention : Character -> Bool -> Html Msg
characterForMention character isSelected =
  let
    message = if isSelected then
                (RemoveNewMentionCharacter character)
              else
                (AddNewMentionCharacter character)
  in
    label []
      [ input [ type' "checkbox"
              , checked isSelected
              , onClick message
              ]
          [ ]
      , text character.name
      ]

markForCharacter : List Character -> List Character -> Html Msg
markForCharacter allCharacters newMentionTargets =
  div []
    [ text "Mark text for "
    , div []
        (List.map
           (\c -> characterForMention c <| List.member c newMentionTargets)
           allCharacters)
    , button [ onClick AddMention ]
        [ text "Mark" ]
    ]

chapterView : Chapter -> Narration -> EditorToolState -> Html Msg
chapterView chapter narration editorToolState =
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
            , addImageView editorToolState.newImageUrl
            , markForCharacter chapter.participants editorToolState.newMentionTargets
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
                , participantListView chapter.id narration.characters chapter.participants
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
                    , button [ class "btn btn-small"
                             , onClick PlayPauseAudioPreview
                             ]
                        [ text "Preview"
                        , span [ id "bigger" ] [ text "♫" ]
                        ]
                    , case chapter.audio of
                        Just chapterAudio ->
                          audio [ id "audio-preview"
                                , src ("/static/narrations/" ++
                                         (toString chapter.narrationId) ++
                                         "/audio/" ++ chapterAudio)
                                ]
                            []
                        Nothing ->
                          text ""
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
    chapterView chapter narration model.editorToolState
