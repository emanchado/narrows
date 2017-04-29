module NarrationOverviewApp.Update exposing (..)

import Http

import Routing
import NarrationOverviewApp.Api
import NarrationOverviewApp.Messages exposing (..)
import NarrationOverviewApp.Models exposing (..)


urlUpdate : Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate route model =
    case route of
      Routing.NarrationPage narrationId ->
        ( model
        , NarrationOverviewApp.Api.fetchNarrationOverview narrationId
        )
      _ ->
        (model, Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)

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
