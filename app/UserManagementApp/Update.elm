module UserManagementApp.Update exposing (..)

import Http
import Core.Routes exposing (Route(..))
import Common.Models exposing (errorBanner)
import UserManagementApp.Api
import UserManagementApp.Messages exposing (..)
import UserManagementApp.Models exposing (..)


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate route model =
    case route of
        UserManagementPage ->
            ( { model | banner = Nothing
                      , users = Nothing
              }
            , UserManagementApp.Api.fetchUsers
            )

        _ ->
            ( model, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        UsersFetchResult (Err error) ->
          case error of
            Http.BadBody parserError ->
              ( { model | banner = errorBanner <| "Error parsing fetched users: " ++ parserError }
              , Cmd.none
              )
            Http.BadStatus status ->
              ( { model | banner = errorBanner <| "Error fetching users: " ++ (String.fromInt status) }
              , Cmd.none
              )
            _ ->
              ( { model | banner = errorBanner <| "Error fetching users, network error" }
              , Cmd.none
              )

        UsersFetchResult (Ok resp) ->
            ( { model | users = Just resp.users }
            , Cmd.none
            )

        SelectUser userId ->
            case model.users of
                Just users ->
                    let
                        selectedUser =
                            List.head <| List.filter (\u -> u.id == userId) users

                        displayName =
                            case selectedUser of
                                Just user ->
                                    user.displayName

                                Nothing ->
                                    ""

                        isUserAdmin =
                            case selectedUser of
                                Just user ->
                                    user.role == "admin"

                                Nothing ->
                                    False
                    in
                        ( { model
                            | userUi =
                                Just
                                    { userId = userId
                                    , displayName = displayName
                                    , password = ""
                                    , isAdmin = isUserAdmin
                                    }
                            , banner = Nothing
                          }
                        , Cmd.none
                        )

                Nothing ->
                    ( model, Cmd.none )

        UnselectUser ->
            ( { model
                | userUi = Nothing
                , banner = Nothing
              }
            , Cmd.none
            )

        UpdateDisplayName newDisplayName ->
            let
                updatedUserUi =
                    case model.userUi of
                        Just userUi ->
                            Just { userUi | displayName = newDisplayName }

                        Nothing ->
                            Nothing
            in
                ( { model
                    | userUi = updatedUserUi
                    , banner = Nothing
                  }
                , Cmd.none
                )

        UpdatePassword newPassword ->
            let
                updatedUserUi =
                    case model.userUi of
                        Just userUi ->
                            Just { userUi | password = newPassword }

                        Nothing ->
                            Nothing
            in
                ( { model
                    | userUi = updatedUserUi
                    , banner = Nothing
                  }
                , Cmd.none
                )

        UpdateIsAdmin isAdmin ->
            let
                updatedUserUi =
                    case model.userUi of
                        Just userUi ->
                            Just { userUi | isAdmin = isAdmin }

                        Nothing ->
                            Nothing
            in
                ( { model
                    | userUi = updatedUserUi
                    , banner = Nothing
                  }
                , Cmd.none
                )

        SaveUser ->
            case model.userUi of
                Just userUi ->
                    ( model, UserManagementApp.Api.saveUser userUi )

                Nothing ->
                    ( model, Cmd.none )

        SaveUserResult (Err err) ->
            let
                errorString =
                    case err of
                        Http.BadBody parserError ->
                            "Bad payload: " ++ parserError

                        Http.BadStatus status ->
                            "Got status " ++ (String.fromInt status)

                        _ ->
                            "Cannot connect to server"
            in
                ( { model | banner = errorBanner errorString }, Cmd.none )

        SaveUserResult (Ok resp) ->
          case resp of
            Http.GoodStatus_ _ _ ->
              ( { model | userUi = Nothing }
              , UserManagementApp.Api.fetchUsers
              )
            Http.BadStatus_ metadata _ ->
              ( { model | banner = errorBanner <| "Error updating user, status code " ++ (String.fromInt metadata.statusCode) }
              , Cmd.none
              )
            _ ->
              ( { model | banner = errorBanner "Error updating user, network error" }
              , Cmd.none
              )

        DeleteUserDialog ->
          ( { model | showDeleteUserDialog = True }
          , Cmd.none
          )

        CancelDeleteUser ->
          ( { model | showDeleteUserDialog = False }
          , Cmd.none
          )

        DeleteUser ->
            case model.userUi of
                Just userUi ->
                    ( { model | showDeleteUserDialog = False }
                    , UserManagementApp.Api.deleteUser userUi.userId
                    )

                Nothing ->
                    ( model, Cmd.none )

        DeleteUserResult (Err err) ->
            let
                errorString =
                    case err of
                        Http.BadBody parserError ->
                            "Bad payload: " ++ parserError

                        Http.BadStatus status ->
                            "Got status " ++ (String.fromInt status)

                        _ ->
                            "Cannot connect to server"
            in
                ( { model | banner = errorBanner errorString }, Cmd.none )

        DeleteUserResult (Ok resp) ->
          case resp of
            Http.GoodStatus_ _ _ ->
              ( { model | userUi = Nothing }
              , UserManagementApp.Api.fetchUsers
              )
            Http.BadStatus_ metadata _ ->
              ( { model | banner = errorBanner <| "Error deleting user, status code " ++ (String.fromInt metadata.statusCode) }
              , Cmd.none
              )
            _ ->
              ( { model | banner = errorBanner "Error deleting user, network error" }
              , Cmd.none
              )

        UpdateNewUserEmail newEmail ->
            ( { model | newUserEmail = newEmail, banner = Nothing }
            , Cmd.none
            )

        UpdateNewUserDisplayName newDisplayName ->
            ( { model | newUserDisplayName = newDisplayName, banner = Nothing }
            , Cmd.none
            )

        UpdateNewUserIsAdmin newIsAdmin ->
            ( { model | newUserIsAdmin = newIsAdmin, banner = Nothing }
            , Cmd.none
            )

        SaveNewUser ->
            ( model
            , UserManagementApp.Api.saveNewUser model.newUserEmail model.newUserDisplayName model.newUserIsAdmin
            )

        SaveNewUserResult (Err err) ->
            ( { model | banner = errorBanner "Error creating user" }
            , Cmd.none
            )

        SaveNewUserResult (Ok user) ->
            let
              updatedUsers = case model.users of
                               Just users -> Just (List.append users [ user ])
                               Nothing -> Just [ user ]
            in
              ( { model | users = updatedUsers
                        , newUserEmail = ""
                        , newUserDisplayName = ""
                        , newUserIsAdmin = False
                }
              , Cmd.none
              )
