module UserManagementApp.Models exposing (..)

import Common.Models exposing (Banner, UserInfo)

type alias UserChanges =
  { userId : Int
  , password : String
  , isAdmin : Bool
  }

type alias UserListResponse =
  { users : List UserInfo
  }

type alias Model =
  { banner : Maybe Banner
  , users : Maybe (List UserInfo)
  , userUi : Maybe UserChanges
  , newUserEmail : String
  , newUserIsAdmin : Bool
  }
