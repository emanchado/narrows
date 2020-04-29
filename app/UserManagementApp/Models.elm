module UserManagementApp.Models exposing (..)

import Browser.Navigation as Nav
import Common.Models exposing (Banner, UserInfo)


type alias UserChanges =
    { userId : Int
    , displayName : String
    , password : String
    , isAdmin : Bool
    }


type alias UserListResponse =
    { users : List UserInfo
    }


type alias Model =
    { key : Nav.Key
    , banner : Maybe Banner
    , users : Maybe (List UserInfo)
    , userUi : Maybe UserChanges
    , newUserEmail : String
    , newUserDisplayName : String
    , newUserIsAdmin : Bool
    }
