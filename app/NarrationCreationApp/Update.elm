module NarrationCreationApp.Update exposing (..)

import Browser.Navigation as Nav
import Process
import Task

import Core.Routes exposing (Route(..))
import Common.Models exposing (Banner, successBanner, errorBanner, updateNarrationFiles, mediaTypeString, MediaType(..))
import Common.Ports exposing (initEditor, openFileInput, uploadFile, playPauseAudioPreview)
import NarrationCreationApp.Api
import NarrationCreationApp.Messages exposing (..)
import NarrationCreationApp.Models exposing (..)
import NarrationCreationApp.Ports exposing (updateFontFaceDefinition)


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate route model =
  case route of
    NarrationCreationPage ->
      ( { model | title = ""
                , narrationId = Nothing
                , files = Nothing
                , uploadingAudio = False
                , uploadingBackgroundImage = False
                , banner = Nothing
                , narrationModified = False
        }
      , Cmd.none
      )

    NarrationEditPage narrationId ->
      ( { model | title = ""
                , narrationId = Just narrationId
                , files = Nothing
                , uploadingAudio = False
                , uploadingBackgroundImage = False
                , banner = Nothing
                , narrationModified = False
        }
      , NarrationCreationApp.Api.fetchNarration narrationId
      )

    _ ->
      ( model, Cmd.none )


