module CharacterCreationApp.Update exposing (..)

import Navigation

import Routing
import CharacterCreationApp.Api
import CharacterCreationApp.Messages exposing (..)
import Common.Models exposing (errorBanner)
import CharacterCreationApp.Models exposing (..)


urlUpdate : Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate route model =
    case route of
      Routing.CharacterCreationPage narrationId ->
        ( { model | banner = Nothing
                  , narrationId = narrationId
                  , playerEmail = ""
                  , characterName = ""
          }
        , Cmd.none
        )
      _ ->
        (model, Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)

    UpdateName newName ->
      ({ model | characterName = newName }, Cmd.none)
    UpdateEmail newEmail ->
      ({ model | playerEmail = newEmail }, Cmd.none)

    CreateCharacter ->
      ( model
      , CharacterCreationApp.Api.createCharacter
          model.narrationId
          model.characterName
          model.playerEmail
      )

    CreateCharacterError error ->
      ( { model | banner = errorBanner "Error saving character" }
      , Cmd.none
      )

    CreateCharacterSuccess resp ->
      if (resp.status >= 200) && (resp.status < 300) then
        ( model
        , Navigation.newUrl <| "/narrations/" ++ (toString model.narrationId)
        )
      else
        ( { model | banner = errorBanner <| "Error saving character, status code " ++ (toString resp.status) }
        , Cmd.none
        )

    CancelCreateCharacter ->
      ( model
      , Navigation.newUrl <| "/narrations/" ++ (toString model.narrationId)
      )
