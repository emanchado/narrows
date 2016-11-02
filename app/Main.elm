import Navigation

import Routing
import ReaderApp

main : Program Never
main =
  Navigation.program Routing.parser
    { init = ReaderApp.initialState
    , view = ReaderApp.view
    , update = ReaderApp.update
    , urlUpdate = ReaderApp.urlUpdate
    , subscriptions = ReaderApp.subscriptions
    }
