module NarrationCreationApp.Views exposing (..)

import Html exposing (Html, main_, h1, h2, section, div, span, form, input, label, button, ul, li, a, hr, img, audio, text)
import Html.Attributes exposing (id, class, style, href, target, type_, name, placeholder, value, disabled, src, checked)
import Html.Events exposing (onInput, onClick, on)

import Common.Models exposing (MediaType(..), StyleSet)
import Common.Views exposing (onPreventDefaultClick, bannerView, breadcrumbNavView, horizontalSpinner)
import Common.Views.FileSelector exposing (fileSelector)
import NarrationCreationApp.Messages exposing (..)
import NarrationCreationApp.Models exposing (..)


titleStyles : StyleSet -> List (Html.Attribute x)
titleStyles styles =
  let
    titleFont = case styles.titleFont of
                  Just font -> "NARROWS title user font"
                  Nothing -> "StoryFont"
    titleFontSize = case styles.titleFontSize of
                      Just size -> size
                      Nothing -> "60px"
    titleColor = case styles.titleColor of
                   Just color -> color
                   Nothing -> "#e5e5e5"
    titleShadowColor = case styles.titleShadowColor of
                         Just shadowColor -> shadowColor
                         Nothing -> "#000000"
  in
    [ style "font-family" titleFont
    , style "font-size" titleFontSize
    , style "color" titleColor
    , style "text-shadow" <| "3px 3px 0 " ++ titleShadowColor ++ ", -1px -1px 0 " ++ titleShadowColor ++ ", 1px -1px 0 " ++ titleShadowColor ++ ", -1px 1px 0 " ++ titleShadowColor ++ ", 1px 1px 0 " ++ titleShadowColor
    ]


bodyTextStyles : StyleSet -> List (Html.Attribute x)
bodyTextStyles styles =
  let
    bodyTextFont = case styles.bodyTextFont of
                  Just font -> "NARROWS body user font"
                  Nothing -> "StoryFont"
    bodyTextFontSize = case styles.bodyTextFontSize of
                      Just size -> size
                      Nothing -> "18px"
    bodyTextColor = case styles.bodyTextColor of
                   Just color -> color
                   Nothing -> "#000000"
    bodyTextBackgroundColor = case styles.bodyTextBackgroundColor of
                         Just bgColor -> bgColor
                         Nothing -> "#e5e5e5"
  in
    [ style "font-family" bodyTextFont
    , style "font-size" bodyTextFontSize
    , style "color" bodyTextColor
    , style "background-color" bodyTextBackgroundColor
    ]


charOffset : Char -> Char -> Int
charOffset basis c =
  Char.toCode c - Char.toCode basis

isBetween : Char -> Char -> Char -> Bool
isBetween lower upper c =
    let
      ci = Char.toCode c
    in
      Char.toCode lower <= ci && ci <= Char.toCode upper

intFromChar : Char -> Int
intFromChar c =
  if isBetween '0' '9' c then
    charOffset '0' c
  else if isBetween 'a' 'f' c then
    10 + charOffset 'a' c
  else if isBetween 'A' 'F' c then
    10 + charOffset 'A' c
  else
    0

colorLightness : String -> Float
colorLightness hexString =
  let
    lightnessMaximum = 765  -- Value for #ffffff
    withoutHash = String.dropLeft 1 hexString
    characterValues = List.indexedMap
                        (\i x -> if modBy 2 i == 0 then
                                   16 * (intFromChar x)
                                 else
                                   intFromChar x) <|
                        String.toList withoutHash
  in
    (toFloat (List.sum characterValues)) / lightnessMaximum


contrastingBackgroundColor : String -> String
contrastingBackgroundColor color =
  if colorLightness color > 0.5 then
    "#333"
  else
    "#ccc"


