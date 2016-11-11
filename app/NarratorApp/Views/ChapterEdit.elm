module NarratorApp.Views.ChapterEdit exposing (..)

import Json.Encode

import Html exposing (Html, h2, div, main', nav, section, aside, ul, li, img, a, input, select, option, button, br, em, text)
import Html.Attributes exposing (id, class, href, src, target, type', value, placeholder, checked, disabled)
import Html.Events exposing (onClick, onInput)

import NarratorApp.Models exposing (Model, Chapter, Character, Narration)
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

chapterView : Chapter -> Narration -> String -> Html Msg
chapterView chapter narration newImageUrl =
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
            , addImageView newImageUrl
            -- , markForCharacter
  -- <div>
  --   Mark text for ${ characterSelector("mentionCharacters", participants, state, send) }
  --   <button onclick=${ () => send("markTextForCharacter", { characters: [{id: 1, name: "Mildred Mayfield"}] }) }>Mark</button>
  -- </div>
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
    chapterView chapter narration model.newImageUrl
