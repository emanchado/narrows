module NovelReaderApp.Messages exposing (..)

import Http
import Common.Models exposing (DeviceSettings)
import NovelReaderApp.Models exposing (Novel)


type Msg
    = NavigateTo String
    | ReceiveDeviceSettings DeviceSettings
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