mainView : Model -> Html Msg
mainView model =
  let
    (mainCssClass, pageTitle, narrationId) =
      case model.narrationId of
        Just id ->
          ("app-container", "Edit narration", id)
        Nothing ->
          ("app-container app-container-simple", "New narration", -1)
    separatorImageFullUrl = case model.styles.separatorImage of
                              Just image -> "/static/narrations/"
                                              ++ (String.fromInt narrationId)
                                              ++ "/images/"
                                              ++ image
                              Nothing -> "/img/separator.png"
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
                      [ h2 [] [ text "Intro" ]
                      , div [ class "form-line" ]
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
                            [ label [] [ text "Text" ]
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
                                          model.uploadingBackgroundImage
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
                                          model.uploadingAudio
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
                      [ h2 [] [ text "Chapter defaults" ]
                      , div [ class "form-line" ]
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
                      , h2 [] [ text "Narration custom styles" ]
                      , div [ class "form-line" ]
                          [ label [] [ text "Title font" ]
                          , fileSelector
                              UpdateSelectedTitleFont
                              OpenMediaFileSelector
                              (AddMediaFile Font NarrationTitleStylesTarget)
                              "new-title-font-file"
                              model.uploadingFont  -- disabled?
                              (case model.styles.titleFont of
                                 Just font -> font
                                 Nothing -> "")
                              (List.map
                                 (\file -> (file, file))
                                 files.fonts)
                          ]
                      , div [ class "form-line" ]
                          [ label []
                              [ text "Title font size"
                              , input [ type_ "checkbox"
                                      , checked (model.styles.titleFontSize /= Nothing)
                                      , onClick ToggleCustomTitleFontSize
                                      ]
                                  []
                              ]
                          , case model.styles.titleFontSize of
                              Just size ->
                                div []
                                  [ input [ type_ "number"
                                          , value size
                                          , onInput UpdateTitleFontSize
                                          ]
                                      []
                                  ]
                              Nothing ->
                                div []
                                  [ input [ type_ "number"
                                          , disabled True
                                          ]
                                      []
                                  ]
                          ]
                      , div [ class "form-line" ]
                          [ label []
                              [ text "Title color"
                              , input [ type_ "checkbox"
                                      , checked (model.styles.titleColor /= Nothing)
                                      , onClick ToggleCustomTitleColor
                                      ]
                                  []
                              ]
                          , case model.styles.titleColor of
                              Just color ->
                                div []
                                  [ input [ type_ "color"
                                          , value color
                                          , onInput UpdateTitleColor
                                          ]
                                      []
                                  ]
                              Nothing ->
                                div []
                                  [ input [ type_ "color"
                                          , disabled True
                                          ]
                                      []
                                  ]
                          ]
                      , div [ class "form-line" ]
                          [ label []
                              [ text "Title shadow color"
                              , input [ type_ "checkbox"
                                      , checked (model.styles.titleShadowColor /= Nothing)
                                      , onClick ToggleCustomTitleShadowColor
                                      ]
                                  []
                              ]
                          , case model.styles.titleShadowColor of
                              Just color ->
                                div []
                                  [ input [ type_ "color"
                                          , value color
                                          , onInput UpdateTitleShadowColor
                                          ]
                                      []
                                  ]
                              Nothing ->
                                div []
                                  [ input [ type_ "color"
                                          , disabled True
                                          ]
                                      []
                                  ]
                          ]
                      , div [ class "form-line" ]
                          [ label [] [ text "Body text font" ]
                          , fileSelector
                              UpdateSelectedBodyTextFont
                              OpenMediaFileSelector
                              (AddMediaFile Font NarrationBodyTextStylesTarget)
                              "new-body-text-font-file"
                              model.uploadingFont  -- disabled?
                              (case model.styles.bodyTextFont of
                                 Just font -> font
                                 Nothing -> "")
                              (List.map
                                 (\file -> (file, file))
                                 files.fonts)
                          ]
                      , div [ class "form-line" ]
                          [ label []
                              [ text "Body text font size"
                              , input [ type_ "checkbox"
                                      , checked (model.styles.bodyTextFontSize /= Nothing)
                                      , onClick ToggleCustomBodyTextFontSize
                                      ]
                                  []
                              ]
                          , case model.styles.bodyTextFontSize of
                              Just size ->
                                div []
                                  [ input [ type_ "number"
                                          , value size
                                          , onInput UpdateBodyTextFontSize
                                          ]
                                      []
                                  ]
                              Nothing ->
                                div []
                                  [ input [ type_ "number"
                                          , disabled True
                                          ]
                                      []
                                  ]
                          ]
                      , div [ class "form-line" ]
                          [ label []
                              [ text "Body text color"
                              , input [ type_ "checkbox"
                                      , checked (model.styles.bodyTextColor /= Nothing)
                                      , onClick ToggleCustomBodyTextColor
                                      ]
                                  []
                              ]
                          , case model.styles.bodyTextColor of
                              Just color ->
                                div []
                                  [ input [ type_ "color"
                                          , value color
                                          , onInput UpdateBodyTextColor
                                          ]
                                      []
                                  ]
                              Nothing ->
                                div []
                                  [ input [ type_ "color"
                                          , disabled True
                                          ]
                                      []
                                  ]
                          ]
                      , div [ class "form-line" ]
                          [ label []
                              [ text "Body text background color"
                              , input [ type_ "checkbox"
                                      , checked (model.styles.bodyTextBackgroundColor /= Nothing)
                                      , onClick ToggleCustomBodyTextBackgroundColor
                                      ]
                                  []
                              ]
                          , case model.styles.bodyTextBackgroundColor of
                              Just color ->
                                div []
                                  [ input [ type_ "color"
                                          , value color
                                          , onInput UpdateBodyTextBackgroundColor
                                          ]
                                      []
                                  ]
                              Nothing ->
                                div []
                                  [ input [ type_ "color"
                                          , disabled True
                                          ]
                                      []
                                  ]
                          ]
                      , div [ class "form-line" ]
                          [ div [ class "image-selector" ]
                                [ label [] [ text "Horizontal separator image"
                                           , if model.uploadingImage then
                                               horizontalSpinner
                                             else
                                               text ""
                                           ]
                                , fileSelector
                                    UpdateSelectedSeparatorImage
                                    OpenMediaFileSelector
                                    (AddMediaFile Image NarrationBodyTextStylesTarget)
                                    "new-separator-image-file"
                                    model.uploadingImage
                                    (case model.styles.separatorImage of
                                       Just image -> image
                                       Nothing -> "")
                                    (List.map
                                       (\file -> (file, file))
                                       files.images)
                                , img (List.append
                                         [ class "separator-image-preview"
                                         , src separatorImageFullUrl
                                         ]
                                         (bodyTextStyles model.styles))
                                    []
                                ]
                          ]
                      , div [ class "form-line" ]
                          [ label []
                              [ text "Preview" ]
                          , div [ class "narration-styles-preview chapter"
                                , style "background-color" <| contrastingBackgroundColor <| Maybe.withDefault "#e5e5e5" model.styles.titleColor
                                ]
                              [ div (List.append
                                       [ class "title-preview" ]
                                       (titleStyles model.styles))
                                  [ text model.title
                                  ]
                              , div (List.append
                                       [ class "body-text-preview" ]
                                       (bodyTextStyles model.styles))
                                  [ text "Some example chapter text."
                                  , div (List.append
                                           [ class "separator"
                                           , style "background-image" <| "url(" ++ separatorImageFullUrl ++ ")"
                                           ]
                                           (bodyTextStyles model.styles))
                                      []
                                  , text "Some example chapter text."
                                  ]
                              ]
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
