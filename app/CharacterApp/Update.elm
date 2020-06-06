module CharacterApp.Update exposing (..)

import Http
import Browser.Navigation as Nav

import Core.Routes exposing (Route(..))
import Common.Models exposing (errorBanner, successBanner)
import Common.Ports exposing (initEditor, readAvatarAsUrl, uploadAvatar, renderText)
import CharacterApp.Api
import CharacterApp.Messages exposing (..)
import CharacterApp.Models exposing (..)


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate route model =
    case route of
        CharacterPage characterToken ->
            ( { model | characterToken = characterToken }
            , CharacterApp.Api.fetchCharacterInfo characterToken
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
              "Bad payload: " ++ parserError

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
      , Cmd.batch <|
          List.append
            [ initEditor { elemId = "description-editor"
                         , narrationId = 0
                         , narrationImages = []
                         , chapterParticipants = []
                         , text = character.description
                         , editorType = "description"
                         , updatePortName = "descriptionContentChanged"
                         }
            , initEditor { elemId = "backstory-editor"
                         , narrationId = 0
                         , narrationImages = []
                         , chapterParticipants = []
                         , text = character.backstory
                         , editorType = "description"
                         , updatePortName = "backstoryContentChanged"
                         }
            ]
            (List.map
               (\narrationCharacter ->
                  renderText
                    { elemId = "description-character-" ++ (String.fromInt narrationCharacter.id)
                    , text = narrationCharacter.description
                    , proseMirrorType = "description"
                    })
               character.narration.characters)
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
      , readAvatarAsUrl { type_ = "user"
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

    SaveCharacter ->
      case model.characterInfo of
        Just character ->
          ( model
          , CharacterApp.Api.saveCharacter model.characterToken character
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
            uploadAvatar { type_ = "user"
                         , fileInputId = "new-avatar"
                         , characterToken = model.characterToken
                         }
          Nothing ->
            Cmd.none
      )

    ToggleNovelTip ->
      ( { model | showNovelTip = not model.showNovelTip }
      , Cmd.none
      )

    AbandonCharacter ->
      ( { model | showAbandonCharacterDialog = True }
      , Cmd.none
      )

    ConfirmAbandonCharacter ->
      ( model
      , CharacterApp.Api.abandonCharacter model.characterToken
      )

    CancelAbandonCharacter ->
      ( { model | showAbandonCharacterDialog = False }
      , Cmd.none
      )

    AbandonCharacterResult (Err error) ->
      ( { model | banner = errorBanner "Error abandoning character"
                , showAbandonCharacterDialog = False
        }
      , Cmd.none
      )

    AbandonCharacterResult (Ok resp) ->
      ( model
      , Nav.pushUrl model.key "/"
      )
