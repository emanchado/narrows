module ChapterEditApp.Views exposing (mainView)

import String
import Json.Decode
import Html exposing (Html, h2, h3, div, main_, nav, section, ul, li, img, a, input, button, audio, br, span, label, strong, em, text)
import Html.Attributes exposing (id, name, class, href, src, target, type_, value, placeholder, checked, disabled)
import Html.Events exposing (onClick, onInput, on)
import Common.Models exposing (FullCharacter, Narration, Chapter)
import Common.Views exposing (bannerView, breadcrumbNavView, onStopPropagationClick, horizontalSpinner)
import ChapterEditApp.Models exposing (Model, LastReactions, LastChapter, LastReaction)
import ChapterEditApp.Messages exposing (..)
import ChapterEditApp.Views.FileSelector exposing (fileSelector)
import ChapterEditApp.Views.Participants exposing (participantListView, participantPreviewsView)


chapterMediaView : Chapter -> Narration -> Bool -> Bool -> Html Msg
chapterMediaView chapter narration uploadingAudio uploadingBackgroundImage =
  div [ class "chapter-media" ]
    [ div [ class "image-selector" ]
        [ label []
            [ text "Background image:"
            , if uploadingBackgroundImage then
                horizontalSpinner
              else
                text ""
            ]
        , div []
            [ fileSelector
                UpdateSelectedBackgroundImage
                uploadingBackgroundImage
                (case chapter.backgroundImage of
                   Just image -> image
                   Nothing -> "")
                (List.map
                   (\file -> (file, file))
                   narration.files.backgroundImages)
            , button [ class "btn btn-small btn-add"
                     , onClick (OpenMediaFileSelector "new-bg-image-file")
                     ]
                [ text "Upload" ]
            , input [ type_ "file"
                    , id "new-bg-image-file"
                    , class "invisible"
                    , name "file"
                    , on "change" (Json.Decode.succeed <| AddMediaFile BackgroundImage "new-bg-image-file")
                    ]
                []
            ]
        , img [ class "tiny-image-preview"
              , src (case chapter.backgroundImage of
                       Just image -> "/static/narrations/"
                                       ++ (toString chapter.narrationId)
                                       ++ "/background-images/"
                                       ++ image
                       Nothing -> "/img/no-preview.png")
              ]
            []
        ]
    , div [ class "audio-selector" ]
        [ label []
            [ text "Background audio:"
            , if uploadingAudio then
                horizontalSpinner
              else
                text ""
            ]
        , div []
            [ fileSelector
                UpdateSelectedAudio
                uploadingAudio
                (case chapter.audio of
                   Just audio -> audio
                   Nothing -> "")
                (List.map
                   (\file -> (file, file))
                   narration.files.audio)
            , button [ class "btn btn-small btn-add"
                     , onClick (OpenMediaFileSelector "new-audio-file")
                     ]
                [ text "Upload" ]
            , input [ type_ "file"
                    , id "new-audio-file"
                    , class "invisible"
                    , name "file"
                    , on "change" (Json.Decode.succeed <| AddMediaFile Audio "new-audio-file")
                    ]
                []
            ]
        , button [ class "btn btn-small"
                 , onClick PlayPauseAudioPreview
                 ]
            [ text "Preview"
            , span [ id "bigger" ] [ text "♫" ]
            ]
        , case chapter.audio of
            Just chapterAudio ->
              audio [ id "audio-preview"
                    , src ("/static/narrations/"
                             ++ (toString chapter.narrationId)
                             ++ "/audio/"
                             ++ chapterAudio)
                    ]
                []
            Nothing ->
              text ""
        ]
    ]


chapterView : Chapter -> Narration -> Bool -> Bool -> Html Msg
chapterView chapter narration uploadingAudio uploadingBackgroundImage =
  let
    (saveAction, publishAction) =
      if chapter.id == 0 then
        (SaveNewChapter, PublishNewChapter)
      else
        (SaveChapter, PublishChapter)
  in
    section [ class "page-aside" ]
      [ section []
          [ input [ class "chapter-title"
                  , type_ "text"
                  , placeholder "Title"
                  , value chapter.title
                  , onInput UpdateChapterTitle
                  ]
              []
          , div [ class "participant-list" ]
              [ label [] [ text "Participants:" ]
              , participantListView chapter.id narration.characters chapter.participants
              ]
          ]
      , chapterMediaView chapter narration uploadingAudio uploadingBackgroundImage
      , label [] [ text "Text:" ]
      , div [ id "editor-container"
            , class "editor-container"
            ]
          []
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
      , participantPreviewsView chapter.id chapter.participants
      ]


