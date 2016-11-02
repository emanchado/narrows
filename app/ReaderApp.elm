module ReaderApp exposing (..)

import Routing
import ReaderApp.Messages exposing (..)
import ReaderApp.Models exposing (..)
import ReaderApp.Update
import ReaderApp.Views
import ReaderApp.Ports

initialState : Result String Routing.Route -> (Model, Cmd Msg)
initialState result =
  let
    model =
      { route = Routing.NotFoundRoute
      , state = Loader
      , chapter = Nothing
      , messageThreads = Nothing
      , backgroundMusic = True
      , musicPlaying = True
      , backgroundBlurriness = 0
      , newMessageText = ""
      , newMessageRecipients = []
      , reactionSent = False
      , reaction = ""
      , banner = Nothing
      }
  in
    ReaderApp.Update.urlUpdate result model

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch [ ReaderApp.Ports.pageScrollListener PageScroll
            , ReaderApp.Ports.markNarrationAsStarted NarrationStarted
            ]

update = ReaderApp.Update.update
urlUpdate = ReaderApp.Update.urlUpdate
view = ReaderApp.Views.mainApplicationView
