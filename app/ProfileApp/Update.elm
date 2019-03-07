module ProfileApp.Update exposing (..)

import Http
import Core.Routes exposing (Route(..))
import Common.Models exposing (errorBanner, successBanner)
import ProfileApp.Api
import ProfileApp.Messages exposing (..)
import ProfileApp.Models exposing (..)


urlUpdate : Route -> Model -> (Model, Cmd Msg)
urlUpdate route model =
  case route of
    ProfilePage ->
      ( { model | banner = Nothing
                , user = Nothing
                , newPassword = ""
        }
      , ProfileApp.Api.fetchCurrentUser
      )

    _ ->
      (model, Cmd.none)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)

    UserFetchResult (Err error) ->
      case error of
        Http.BadStatus status ->
          ( { model | banner = errorBanner <| "Error fetching user: " ++ (String.fromInt status) }
          , Cmd.none
          )
        Http.BadBody body ->
          ( { model | banner = errorBanner <| "Could not parse fetched user: " ++ body }
          , Cmd.none
          )
        _ ->
          ( { model | banner = errorBanner <| "Network error fetching user" }
          , Cmd.none
          )

    UserFetchResult (Ok resp) ->
      ( { model | user = Just resp }
      , Cmd.none
      )

    UpdatePassword newPassword ->
      ( { model | newPassword = newPassword
                , banner = Nothing
        }
      , Cmd.none
      )


    SaveUser ->
      case model.user of
        Just user ->
          (model, ProfileApp.Api.saveUser user.id model.newPassword)
        Nothing ->
          (model, Cmd.none)

    SaveUserResult (Err err) ->
      let
        errorString = case err of
                        Http.BadBody parserError ->
                          "Bad payload: " ++ parserError
                        Http.BadStatus status ->
                          "Got status " ++ (String.fromInt status)
                        _ ->
                          "Cannot connect to server"
      in
        ({ model | banner = errorBanner errorString }, Cmd.none)

    SaveUserResult (Ok resp) ->
      case resp of
        Http.GoodStatus_ _ _ ->
          ( { model | banner = successBanner "User updated"
                    , newPassword = "" }
          , Cmd.none
          )
        Http.BadStatus_ metadata _ ->
          ( { model | banner = errorBanner <| "Error updating user, error code " ++ (String.fromInt metadata.statusCode) }
          , Cmd.none
          )
        _ ->
          ( { model | banner = errorBanner "Error updating user, network error" }
          , Cmd.none
          )