reactionView : LastReaction -> Html Msg
reactionView reaction =
  li []
    [ strong [] [ text reaction.character.name ]
    , text ", in chapter "
    , strong [] [ text reaction.chapterInfo.title ]
    , text ":"
    , div [ class "last-reaction-text" ]
        [ case reaction.text of
            Just reactionText -> text reactionText
            Nothing -> em [ class "no-content" ]
                         [ text "Has not reacted yet." ]
        ]
    ]


-- Need to always produce the placeholder markup for the text, but may
-- mark as "invisible" so that the chapter is not actually rendered by
-- the browser. This will make it possible to show/hide dynamically on
-- the frontend according to the current chapter's participants.
lastChapterView : List Int -> LastChapter -> Html Msg
lastChapterView participantChapterIds chapter =
  let
    extraClass =
      if List.member chapter.id participantChapterIds then
        ""
      else
        " invisible"
  in
    li []
      [ h3 [] [ text chapter.title ]
      , div [ id <| "chapter-text-" ++ (toString chapter.id)
            , class <| "chapter" ++ extraClass
            ]
          []
      ]


findLastChapter : List LastChapter -> Int -> Maybe LastChapter
findLastChapter chapterList chapterId =
  List.head <|
    List.filter (\c -> c.id == chapterId) chapterList


lastReactionListView : LastReactions -> Chapter -> Html Msg
lastReactionListView lastReactions chapter =
  let
    participantIds =
      List.map (\p -> p.id) chapter.participants
    participantChapterIds =
      List.filter
        (\chapterId -> chapterId > 0)
        (List.map
           (\r ->
              if List.member r.character.id participantIds then
                r.chapterInfo.id
              else
                -1)
           lastReactions.reactions)
  in
    section []
      [ h2 [] [ text "Last reactions" ]
      , ul [ class "last-reactions narrator" ]
          (List.map
            (\r ->
              if List.member r.character.id participantIds then
                reactionView r
              else
                text "")
            lastReactions.reactions)
      , h2 [] [ text "Last chapters" ]
      , ul [ class "last-chapters narrator" ]
          (List.map
             (lastChapterView participantChapterIds)
             lastReactions.chapters)
      ]


showDialog : String -> String -> Msg -> String -> Msg -> Html Msg
showDialog dialogText okText okMessage cancelText cancelMessage =
  div [ class "dialog-overlay"
      , onClick cancelMessage
      ]
    [ div [ class "dialog"
          , onStopPropagationClick NoOp
          ]
        [ div [ class "dialog-text" ]
            [ text dialogText ]
        , div [ class "btn-bar" ]
            [ button [ class "btn btn-small btn-default"
                     , onClick okMessage
                     ]
                [ text okText ]
            , button [ class "btn btn-small"
                     , onClick cancelMessage
                     ]
                [ text cancelText ]
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
    div [ id "narrator-app", class "app-container" ]
      [ breadcrumbNavView
          NavigateTo
          [ { title = "Home"
            , url = "/"
            }
          , { title = narration.title
            , url = "/narrations/" ++ (toString chapter.narrationId)
            }
          ]
          (if String.isEmpty chapter.title then
            em [] [ text "New chapter" ]
           else
            text chapter.title)
      , bannerView model.banner
      , div [ class "two-column" ]
          [ case model.lastReactions of
              Just lastReactions -> lastReactionListView lastReactions chapter
              Nothing -> section [] [ text "Loading reactions…" ]
          , section []
              [ chapterView chapter narration model.uploadingAudio model.uploadingBackgroundImage
              , bannerView model.flash
              , if model.showPublishChapterDialog then
                  showDialog
                    "Publish chapter?"
                    "Publish"
                    ConfirmPublishChapter
                    "Cancel"
                    CancelPublishChapter
                else
                  text ""
              ]
          ]
      ]
