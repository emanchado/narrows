module Core.Models exposing (..)

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
import UserManagementApp
import NovelReaderApp
import ProfileApp




type UserSession
    = AnonymousSession
    | LoggedInSession UserInfo


type alias Model =
    { route : Route
    , session : Maybe UserSession
    , banner : Maybe Banner
    , email : String
    , password : String
    , readerApp : ReaderApp.Model
    , characterApp : CharacterApp.Model
    , narratorDashboardApp : NarratorDashboardApp.Model
    , narrationArchiveApp : NarrationArchiveApp.Model
    , narrationCreationApp : NarrationCreationApp.Model
    , narrationOverviewApp : NarrationOverviewApp.Model
    , chapterEditApp : ChapterEditApp.Model
    , chapterControlApp : ChapterControlApp.Model
    , characterCreationApp : CharacterCreationApp.Model
    , userManagementApp : UserManagementApp.Model
    , novelReaderApp : NovelReaderApp.Model
    , profileApp : ProfileApp.Model
    }
