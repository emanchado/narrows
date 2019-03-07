module CharacterCreationApp.Update exposing (..)

import Http
import Browser.Navigation as Nav

import Core.Routes exposing (Route(..))
import CharacterCreationApp.Api
import CharacterCreationApp.Messages exposing (..)
import Common.Models exposing (errorBanner)
import CharacterCreationApp.Models exposing (..)


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate route model =
    case route of
        CharacterCreationPage narrationId ->
            ( { model | banner = Nothing
                      , narrationId = narrationId
                      , playerEmail = ""
                      , characterName = ""
              }
            , CharacterCreationApp.Api.fetchNarration narrationId
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

        FetchNarrationResult (Err error) ->
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
              ( { model | banner = Just { type_ = "error", text = errorString } }
              , Cmd.none
              )

        FetchNarrationResult (Ok narration) ->
            ( { model | narration = Just narration }, Cmd.none )

        UpdateName newName ->
            ( { model | characterName = newName }, Cmd.none )

        UpdateEmail newEmail ->
            ( { model | playerEmail = newEmail }, Cmd.none )

        CreateCharacter ->
            ( model
            , CharacterCreationApp.Api.createCharacter
                model.narrationId
                model.characterName
                model.playerEmail
            )

        CreateCharacterResult (Err error) ->
            ( { model | banner = errorBanner "Error saving character" }
            , Cmd.none
            )

        CreateCharacterResult (Ok character) ->
            ( model
            , Nav.pushUrl model.key <| "/characters/" ++ (String.fromInt character.id) ++ "/edit"
            )

        CancelCreateCharacter ->
            ( model
            , Nav.pushUrl model.key <| "/narrations/" ++ (String.fromInt model.narrationId)
            )
