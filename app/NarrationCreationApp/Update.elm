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

    OpenMediaFileSelector fileInputId ->
      ( model, openFileInput fileInputId )

    AddMediaFile mediaType mediaTarget fileInputId ->
      case model.narrationId of
        Just narrationId ->
          let
            modelWithUploadFlag =
              case mediaType of
                Audio -> { model | uploadingAudio = True }
                BackgroundImage -> { model | uploadingBackgroundImage = True }
            portType =
              case mediaTarget of
                NarrationIntroTarget -> "narrationIntroEdit"
                NarrationDefaultTarget -> "narrationDefaultEdit"
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
        }
      , showFlashMessage <| errorBanner error.message
      )

    AddMediaFileSuccess mediaTarget resp ->
      let
        modelWithoutUploadFlag =
          if resp.type_ == "audio" then
            case mediaTarget of
              NarrationIntroTarget ->
                { model | uploadingAudio = False
                        , introAudio = Just resp.name
                }
              NarrationDefaultTarget ->
                { model | uploadingAudio = False
                        , defaultAudio = Just resp.name
                }
          else
            case mediaTarget of
              NarrationIntroTarget ->
                { model | uploadingBackgroundImage = False
                        , introBackgroundImage = Just resp.name
                }
              NarrationDefaultTarget ->
                { model | uploadingBackgroundImage = False
                        , defaultBackgroundImage = Just resp.name
                }
        updatedFiles = case model.files of
                         Just files ->
                           Just <| updateNarrationFiles files resp
                         Nothing ->
                           Nothing
      in
        ( { modelWithoutUploadFlag | files = updatedFiles
                                   , narrationModified = True
          }
        , Cmd.none
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
        }
      , initEditor
          { elemId = "intro-editor"
          , narrationId = narration.id
          , narrationImages = narration.files.images
          , chapterParticipants = []
          , text = narration.intro
          , editorType = "narrationIntro"
          , updatePortName = "narrationIntroContentChanged"
          }
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
