module NarrationCreationApp.Update exposing (..)

import Navigation
import Core.Routes exposing (Route(..))
import NarrationCreationApp.Api
import NarrationCreationApp.Messages exposing (..)
import Common.Models exposing (errorBanner)
import NarrationCreationApp.Models exposing (..)


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate route model =
    case route of
        NarrationCreationPage ->
            ( { model | title = "" }
            , Cmd.none
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

        CreateNarration ->
            ( model
            , NarrationCreationApp.Api.createNarration
                { title = model.title
                }
            )

        CreateNarrationResult (Err _) ->
            ( { model | banner = errorBanner "Could not create new narration" }
            , Cmd.none
            )

        CreateNarrationResult (Ok narration) ->
            ( { model | banner = Nothing }
            , Navigation.newUrl <| "/narrations/" ++ (toString narration.id)
            )

        CancelCreateNarration ->
            ( model
            , Navigation.newUrl "/"
            )
