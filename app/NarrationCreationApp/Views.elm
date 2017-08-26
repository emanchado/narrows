module NarrationCreationApp.Views exposing (..)

import Html exposing (Html, main_, h1, h2, div, form, input, label, button, ul, li, a, text)
import Html.Attributes exposing (id, class, href, type_, name, placeholder, value, disabled)
import Html.Events exposing (onInput, onClick, on)

import Common.Models exposing (MediaType(..))
import Common.Views exposing (onPreventDefaultClick, bannerView)
import Common.Views.FileSelector exposing (fileSelector)
import NarrationCreationApp.Messages exposing (..)
import NarrationCreationApp.Models exposing (..)


mainView : Model -> Html Msg
mainView model =
  let
    (pageTitle, saveAction, saveButtonLabel) =
      if model.narrationId == Nothing then
        ("New narration", CreateNarration, "Create")
      else
        ("Edit narration", SaveNarration, "Save")
  in
    main_ [ id "narrator-app"
          , class "app-container app-container-simple"
          ]
      [ h1 [] [ text pageTitle ]
      , bannerView model.banner
      , form [ class "vertical-form" ]
          [ label [] [ text "Title:" ]
          , div []
              [ input
                  [ class "large-text-input"
                  , type_ "text"
                  , placeholder "Title"
                  , value model.title
                  , onInput UpdateTitle
                  ]
                  []
              ]
          , case model.files of
              Just files ->
                div []
                  [ label [] [ text "Default background image:" ]
                  , div []
                      [ fileSelector
                          UpdateSelectedBackgroundImage
                          OpenMediaFileSelector
                          (AddMediaFile BackgroundImage)
                          "new-bg-image-file"
                          False -- disabled?
                          (case model.defaultBackgroundImage of
                             Just bgImage -> bgImage
                             Nothing -> "")
                          (List.map
                             (\file -> (file, file))
                             files.backgroundImages)
                      ]
                  , label [] [ text "Default audio:" ]
                  , div []
                      [ fileSelector
                          UpdateSelectedAudio
                          OpenMediaFileSelector
                          (AddMediaFile Audio)
                          "new-audio-file"
                          False -- disabled?
                          (case model.defaultAudio of
                             Just audio -> audio
                             Nothing -> "")
                          (List.map
                             (\file -> (file, file))
                             files.audio)
                      ]
                  ]
              Nothing ->
                div [] []
          , div [ class "btn-bar" ]
              [ button [ class "btn btn-default"
                       , type_ "submit"
                       , onPreventDefaultClick saveAction
                       ]
                  [ text saveButtonLabel ]
              , button [ class "btn"
                       , onPreventDefaultClick CancelCreateNarration
                       ]
                  [ text "Cancel" ]
              ]
          ]
      ]
