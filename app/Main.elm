import Navigation

import Routing
import Messages exposing (..)
import Models exposing (..)
import Update
import Views
import Ports

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
      , characterId = Nothing
      , characterToken = ""
      , newMessageText = ""
      , newMessageRecipients = []
      , reactionSent = False
      , reaction = ""
      , banner = Nothing
      }
  in
    Update.urlUpdate result model

main : Program Never
main =
  Navigation.program Routing.parser
    { init = initialState
    , view = Views.mainApplicationView
    , update = Update.update
    , urlUpdate = Update.urlUpdate
    , subscriptions = subscriptions
    }

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch [ Ports.pageScrollListener PageScroll
            , Ports.markNarrationAsStarted NarrationStarted
            ]
