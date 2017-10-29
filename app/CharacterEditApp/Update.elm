module CharacterEditApp.Update exposing (..)

import Http
import Navigation
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
            ( { model | characterId = characterId }
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
      ( model, Navigation.newUrl url )

    CharacterFetchResult (Err error) ->
      let
        errorString =
          case error of
            Http.BadPayload parserError _ ->
              "Bad payload: " ++ parserError

            Http.BadStatus resp ->
              "Got status " ++ (toString resp.status) ++ " with body " ++ resp.body

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
                      , banner = Nothing
              }
            , Cmd.none
            )
        Nothing ->
          ( model, Cmd.none )

    UpdateCharacterAvatar elementId ->
      ( model
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
        banner = errorBanner <| (toString err.status) ++ " - " ++ err.message
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

    UpdatePlayerEmail newEmail ->
      let
        updatedCharacter =
          case model.characterInfo of
            Just character -> Just { character | email = newEmail }
            Nothing -> Nothing
      in
        ( { model | characterInfo = updatedCharacter }
        , Cmd.none
        )

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
