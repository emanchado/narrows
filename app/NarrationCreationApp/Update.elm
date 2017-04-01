module NarrationCreationApp.Update exposing (..)

import Json.Decode as Json exposing (..)
import Http
import Navigation

import Routing
import NarrationCreationApp.Api
import NarrationCreationApp.Api.Json
import NarrationCreationApp.Messages exposing (..)
import Common.Models exposing (errorBanner)
import NarrationCreationApp.Models exposing (..)


urlUpdate : Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate route model =
    case route of
      Routing.NarrationCreationPage ->
        ( { model | title = "" }
        , Cmd.none
        )
      _ ->
        (model, Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)

    UpdateTitle newTitle ->
      ( { model | title = newTitle }
      , Cmd.none
      )

    CreateNarration ->
      ( model
      , NarrationCreationApp.Api.createNarration { title = model.title
                                                 }
      )
    CreateNarrationError error ->
      ( { model | banner = errorBanner "Could not create new narration" }
      , Cmd.none
      )
    CreateNarrationSuccess resp ->
      if (resp.status >= 200) && (resp.status < 300) then
        case resp.value of
          Http.Text text ->
            let
              narrationDecoding =
                Json.decodeString NarrationCreationApp.Api.Json.parseNarrationResponse text
            in
              case narrationDecoding of
                Ok narration ->
                  ( { model | banner = Nothing }
                  , Navigation.newUrl <| "/narrations/" ++ (toString narration.id)
                  )
                _ ->
                  ( { model | banner = errorBanner "Error parsing chapter saving result" }
                  , Cmd.none
                  )
          _ ->
            ( { model | banner = errorBanner <| "Error creating narration, status code " ++ (toString resp.status) }
            , Cmd.none
            )
      else
        ( { model | banner = errorBanner <| "Error creating narration, status code " ++ (toString resp.status) }
        , Cmd.none
        )

    CancelCreateNarration ->
      ( model
      , Navigation.newUrl "/"
      )
