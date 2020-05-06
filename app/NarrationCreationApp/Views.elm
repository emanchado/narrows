module NarrationCreationApp.Views exposing (..)

import Html exposing (Html, main_, h1, section, div, span, form, input, label, button, ul, li, a, hr, img, audio, text)
import Html.Attributes exposing (id, class, href, target, type_, name, placeholder, value, disabled, src)
import Html.Events exposing (onInput, onClick, on)

import Common.Models exposing (MediaType(..))
import Common.Views exposing (onPreventDefaultClick, bannerView, breadcrumbNavView, horizontalSpinner)
import Common.Views.FileSelector exposing (fileSelector)
import NarrationCreationApp.Messages exposing (..)
import NarrationCreationApp.Models exposing (..)


mainView : Model -> Html Msg
mainView model =
  let
    (mainCssClass, pageTitle, narrationId) =
      case model.narrationId of
        Just id ->
          ("app-container", "Edit narration", id)
        Nothing ->
          ("app-container app-container-simple", "New narration", -1)
  in
    main_ [ id "narrator-app"
          , class "app-container"
          ]
      [ breadcrumbNavView
          [ { title = "Home"
            , url = "/"
            }
          ]
          (text pageTitle)
      , h1 [] [ text pageTitle ]
      , case model.files of
          Just files ->
            form [ class "vertical-form" ]
              [ div [ class "two-column" ]
                  [ section []
                      [ div [ class "form-line" ]
                          [ label [] [ text "Title" ]
                          , input [ class "large-text-input"
                                  , type_ "text"
                                  , placeholder "Title"
                                  , value model.title
                                  , onInput UpdateTitle
                                  ]
                              []
                          ]
                      , div []
                          [ div [ class "form-line" ]
                            [ label [] [ text "Intro text" ]
                            , div [ id "intro-editor"
                                  , class "editor-container"
                                  ]
                                []
                            ]
                          , div [ class "form-line" ]
                              [ div [ class "chapter-media" ]
                                  [ div [ class "image-selector" ]
                                      [ label [] [ text "Intro background image"
                                                 , if model.uploadingBackgroundImage then
                                                     horizontalSpinner
                                                   else
                                                     text ""
                                                 ]
                                      , fileSelector
                                          UpdateSelectedIntroBackgroundImage
                                          OpenMediaFileSelector
                                          (AddMediaFile BackgroundImage NarrationIntroTarget)
                                          "new-intro-bg-image-file"
                                          False -- disabled?
                                          (case model.introBackgroundImage of
                                             Just bgImage -> bgImage
                                             Nothing -> "")
                                          (List.map
                                             (\file -> (file, file))
                                             files.backgroundImages)
                                      , img [ class "tiny-image-preview"
                                            , src (case model.introBackgroundImage of
                                                     Just image -> "/static/narrations/"
                                                                     ++ (String.fromInt narrationId)
                                                                     ++ "/background-images/"
                                                                     ++ image
                                                     Nothing -> "/img/no-preview.png")
                                            ]
                                          []
                                      ]
                                  , div [ class "audio-selector" ]
                                      [ label [] [ text "Intro audio"
                                                 , if model.uploadingAudio then
                                                     horizontalSpinner
                                                   else
                                                     text ""
                                                 ]
                                      , fileSelector
                                          UpdateSelectedIntroAudio
                                          OpenMediaFileSelector
                                          (AddMediaFile Audio NarrationIntroTarget)
                                          "new-intro-audio-file"
                                          False -- disabled?
                                          (case model.introAudio of
                                             Just audio -> audio
                                             Nothing -> "")
                                          (List.map
                                             (\file -> (file, file))
                                             files.audio)
                                      , button [ class "btn btn-small"
                                               , type_ "button"
                                               , onClick PlayPauseAudioPreview
                                               ]
                                          [ text "Preview"
                                          , span [ id "bigger" ] [ text "♫" ]
                                          ]
                                      , case model.introAudio of
                                          Just introAudio ->
                                            audio [ id "audio-preview"
                                                  , src ("/static/narrations/"
                                                           ++ (String.fromInt narrationId)
                                                           ++ "/audio/"
                                                           ++ introAudio)
                                                  ]
                                              []
                                          Nothing ->
                                            text ""
                                      ]
                                  ]
                              ]
                          ]
                      , div [ class "btn-bar-status" ]
                          [ bannerView model.banner
                          , div [ class "btn-bar" ]
                              [ a [ class "btn"
                                  , href model.introUrl
                                  , target "_blank"
                                  ]
                                  [ text "Preview intro"
                                  ]
                              , button [ class "btn btn-default"
                                       , type_ "submit"
                                       , disabled (not model.narrationModified)
                                       , onPreventDefaultClick SaveNarration
                                       ]
                                  [ text "Save" ]
                              , button [ class "btn"
                                       , onPreventDefaultClick CancelCreateNarration
                                       ]
                                  [ text "Cancel" ]
                              ]
                          ]
                      ]
                  , section []
                      [ div [ class "form-line" ]
                          [ label [] [ text "Default background image for the narration" ]
                          , fileSelector
                              UpdateSelectedDefaultBackgroundImage
                              OpenMediaFileSelector
                              (AddMediaFile BackgroundImage NarrationDefaultTarget)
                              "new-default-bg-image-file"
                              False -- disabled?
                              (case model.defaultBackgroundImage of
                                 Just bgImage -> bgImage
                                 Nothing -> "")
                              (List.map
                                 (\file -> (file, file))
                                 files.backgroundImages)
                          ]
                      , div [ class "form-line" ]
                          [ label [] [ text "Default audio for the narration" ]
                          , fileSelector
                              UpdateSelectedDefaultAudio
                              OpenMediaFileSelector
                              (AddMediaFile Audio NarrationDefaultTarget)
                              "new-default-audio-file"
                              False -- disabled?
                              (case model.defaultAudio of
                                 Just audio -> audio
                                 Nothing -> "")
                              (List.map
                                 (\file -> (file, file))
                                 files.audio)
                          ]
                      ]
                  ]
              ]
          Nothing ->
            form [ class "narrow-form vertical-form" ]
              [ div [ class "form-line" ]
                  [ label [] [ text "Title" ]
                  , input [ class "large-text-input"
                          , type_ "text"
                          , placeholder "Title"
                          , value model.title
                          , onInput UpdateTitle
                          ]
                      []
                  ]
                  , div [ class "btn-bar" ]
                      [ button [ class "btn btn-default"
                               , type_ "submit"
                               , onPreventDefaultClick CreateNarration
                               ]
                          [ text "Create" ]
                      , button [ class "btn"
                               , onPreventDefaultClick CancelCreateNarration
                               ]
                          [ text "Cancel" ]
                      ]
              ]
      ]
