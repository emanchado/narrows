module ChapterEditApp.Views exposing (mainView)

import String
import Json.Decode

import Html exposing (Html, h2, div, main', nav, section, aside, ul, li, img, a, input, button, audio, br, span, label, em, text)
import Html.Attributes exposing (id, name, class, href, src, target, type', value, placeholder, checked, disabled)
import Html.Events exposing (onClick, onInput, on)

import Common.Models exposing (FullCharacter, Narration, Chapter)
import ChapterEditApp.Models exposing (Model, EditorToolState)
import ChapterEditApp.Messages exposing (..)
import ChapterEditApp.Views.FileSelector exposing (fileSelector)
import ChapterEditApp.Views.Participants exposing (participantListView)

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

characterForMention : FullCharacter -> Bool -> Html Msg
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

markForCharacter : List FullCharacter -> List FullCharacter -> Html Msg
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
  let
    (saveAction, publishAction) = if chapter.id == 0 then
                                    (SaveNewChapter, PublishNewChapter)
                                  else
                                    (SaveChapter, PublishChapter)
  in
    div [ id "narrator-app" ]
      [ nav []
          [ a [ href ("/narrations/" ++ (toString chapter.narrationId)) ]
              [ text "Narration" ]
          , text " ⇢ "
          , (if String.isEmpty chapter.title then
               em [] [ text "New chapter" ]
             else
               text chapter.title)
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
                           , onClick saveAction
                           ]
                      [ text "Save" ]
                  , button [ class "btn btn-default"
                           , onClick publishAction
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
                  , em [] [ text "Preview:" ]
                  , br [] []
                  , img [ class "tiny-image-preview"
                        , src (case chapter.backgroundImage of
                                 Just image ->
                                   "/static/narrations/" ++
                                     (toString chapter.narrationId) ++
                                     "/background-images/" ++
                                     image
                                 Nothing ->
                                   "/img/no-preview.png")
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
                      , button [ class "btn btn-small btn-default"
                               , onClick (OpenMediaFileSelector "new-media-file")
                               ]
                          [ text "Add files" ]
                      , input [ type' "file"
                              , id "new-media-file"
                              , name "file"
                              , on "change" (Json.Decode.succeed <| AddMediaFile "new-media-file")
                              ]
                          []
                      ]
                  ]
              ]
          ]
      ]


mainView : Model -> Html Msg
mainView model =
  let
    chapter = case model.chapter of
                Just chapter -> chapter
                Nothing -> Common.Models.loadingPlaceholderChapter
    narration = case model.narration of
                  Just narration -> narration
                  Nothing -> Common.Models.loadingPlaceholderNarration
  in
    chapterView chapter narration model.editorToolState
