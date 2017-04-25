module Core.Messages exposing (..)

import Http

import Core.Models
import Routing
import ReaderApp
import CharacterApp
import NarratorDashboardApp
import NarrationCreationApp
import NarrationOverviewApp
import ChapterEditApp
import ChapterControlApp
import CharacterCreationApp

type Msg
  = NoOp
  | SessionFetchSuccess Core.Models.UserSessionInfo
  | SessionFetchError Http.Error
  | UpdateEmail String
  | UpdatePassword String
  | Login
  | LoginSuccess Http.Response
  | LoginError Http.RawError
  | ReaderMsg ReaderApp.Msg
  | CharacterMsg CharacterApp.Msg
  | NarratorDashboardMsg NarratorDashboardApp.Msg
  | NarrationCreationMsg NarrationCreationApp.Msg
  | NarrationOverviewMsg NarrationOverviewApp.Msg
  | ChapterEditMsg ChapterEditApp.Msg
  | ChapterControlMsg ChapterControlApp.Msg
  | CharacterCreationMsg CharacterCreationApp.Msg
