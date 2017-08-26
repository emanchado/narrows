module NarrationCreationApp.Update exposing (..)

import Navigation
import Core.Routes exposing (Route(..))
import Common.Models exposing (errorBanner, updateNarrationFiles, mediaTypeString, MediaType(..))
import Common.Ports exposing (openFileInput, uploadFile)
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
        }
      , Cmd.none
      )

    NarrationEditPage narrationId ->
      ( { model | title = ""
                , narrationId = Just narrationId
                , files = Nothing
                , uploadingAudio = False
                , uploadingBackgroundImage = False
        }
      , NarrationCreationApp.Api.fetchNarration narrationId
      )

    _ ->
      ( model, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    NoOp ->
      ( model, Cmd.none )

    UpdateTitle newTitle ->
      ( { model | title = newTitle }
      , Cmd.none
      )

    UpdateSelectedBackgroundImage newBgImage ->
      let
        newValue =
          case model.files of
            Just files ->
              List.head <|
                List.filter (\i -> i == newBgImage) files.backgroundImages
            Nothing -> Nothing
      in
        ( { model | defaultBackgroundImage = newValue
                  , banner = Nothing
          }
        , Cmd.none
        )

    UpdateSelectedAudio newAudio ->
      let
        newValue =
          case model.files of
            Just files ->
              List.head <|
                List.filter (\i -> i == newAudio) files.audio
            Nothing -> Nothing
      in
        ( { model | defaultAudio = newValue
                  , banner = Nothing
          }
        , Cmd.none
        )

    OpenMediaFileSelector fileInputId ->
      ( model, openFileInput fileInputId )

    AddMediaFile mediaType fileInputId ->
      case model.narrationId of
        Just narrationId ->
          let
            modelWithUploadFlag =
              case mediaType of
                Audio -> { model | uploadingAudio = True }
                BackgroundImage -> { model | uploadingBackgroundImage = True }
          in
            ( modelWithUploadFlag
            , uploadFile { type_ = mediaTypeString mediaType
                         , portType = "narrationEdit"
                         , fileInputId = fileInputId
                         , narrationId = narrationId
                         }
            )

        Nothing ->
          ( model, Cmd.none )

    AddMediaFileError error ->
      -- Bah. We don't know which type was uploaded, so we assume we
      -- can safely turn off both spinners. Sigh.
      ( { model | banner = errorBanner error.message
                , uploadingAudio = False
                , uploadingBackgroundImage = False
        }
      , Cmd.none
      )

    AddMediaFileSuccess resp ->
      let
        modelWithoutUploadFlag =
          if resp.type_ == "audio" then
            { model | uploadingAudio = False
                    , defaultAudio = Just resp.name
            }
          else
            { model | uploadingBackgroundImage = False
                    , defaultBackgroundImage = Just resp.name
            }
        updatedFiles = case model.files of
                         Just files ->
                           Just <| updateNarrationFiles files resp
                         Nothing ->
                           Nothing
      in
        ( { modelWithoutUploadFlag | files = updatedFiles }
        , Cmd.none
        )

    CreateNarration ->
      ( model
      , if String.isEmpty model.title then
          Cmd.none
        else
          NarrationCreationApp.Api.createNarration { title = model.title }
      )

    CreateNarrationResult (Err _) ->
      ( { model | banner = errorBanner "Could not create new narration" }
      , Cmd.none
      )

    CreateNarrationResult (Ok narration) ->
      ( { model | banner = Nothing }
      , Navigation.newUrl <| "/narrations/" ++ (toString narration.id)
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
                , defaultBackgroundImage = model.defaultBackgroundImage
                , defaultAudio = model.defaultAudio
                }
            Nothing ->
              Cmd.none
      )

    SaveNarrationResult (Err _) ->
      ( { model | banner = errorBanner "Could not save narration" }
      , Cmd.none
      )

    SaveNarrationResult (Ok narration) ->
      ( { model | banner = Nothing }
      , Navigation.newUrl <| "/narrations/" ++ (toString narration.id)
      )

    FetchNarrationResult (Err _) ->
      ( { model | banner = errorBanner "Could not create new narration" }
      , Cmd.none
      )

    FetchNarrationResult (Ok narration) ->
      ( { model | banner = Nothing
                , title = narration.title
                , defaultBackgroundImage = narration.defaultBackgroundImage
                , defaultAudio = narration.defaultAudio
                , files = Just narration.files
        }
      , Cmd.none
      )

    CancelCreateNarration ->
      let
        newUrl = case model.narrationId of
                   Just narrationId -> "/narrations/" ++ (toString narrationId)
                   Nothing -> "/"
      in
        ( model
        , Navigation.newUrl newUrl
        )
