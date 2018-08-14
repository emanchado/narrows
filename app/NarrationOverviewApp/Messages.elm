module NarrationOverviewApp.Messages exposing (..)

import Http
import Common.Models exposing (Narration, NarrationStatus, NarrationOverview)
import NarrationOverviewApp.Models exposing (SendPendingIntroEmailsResponse)


type Msg
    = NoOp
    | NavigateTo String
    | NarrationOverviewFetchResult (Result Http.Error NarrationOverview)
    | MarkNarration NarrationStatus
    | MarkNarrationResult (Result Http.Error Narration)
    | SendPendingIntroEmails
    | SendPendingIntroEmailsResult (Result Http.Error SendPendingIntroEmailsResponse)
