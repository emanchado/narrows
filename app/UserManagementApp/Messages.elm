module UserManagementApp.Messages exposing (..)

import Http

import UserManagementApp.Models exposing (UserListResponse)

type Msg
  = NoOp
  | UsersFetchError Http.Error
  | UsersFetchSuccess UserListResponse
  | SelectUser Int
  | UnselectUser
  | UpdatePassword String
  | UpdateIsAdmin Bool
  | SaveUser
  | SaveUserError Http.RawError
  | SaveUserSuccess Http.Response
  | UpdateNewUserEmail String
  | UpdateNewUserIsAdmin Bool
  | SaveNewUser
  | SaveNewUserError Http.RawError
  | SaveNewUserSuccess Http.Response