showFlashMessage : Maybe Banner -> Cmd Msg
showFlashMessage maybeBanner =
  Cmd.batch
    [ Process.sleep 0
      |> Task.perform (\_ -> SetFlashMessage maybeBanner)
    , Process.sleep 2000
      |> Task.perform (\_ -> RemoveFlashMessage)
    ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    NoOp ->
      ( model, Cmd.none )

    NavigateTo url ->
      ( model, Nav.pushUrl model.key url )

    UpdateTitle newTitle ->
      ( { model | title = newTitle
                , narrationModified = True
        }
      , Cmd.none
      )

    UpdateIntro newIntro ->
      ( { model | intro = newIntro
                , narrationModified = True
        }
      , Cmd.none
      )

    UpdateSelectedIntroBackgroundImage newBgImage ->
      let
        newValue =
          case model.files of
            Just files ->
              List.head <|
                List.filter (\i -> i == newBgImage) files.backgroundImages
            Nothing -> Nothing
      in
        ( { model | introBackgroundImage = newValue
                  , narrationModified = True
                  , banner = Nothing
          }
        , Cmd.none
        )

    UpdateSelectedIntroAudio newAudio ->
      let
        newValue =
          case model.files of
            Just files ->
              List.head <|
                List.filter (\i -> i == newAudio) files.audio
            Nothing -> Nothing
      in
        ( { model | introAudio = newValue
                  , narrationModified = True
                  , banner = Nothing
          }
        , Cmd.none
        )

    UpdateSelectedDefaultBackgroundImage newBgImage ->
      let
        newValue =
          case model.files of
            Just files ->
              List.head <|
                List.filter (\i -> i == newBgImage) files.backgroundImages
            Nothing -> Nothing
      in
        ( { model | defaultBackgroundImage = newValue
                  , narrationModified = True
                  , banner = Nothing
          }
        , Cmd.none
        )

    UpdateSelectedDefaultAudio newAudio ->
      let
        newValue =
          case model.files of
            Just files ->
              List.head <|
                List.filter (\i -> i == newAudio) files.audio
            Nothing -> Nothing
      in
        ( { model | defaultAudio = newValue
                  , narrationModified = True
                  , banner = Nothing
          }
        , Cmd.none
        )

    UpdateSelectedTitleFont newFont ->
      let
        newValue =
          case model.files of
            Just files ->
              List.head <|
                List.filter (\i -> i == newFont) files.fonts
            Nothing -> Nothing
        styles = model.styles
        updatedStyles = { styles | titleFont = newValue }
      in
        ( { model | styles = updatedStyles
                  , narrationModified = True
                  , banner = Nothing
          }
        , case newValue of
            Just fontFace ->
              case model.narrationId of
                Just narrationId ->
                  updateFontFaceDefinition { fontFaceName = "NARROWS title user font"
                                           , fontUrl = "/static/narrations/" ++ (String.fromInt narrationId) ++ "/fonts/" ++ fontFace
                                           }
                Nothing ->
                  Cmd.none
            Nothing ->
              Cmd.none
        )

    ToggleCustomTitleFontSize ->
      let
        styles = model.styles
        updatedStyles = case styles.titleFontSize of
                          Just _ -> { styles | titleFontSize = Nothing }
                          Nothing -> { styles | titleFontSize = Just "60" }
      in
        ( { model | styles = updatedStyles
                  , narrationModified = True
          }
        , Cmd.none
        )

    UpdateTitleFontSize newSize ->
      let
        styles = model.styles
        updatedStyles = { styles | titleFontSize = Just newSize }
      in
        ( { model | styles = updatedStyles
                  , narrationModified = True
          }
        , Cmd.none
        )

    ToggleCustomTitleColor ->
      let
        styles = model.styles
        updatedStyles = case styles.titleColor of
                          Just _ -> { styles | titleColor = Nothing }
                          Nothing -> { styles | titleColor = Just "#e5e5e5" }
      in
        ( { model | styles = updatedStyles
                  , narrationModified = True
          }
        , Cmd.none
        )

    UpdateTitleColor newColor ->
      let
        styles = model.styles
        updatedStyles = { styles | titleColor = Just newColor }
      in
        ( { model | styles = updatedStyles
                  , narrationModified = True
          }
        , Cmd.none
        )

    ToggleCustomTitleShadowColor ->
      let
        styles = model.styles
        updatedStyles = case styles.titleShadowColor of
                          Just _ -> { styles | titleShadowColor = Nothing }
                          Nothing -> { styles | titleShadowColor = Just "#000" }
      in
        ( { model | styles = updatedStyles
                  , narrationModified = True
          }
        , Cmd.none
        )

    UpdateTitleShadowColor newColor ->
      let
        styles = model.styles
        updatedStyles = { styles | titleShadowColor = Just newColor }
      in
        ( { model | styles = updatedStyles
                  , narrationModified = True }
        , Cmd.none
        )

    UpdateSelectedBodyTextFont newFont ->
      let
        newValue =
          case model.files of
            Just files ->
              List.head <|
                List.filter (\i -> i == newFont) files.fonts
            Nothing -> Nothing
        styles = model.styles
        updatedStyles = { styles | bodyTextFont = newValue }
      in
        ( { model | styles = updatedStyles
                  , narrationModified = True
                  , banner = Nothing
          }
        , case newValue of
            Just fontFace ->
              case model.narrationId of
                Just narrationId ->
                  updateFontFaceDefinition { fontFaceName = "NARROWS body user font"
                                           , fontUrl = "/static/narrations/" ++ (String.fromInt narrationId) ++ "/fonts/" ++ fontFace
                                           }
                Nothing ->
                  Cmd.none
            Nothing ->
              Cmd.none
        )

    ToggleCustomBodyTextFontSize ->
      let
        styles = model.styles
        updatedStyles = case styles.bodyTextFontSize of
                          Just _ -> { styles | bodyTextFontSize = Nothing }
                          Nothing -> { styles | bodyTextFontSize = Just "18" }
      in
        ( { model | styles = updatedStyles
                  , narrationModified = True
          }
        , Cmd.none
        )

    UpdateBodyTextFontSize newSize ->
      let
        styles = model.styles
        updatedStyles = { styles | bodyTextFontSize = Just newSize }
      in
        ( { model | styles = updatedStyles
                  , narrationModified = True
          }
        , Cmd.none
        )

    ToggleCustomBodyTextColor ->
      let
        styles = model.styles
        updatedStyles = case styles.bodyTextColor of
                          Just _ -> { styles | bodyTextColor = Nothing }
                          Nothing -> { styles | bodyTextColor = Just "#000" }
      in
        ( { model | styles = updatedStyles
                  , narrationModified = True
          }
        , Cmd.none
        )

    UpdateBodyTextColor newColor ->
      let
        styles = model.styles
        updatedStyles = { styles | bodyTextColor = Just newColor }
      in
        ( { model | styles = updatedStyles
                  , narrationModified = True }
        , Cmd.none
        )

    ToggleCustomBodyTextBackgroundColor ->
      let
        styles = model.styles
        updatedStyles = case styles.bodyTextBackgroundColor of
                          Just _ -> { styles | bodyTextBackgroundColor = Nothing }
                          Nothing -> { styles | bodyTextBackgroundColor = Just "#e5e5e5" }
      in
        ( { model | styles = updatedStyles
                  , narrationModified = True
          }
        , Cmd.none
        )

    UpdateBodyTextBackgroundColor newColor ->
      let
        styles = model.styles
        updatedStyles = { styles | bodyTextBackgroundColor = Just newColor }
      in
        ( { model | styles = updatedStyles
                  , narrationModified = True }
        , Cmd.none
        )

    UpdateSelectedSeparatorImage newImage ->
      let
        newValue =
          case model.files of
            Just files ->
              List.head <|
                List.filter (\i -> i == newImage) files.images
            Nothing -> Nothing
        styles = model.styles
        updatedStyles = { styles | separatorImage = newValue }
      in
        ( { model | styles = updatedStyles
                  , narrationModified = True }
        , Cmd.none
        )

    OpenMediaFileSelector fileInputId ->
      ( model, openFileInput fileInputId )

    AddMediaFile mediaType mediaTarget fileInputId ->
      case model.narrationId of
        Just narrationId ->
          let
            modelWithUploadFlag =
              case mediaType of
                Audio -> { model | uploadingAudio = True }
                Image -> { model | uploadingImage = True }
                BackgroundImage -> { model | uploadingBackgroundImage = True }
                Font -> { model | uploadingFont = True }
            portType =
              case mediaTarget of
                NarrationIntroTarget -> "narrationIntroEdit"
                NarrationDefaultTarget -> "narrationDefaultEdit"
                NarrationTitleStylesTarget -> "narrationTitleStylesEdit"
                NarrationBodyTextStylesTarget -> "narrationBodyTextStylesEdit"
          in
            ( modelWithUploadFlag
            , uploadFile { type_ = mediaTypeString mediaType
                         , portType = portType
                         , fileInputId = fileInputId
                         , narrationId = narrationId
                         }
            )

        Nothing ->
          ( model, Cmd.none )

    AddMediaFileError mediaTarget error ->
      -- Bah. We don't know which type was uploaded, so we assume we
      -- can safely turn off both spinners. Sigh.
      ( { model | uploadingAudio = False
                , uploadingBackgroundImage = False
                , uploadingFont = False
        }
      , showFlashMessage <| errorBanner error.message
      )

    AddMediaFileSuccess mediaTarget resp ->
      let
        ( modelWithoutUploadFlag, command ) =
          if resp.type_ == "audio" then
            case mediaTarget of
              NarrationIntroTarget ->
                ( { model | uploadingAudio = False
                          , introAudio = Just resp.name
                  }
                , Cmd.none
                )
              NarrationDefaultTarget ->
                ( { model | uploadingAudio = False
                          , defaultAudio = Just resp.name
                  }
                , Cmd.none
                )
              _ ->
                ( model, Cmd.none )
          else if resp.type_ == "images" then
            case mediaTarget of
              NarrationBodyTextStylesTarget ->
                let
                  styles = model.styles
                  updatedStyles = { styles | separatorImage = Just resp.name }
                in
                  ( { model | uploadingImage = False
                            , styles = updatedStyles
                    }
                  , Cmd.none
                  )
              _ ->
                ( model, Cmd.none )
          else if resp.type_ == "backgroundImages" then
            case mediaTarget of
              NarrationIntroTarget ->
                ( { model | uploadingBackgroundImage = False
                          , introBackgroundImage = Just resp.name
                  }
                , Cmd.none
                )
              NarrationDefaultTarget ->
                ( { model | uploadingBackgroundImage = False
                          , defaultBackgroundImage = Just resp.name
                  }
                , Cmd.none
                )
              _ ->
                ( model, Cmd.none )
          else if resp.type_ == "fonts" then
            case mediaTarget of
              NarrationTitleStylesTarget ->
                let
                  styles = model.styles
                  updatedStyles = { styles | titleFont = Just resp.name }
                  narrationId = case model.narrationId of
                                  Just id -> id
                                  Nothing -> -1
                in
                  ( { model | uploadingFont = False
                            , styles = updatedStyles
                    }
                , updateFontFaceDefinition
                    { fontFaceName = "NARROWS title user font"
                    , fontUrl = "/static/narrations/" ++ (String.fromInt narrationId) ++ "/fonts/" ++ resp.name
                    }
                )
              NarrationBodyTextStylesTarget ->
                let
                  styles = model.styles
                  updatedStyles = { styles | bodyTextFont = Just resp.name }
                  narrationId = case model.narrationId of
                                  Just id -> id
                                  Nothing -> -1
                in
                  ( { model | uploadingFont = False
                            , styles = updatedStyles
                    }
                  , updateFontFaceDefinition
                      { fontFaceName = "NARROWS body user font"
                      , fontUrl = "/static/narrations/" ++ (String.fromInt narrationId) ++ "/fonts/" ++ resp.name
                      }
                  )
              _ ->
                ( model, Cmd.none )
          else
            ( model, Cmd.none )
        updatedFiles = case model.files of
                         Just files ->
                           Just <| updateNarrationFiles files resp
                         Nothing ->
                           Nothing
      in
        ( { modelWithoutUploadFlag | files = updatedFiles
                                   , narrationModified = True
          }
        , command
        )

    PlayPauseAudioPreview ->
      ( model, playPauseAudioPreview "audio-preview" )

    CreateNarration ->
      ( model
      , if String.isEmpty model.title then
          Cmd.none
        else
          NarrationCreationApp.Api.createNarration { title = model.title }
      )

    CreateNarrationResult (Err _) ->
      ( model
      , showFlashMessage <| errorBanner "Could not create new narration"
      )

    CreateNarrationResult (Ok narration) ->
      ( { model | banner = Nothing }
      , Nav.pushUrl model.key <| "/narrations/" ++ (String.fromInt narration.id) ++ "/edit"
      )

    SaveNarration ->
      ( model
      , if String.isEmpty model.title then
          Cmd.none
        else
          case model.narrationId of
            Just narrationId ->
              NarrationCreationApp.Api.saveNarration
                narrationId
                { title = model.title
                , intro = model.intro
                , introBackgroundImage = model.introBackgroundImage
                , introAudio = model.introAudio
                , defaultBackgroundImage = model.defaultBackgroundImage
                , defaultAudio = model.defaultAudio
                , styles = model.styles
                }
            Nothing ->
              Cmd.none
      )

    SaveNarrationResult (Err _) ->
      ( model
      , showFlashMessage <| errorBanner "Could not save narration"
      )

    SaveNarrationResult (Ok narration) ->
      ( { model | banner = Nothing
                , narrationModified = False
        }
      , showFlashMessage <| successBanner "Narration saved"
      )

    FetchNarrationResult (Err _) ->
      ( { model | banner = errorBanner "Could not create new narration" }
      , Cmd.none
      )

    FetchNarrationResult (Ok narration) ->
      ( { model | banner = Nothing
                , title = narration.title
                , intro = narration.intro
                , introBackgroundImage = narration.introBackgroundImage
                , introAudio = narration.introAudio
                , introUrl = narration.introUrl
                , defaultBackgroundImage = narration.defaultBackgroundImage
                , defaultAudio = narration.defaultAudio
                , files = Just narration.files
                , styles = narration.styles
        }
      , Cmd.batch [ initEditor
                      { elemId = "intro-editor"
                      , narrationId = narration.id
                      , narrationImages = narration.files.images
                      , chapterParticipants = []
                      , text = narration.intro
                      , editorType = "narrationIntro"
                      , updatePortName = "narrationIntroContentChanged"
                      }
                  , case narration.styles.titleFont of
                      Just font ->
                        updateFontFaceDefinition
                          { fontFaceName = "NARROWS title user font"
                          , fontUrl = "/static/narrations/" ++ (String.fromInt narration.id) ++ "/fonts/" ++ font
                          }
                      Nothing ->
                        Cmd.none
                  , case narration.styles.bodyTextFont of
                      Just font ->
                        updateFontFaceDefinition
                          { fontFaceName = "NARROWS body user font"
                          , fontUrl = "/static/narrations/" ++ (String.fromInt narration.id) ++ "/fonts/" ++ font
                          }
                      Nothing ->
                        Cmd.none
                  ]
      )

    CancelCreateNarration ->
      let
        newUrl = case model.narrationId of
                   Just narrationId -> "/narrations/" ++ (String.fromInt narrationId)
                   Nothing -> "/"
      in
        ( model
        , Nav.pushUrl model.key newUrl
        )

    SetFlashMessage maybeBanner ->
      ( { model | banner = maybeBanner }
      , Cmd.none
      )

    RemoveFlashMessage ->
      ( { model | banner = Nothing }
      , Cmd.none
      )
