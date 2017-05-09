module NovelReaderApp.Messages exposing (..)

import Http
import NovelReaderApp.Models exposing (Novel)
import NovelReaderApp.Models exposing (..)


type Msg
    = NavigateTo String
    | StartNarration
      -- The parameter is useless here, but is a subscription so it needs it
    | NarrationStarted Int
    | NovelFetchResult (Result Http.Error Novel)
    | ToggleBackgroundMusic
    | PlayPauseMusic
    | PageScroll Int
    | NextChapter
    | PreviousChapter
    | ShowReferenceInformation
    | HideReferenceInformation
