module CharacterApp.Update exposing (..)

import Http

import Routing

import Common.Ports exposing (initEditor)

import CharacterApp.Api
import CharacterApp.Messages exposing (..)
import CharacterApp.Models exposing (..)


urlUpdate : Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate route model =
  case route of
    Routing.CharacterPage characterToken ->
      ( { model | characterToken = characterToken }
      , CharacterApp.Api.fetchCharacterInfo characterToken
      )
    _ ->
      (model, Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)
    CharacterFetchError error ->
      let
        errorString = case error of
                        Http.UnexpectedPayload payload ->
                          "Bad payload: " ++ payload
                        Http.BadResponse status body ->
                          "Got status " ++ (toString status) ++ " with body " ++ body
                        _ ->
                          "Network stuff"
      in
        ( { model | banner = (Just { text = "Error fetching character: " ++ errorString
                                   , type' = "error"
                                   }) }
        , Cmd.none
        )
    CharacterFetchSuccess character ->
      ( { model | characterInfo = Just character }
      , Cmd.batch [ initEditor { elemId = "description-editor"
                               , narrationId = 0
                               , narrationImages = []
                               , chapterParticipants = []
                               , text = character.description
                               }
                  , initEditor { elemId = "backstory-editor"
                               , narrationId = 0
                               , narrationImages = []
                               , chapterParticipants = []
                               , text = character.backstory
                               }
                  ]
      )
