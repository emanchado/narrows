module NarrationIntroApp.Messages exposing (..)

import Http
import Common.Models exposing (UserInfo)
import NarrationIntroApp.Models exposing (NarrationIntroResponse)


type Msg
    = NoOp
    | SessionFetchResult (Result Http.Error UserInfo)
    | NarrationIntroFetchResult (Result Http.Error NarrationIntroResponse)
    | ToggleBackgroundMusic
    | StartNarration
    | NarrationStarted Int
    | PlayPauseMusic
    | PageScroll Int
    | UpdateEmail String
    | ClaimCharacter Int String
    | ClaimCharacterFetchResult (Result Http.Error ())
