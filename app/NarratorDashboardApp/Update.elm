module NarratorDashboardApp.Update exposing (..)

import Http
import Navigation

import Routing
import NarratorDashboardApp.Api
import NarratorDashboardApp.Messages exposing (..)
import NarratorDashboardApp.Models exposing (..)


urlUpdate : Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate route model =
    case route of
      Routing.NarratorIndex ->
        ( model
        , NarratorDashboardApp.Api.fetchNarratorOverview
        )
      _ ->
        (model, Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)

    NarratorOverviewFetchError error ->
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
    NarratorOverviewFetchSuccess narratorOverview ->
      ( { model | narrations = Just narratorOverview.narrations }
      , Cmd.none
      )

    NewNarration ->
      ( model
      , Navigation.newUrl "/narrations/new"
      )
