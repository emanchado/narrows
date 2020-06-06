module CharacterEditApp.Update exposing (..)

import Http
import Browser
import Browser.Navigation as Nav
import Url

import Core.Routes exposing (Route(..))
import Common.Models exposing (errorBanner, successBanner)
import Common.Ports exposing (initEditor, readAvatarAsUrl, uploadAvatar)
import CharacterEditApp.Api
import CharacterEditApp.Messages exposing (..)
import CharacterEditApp.Models exposing (..)


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate route model =
    case route of
        CharacterEditPage characterId ->
            ( { model | characterId = characterId
                      , banner = Nothing
              }
            , CharacterEditApp.Api.fetchCharacterInfo characterId
            )

        _ ->
            ( model, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    NoOp ->
      ( model, Cmd.none )

    NavigateTo url ->
      ( model, Nav.pushUrl model.key url )

    CharacterFetchResult (Err error) ->
      let
        errorString =
          case error of
            Http.BadBody parserError ->
              "Bad body: " ++ parserError

            Http.BadStatus status ->
              "Got status " ++ (String.fromInt status)

            _ ->
              "Cannot connect to server"
      in
        ( { model | banner = errorBanner <| "Error fetching character: " ++ errorString }
        , Cmd.none
        )

    CharacterFetchResult (Ok character) ->
      ( { model | characterInfo = Just character }
      , Cmd.batch
          [ initEditor { elemId = "description-editor"
                       , narrationId = 0
                       , narrationImages = []
                       , chapterParticipants = []
                       , text = character.description
                       , editorType = "description"
                       , updatePortName = "narratorDescriptionContentChanged"
                       }
          , initEditor { elemId = "backstory-editor"
                       , narrationId = 0
                       , narrationImages = []
                       , chapterParticipants = []
                       , text = character.backstory
                       , editorType = "description"
                       , updatePortName = "narratorBackstoryContentChanged"
                       }
          ]
      )

    UpdateDescriptionText newDescription ->
      case model.characterInfo of
        Just character ->
          let
            updatedCharacter =
              { character | description = newDescription }
          in
            ( { model | characterInfo = Just updatedCharacter
                      , characterModified = True
                      , banner = Nothing
              }
            , Cmd.none
            )

        Nothing ->
          ( model, Cmd.none )

    UpdateBackstoryText newBackstory ->
      case model.characterInfo of
        Just character ->
          let
            updatedCharacter =
              { character | backstory = newBackstory }
          in
            ( { model | characterInfo = Just updatedCharacter
                      , characterModified = True
                      , banner = Nothing
              }
            , Cmd.none
            )

        Nothing ->
          ( model, Cmd.none )

    UpdateCharacterName newName ->
      case model.characterInfo of
        Just character ->
          let
            updatedCharacter = { character | name = newName }
          in
            ( { model | characterInfo = Just updatedCharacter
                      , characterModified = True
                      , banner = Nothing
              }
            , Cmd.none
            )
        Nothing ->
          ( model, Cmd.none )

    UpdateCharacterAvatar elementId ->
      ( { model | characterModified = True }
      , readAvatarAsUrl { type_ = "narrator"
                        , fileInputId = elementId
                        }
      )

    ReceiveAvatarAsUrl dataUrl ->
      ( { model | newAvatarUrl = Just dataUrl
                , banner = Nothing
        }
      , Cmd.none
      )

    UploadAvatarError err ->
      let
        banner = errorBanner <| (String.fromInt err.status) ++ " - " ++ err.message
      in
        ( { model | banner = banner }
        , Cmd.none
        )
    UploadAvatarSuccess newAvatarUrl ->
      let
        updatedCharacter =
          case model.characterInfo of
            Just character -> Just { character | avatar = Just newAvatarUrl }
            Nothing -> Nothing
      in
        ( { model | characterInfo = updatedCharacter }
        , Cmd.none
        )

    ToggleUnclaimInfoBox ->
      ( { model | showUnclaimInfoBox = not model.showUnclaimInfoBox }
      , Cmd.none
      )

    ToggleTokenInfoBox ->
      ( { model | showTokenInfoBox = not model.showTokenInfoBox }
      , Cmd.none
      )

    ToggleNovelTokenInfoBox ->
      ( { model | showNovelTokenInfoBox = not model.showNovelTokenInfoBox }
      , Cmd.none
      )

    UnclaimCharacter ->
      ( { model | showUnclaimCharacterDialog = True }
      , Cmd.none
      )

    ConfirmUnclaimCharacter ->
      case model.characterInfo of
        Just character ->
          ( { model | showUnclaimCharacterDialog = False }
          , CharacterEditApp.Api.unclaimCharacter character.id
          )

        Nothing ->
          ( { model | showUnclaimCharacterDialog = False }, Cmd.none )

    CancelUnclaimCharacter ->
      ( { model | showUnclaimCharacterDialog = False }
      , Cmd.none
      )

    UnclaimCharacterResult (Err error) ->
      ( { model | banner = errorBanner "Error unclaiming character" }
      , Cmd.none
      )

    UnclaimCharacterResult (Ok character) ->
      ( { model | characterInfo = Just character
                , banner = Nothing
        }
      , Cmd.none
      )

    ResetCharacterToken ->
      ( { model | showResetCharacterTokenDialog = True }
      , Cmd.none
      )

    ConfirmResetCharacterToken ->
      case model.characterInfo of
        Just character ->
          ( { model | showResetCharacterTokenDialog = False }
          , CharacterEditApp.Api.resetCharacterToken character.id
          )

        Nothing ->
          ( { model | showResetCharacterTokenDialog = False }, Cmd.none )

    CancelResetCharacterToken ->
      ( { model | showResetCharacterTokenDialog = False }
      , Cmd.none
      )

    ResetCharacterTokenResult (Err error) ->
      ( { model | banner = errorBanner "Error reset character token" }
      , Cmd.none
      )

    ResetCharacterTokenResult (Ok newTokenResponse) ->
      case model.characterInfo of
        Just character ->
          let
            updatedCharacter = { character | token = newTokenResponse.token }
          in
            ( { model | characterInfo = Just updatedCharacter
                      , banner = Nothing
              }
            , Cmd.none
            )

        Nothing ->
          ( model, Cmd.none )

    SaveCharacter ->
      case model.characterInfo of
        Just character ->
          ( model
          , CharacterEditApp.Api.saveCharacter character.id character
          )

        Nothing ->
          ( model, Cmd.none )

    SaveCharacterResult (Err error) ->
      ( { model | banner = errorBanner "Error saving character" }
      , Cmd.none
      )

    SaveCharacterResult (Ok resp) ->
      ( { model | banner = successBanner <| "Saved"
                , newAvatarUrl = Nothing
                , characterModified = False
        }
      , case model.newAvatarUrl of
          Just avatar ->
            case model.characterInfo of
              Just info ->
                uploadAvatar { type_ = "narrator"
                             , fileInputId = "new-avatar"
                             , characterToken = info.token
                             }
              Nothing ->
                Cmd.none
          Nothing ->
            Cmd.none
      )

    RemoveCharacter ->
      ( { model | showRemoveCharacterDialog = True
                , banner = Nothing
        }
      , Cmd.none
      )

    ConfirmRemoveCharacter ->
      case model.characterInfo of
        Just character ->
          ( { model | showRemoveCharacterDialog = False }
          , CharacterEditApp.Api.removeCharacter character.id
          )

        Nothing ->
          ( model, Cmd.none )

    CancelRemoveCharacter ->
      ( { model | showRemoveCharacterDialog = False }
      , Cmd.none
      )

    RemoveCharacterResult (Err error) ->
      ( { model | banner = errorBanner "Error deleting character" }
      , Cmd.none
      )

    RemoveCharacterResult (Ok resp) ->
      ( model
      , case model.characterInfo of
          Just info ->
            Nav.pushUrl model.key <| "/narrations/" ++ (String.fromInt info.narration.id)
          Nothing ->
            Cmd.none
      )
