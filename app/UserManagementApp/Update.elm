module UserManagementApp.Update exposing (..)

-- import Navigation
import Http
import Json.Decode

import Routing
import UserManagementApp.Api
import UserManagementApp.Messages exposing (..)
import Common.Models exposing (errorBanner)
import UserManagementApp.Models exposing (..)
import UserManagementApp.Api


urlUpdate : Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate route model =
    case route of
      Routing.UserManagementPage ->
        ( { model | banner = Nothing
                  , users = Nothing
          }
        , UserManagementApp.Api.fetchUsers
        )
      _ ->
        (model, Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)

    UsersFetchError error ->
      ( { model | banner = errorBanner "Error fetching users" }
      , Cmd.none
      )

    UsersFetchSuccess resp ->
      ( { model | users = Just resp.users }
      , Cmd.none
      )

    SelectUser userId ->
      case model.users of
        Just users ->
          let
            selectedUser =
              List.head <| List.filter (\u -> u.id == userId) users
            isUserAdmin = case selectedUser of
                            Just user -> user.role == "admin"
                            Nothing -> False
          in
            ( { model | userUi = Just { userId = userId
                                      , password = ""
                                      , isAdmin = isUserAdmin
                                      }
              , banner = Nothing
              }
            , Cmd.none
            )
        Nothing ->
          (model, Cmd.none)

    UnselectUser ->
      ( { model | userUi = Nothing
                , banner = Nothing
        }
      , Cmd.none
      )

    UpdatePassword newPassword ->
      let
        updatedUserUi = case model.userUi of
                          Just userUi ->
                            Just { userUi | password = newPassword }
                          Nothing ->
                            Nothing
      in
        ( { model | userUi = updatedUserUi
                  , banner = Nothing
          }
        , Cmd.none
        )
    UpdateIsAdmin isAdmin ->
      let
        updatedUserUi = case model.userUi of
                          Just userUi ->
                            Just { userUi | isAdmin = isAdmin }
                          Nothing ->
                            Nothing
      in
        ( { model | userUi = updatedUserUi
                  , banner = Nothing
          }
        , Cmd.none
        )

    SaveUser ->
      case model.userUi of
        Just userUi ->
          (model, UserManagementApp.Api.saveUser userUi)
        Nothing ->
          (model, Cmd.none)

    SaveUserError err ->
      ( { model | banner = errorBanner "Error updating user" }
      , Cmd.none
      )
    SaveUserSuccess resp ->
      if (resp.status >= 200) && (resp.status < 300) then
        ( { model | userUi = Nothing }
        , UserManagementApp.Api.fetchUsers
        )
      else
        ( { model | banner = errorBanner "Error updating user" }
        , Cmd.none
        )

    UpdateNewUserEmail newEmail ->
      ({ model | newUserEmail = newEmail, banner = Nothing }, Cmd.none)
    UpdateNewUserIsAdmin newIsAdmin ->
      ({ model | newUserIsAdmin = newIsAdmin, banner = Nothing }, Cmd.none)
    SaveNewUser ->
      ( model
      , UserManagementApp.Api.saveNewUser model.newUserEmail model.newUserIsAdmin
      )
    SaveNewUserError err ->
      ( { model | banner = errorBanner "Error creating user" }
      , Cmd.none
      )
    SaveNewUserSuccess resp ->
      if (resp.status >= 200) && (resp.status < 300) then
        case resp.value of
          Http.Text text ->
            let
              userDecoding =
                Json.Decode.decodeString UserManagementApp.Api.parseUser text
            in
              case userDecoding of
                Ok user ->
                  let
                    updatedUsers = case model.users of
                                     Just users ->
                                       Just (List.append users [user])
                                     Nothing ->
                                       Just [user]
                  in
                    ( { model | users = updatedUsers
                              , newUserEmail = ""
                              , newUserIsAdmin = False
                      }
                    , Cmd.none
                    )
                _ ->
                  ( { model | banner = errorBanner "Error creating user: cannot parse response" }
                  , Cmd.none
                  )
          _ ->
            ( { model | banner = errorBanner "Error creating user: invalid response" }
            , Cmd.none
            )
      else
        let
          error = "Error creating user: unexpected status code " ++
                  (toString resp.status)
        in
          ( { model | banner = errorBanner error }
          , Cmd.none
          )
