module NarratorDashboardApp.Update exposing (..)

import Http
import Navigation
import Core.Routes exposing (Route(..))
import NarratorDashboardApp.Api
import NarratorDashboardApp.Messages exposing (..)
import NarratorDashboardApp.Models exposing (..)


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate route model =
    case route of
        NarratorIndex ->
            ( model
            , NarratorDashboardApp.Api.fetchNarratorOverview
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

        NarratorOverviewFetchResult (Err error) ->
            case error of
                Http.BadPayload parserError _ ->
                    ( { model
                        | banner =
                            Just
                                { text = "Error! " ++ parserError
                                , type_ = "error"
                                }
                      }
                    , Cmd.none
                    )

                Http.BadStatus resp ->
                    ( { model
                        | banner =
                            Just
                                { text = "Error! Body: " ++ resp.body
                                , type_ = "error"
                                }
                      }
                    , Cmd.none
                    )

                _ ->
                    ( { model
                        | banner =
                            Just
                                { text = "Unknown error!"
                                , type_ = "error"
                                }
                      }
                    , Cmd.none
                    )

        NarratorOverviewFetchResult (Ok narratorOverview) ->
            ( { model | narrations = Just narratorOverview.narrations }
            , Cmd.none
            )

        NewNarration ->
            ( model
            , Navigation.newUrl "/narrations/new"
            )
