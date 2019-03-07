module Core.Models exposing (..)

import Browser.Navigation as Nav

import Core.Routes exposing (Route(..))
import Common.Models exposing (Banner, UserInfo)
import ReaderApp
import CharacterApp
import NarratorDashboardApp
import NarrationArchiveApp
import NarrationCreationApp
import NarrationOverviewApp
import ChapterEditApp
import ChapterControlApp
import CharacterCreationApp
import CharacterEditApp
import UserManagementApp
import NovelReaderApp
import ProfileApp




type UserSession
  = AnonymousSession
  | LoggedInSession UserInfo


type alias ResetPasswordResponse =
  { id : String }

type alias Model =
  { route : Route
  , key : Nav.Key
  , session : Maybe UserSession
  , banner : Maybe Banner
  , email : String
  , password : String
  , forgotPasswordUi : Bool
  , readerApp : ReaderApp.Model
  , characterApp : CharacterApp.Model
  , narratorDashboardApp : NarratorDashboardApp.Model
  , narrationArchiveApp : NarrationArchiveApp.Model
  , narrationCreationApp : NarrationCreationApp.Model
  , narrationOverviewApp : NarrationOverviewApp.Model
  , chapterEditApp : ChapterEditApp.Model
  , chapterControlApp : ChapterControlApp.Model
  , characterCreationApp : CharacterCreationApp.Model
  , characterEditApp : CharacterEditApp.Model
  , userManagementApp : UserManagementApp.Model
  , novelReaderApp : NovelReaderApp.Model
  , profileApp : ProfileApp.Model
  }
