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
      ( { model | banner = errorBanner <| "Error fetching user: " ++ (toString error) }
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
                        Http.BadPayload parserError _ ->
                          "Bad payload: " ++ parserError
                        Http.BadStatus resp ->
                          "Got status " ++ (toString resp.status) ++ " with body " ++ resp.body
                        _ ->
                          "Cannot connect to server"
      in
        ({ model | banner = errorBanner errorString }, Cmd.none)

    SaveUserResult (Ok resp) ->
      if (resp.status.code >= 200) && (resp.status.code < 300) then
        ( { model | banner = successBanner "User updated"
                  , newPassword = "" }
        , Cmd.none
        )
      else
        ( { model | banner = errorBanner "Error updating user" }
        , Cmd.none
        )
