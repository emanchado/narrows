module NarrationCreationApp.Views exposing (..)

import Html exposing (Html, main_, h1, section, div, form, input, label, button, ul, li, a, hr, text)
import Html.Attributes exposing (id, class, href, target, type_, name, placeholder, value, disabled)
import Html.Events exposing (onInput, onClick, on)

import Common.Models exposing (MediaType(..))
import Common.Views exposing (onPreventDefaultClick, bannerView, breadcrumbNavView)
import Common.Views.FileSelector exposing (fileSelector)
import NarrationCreationApp.Messages exposing (..)
import NarrationCreationApp.Models exposing (..)


mainView : Model -> Html Msg
mainView model =
  let
    (mainCssClass, pageTitle) =
      if model.narrationId == Nothing then
        ("app-container app-container-simple", "New narration")
      else
        ("app-container", "Edit narration")
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
      , div [ class "narration-header" ]
          [ h1 [] [ text pageTitle ]
          , bannerView model.banner
          ]
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
                              [ label [] [ text "Intro background image" ]
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
                              ]
                          , div [ class "form-line" ]
                              [ label [] [ text "Intro audio" ]
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
                              ]
                          ]
                      , div [ class "btn-bar" ]
                          [ a [ class "btn"
                              , href model.introUrl
                              , target "_blank"
                              ]
                              [ text "Preview intro"
                              ]
                          , button [ class "btn btn-default"
                                   , type_ "submit"
                                   , onPreventDefaultClick SaveNarration
                                   ]
                              [ text "Save" ]
                          , button [ class "btn"
                                   , onPreventDefaultClick CancelCreateNarration
                                   ]
                              [ text "Cancel" ]
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
