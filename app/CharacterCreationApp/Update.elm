module CharacterCreationApp.Update exposing (..)

import Http
import Navigation

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
            ( model, Navigation.newUrl url )

        FetchNarrationResult (Err error) ->
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
            , Navigation.newUrl <| "/characters/" ++ (toString character.id) ++ "/edit"
            )

        CancelCreateCharacter ->
            ( model
            , Navigation.newUrl <| "/narrations/" ++ (toString model.narrationId)
            )
