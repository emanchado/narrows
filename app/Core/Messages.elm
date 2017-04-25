module Core.Messages exposing (..)

import Http

import Core.Models
import ReaderApp
import CharacterApp
import NarratorDashboardApp
import NarrationCreationApp
import NarrationOverviewApp
import ChapterEditApp
import ChapterControlApp
import CharacterCreationApp
import UserManagementApp

type Msg
  = NoOp
  | SessionFetchSuccess Core.Models.UserInfo
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
  | UserManagementMsg UserManagementApp.Msg
