module NarrationOverviewApp.Update exposing (..)

import Http
import Navigation

import Routing
import NarrationOverviewApp.Api
import NarrationOverviewApp.Messages exposing (..)
import NarrationOverviewApp.Models exposing (..)


urlUpdate : Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate route model =
    case route of
      Routing.NarrationPage narrationId ->
        ( model
        , Cmd.batch [ NarrationOverviewApp.Api.fetchNarrationOverview narrationId
                    , NarrationOverviewApp.Api.fetchNarrationNovels narrationId
                    ]
        )
      _ ->
        (model, Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)
    NavigateTo url ->
      (model, Navigation.newUrl url)

    NarrationOverviewFetchError error ->
      case error of
        Http.UnexpectedPayload message ->
          ( { model | banner = Just { text = "Error! " ++ message
                                    , type' = "error"
                                    }
            }
          , Cmd.none
          )
        Http.BadResponse status body ->
          ( { model | banner = Just { text = "Error! Body: " ++ body
                                    , type' = "error"
                                    }
            }
          , Cmd.none
          )
        _ ->
          ( { model | banner = Just { text = "Unknown error!"
                                    , type' = "error"
                                    }
            }
          , Cmd.none
          )
    NarrationOverviewFetchSuccess narrationOverview ->
      ( { model | narrationOverview = Just narrationOverview }
      , Cmd.none
      )

    NarrationNovelsFetchError error ->
      case error of
        Http.UnexpectedPayload message ->
          ( { model | banner = Just { text = "Error! " ++ message
                                    , type' = "error"
                                    }
            }
          , Cmd.none
          )
        Http.BadResponse status body ->
          ( { model | banner = Just { text = "Error! Body: " ++ body
                                    , type' = "error"
                                    }
            }
          , Cmd.none
          )
        _ ->
          ( { model | banner = Just { text = "Unknown error!"
                                    , type' = "error"
                                    }
            }
          , Cmd.none
          )
    NarrationNovelsFetchSuccess narrationNovels ->
      ( { model | narrationNovels = Just narrationNovels.novels }
      , Cmd.none
      )
