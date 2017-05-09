module NarrationOverviewApp.Update exposing (..)

import Http
import Navigation

import Core.Routes exposing (Route(..))
import NarrationOverviewApp.Api
import NarrationOverviewApp.Messages exposing (..)
import NarrationOverviewApp.Models exposing (..)


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate route model =
    case route of
        NarrationPage narrationId ->
            ( model
            , Cmd.batch
                [ NarrationOverviewApp.Api.fetchNarrationOverview narrationId
                , NarrationOverviewApp.Api.fetchNarrationNovels narrationId
                ]
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

        NarrationOverviewFetchResult (Err error) ->
            case error of
                Http.BadPayload parserError resp ->
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

        NarrationOverviewFetchResult (Ok narrationOverview) ->
            ( { model | narrationOverview = Just narrationOverview }
            , Cmd.none
            )

        NarrationNovelsFetchResult (Err error) ->
            case error of
                Http.BadPayload parserError resp ->
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

        NarrationNovelsFetchResult (Ok narrationNovels) ->
            ( { model | narrationNovels = Just narrationNovels.novels }
            , Cmd.none
            )
