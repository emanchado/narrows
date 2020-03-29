module NarrationOverviewApp.Messages exposing (..)

import Http
import Common.Models exposing (Narration, NarrationStatus, NarrationOverview)


type Msg
    = NoOp
    | NavigateTo String
    | NarrationOverviewFetchResult (Result Http.Error NarrationOverview)
    | MarkNarration NarrationStatus
    | MarkNarrationResult (Result Http.Error Narration)
    | ToggleURLInfoBox
    | RemoveNarration
    | ConfirmRemoveNarration
    | CancelRemoveNarration
    | RemoveNarrationResult (Result Http.Error ())
