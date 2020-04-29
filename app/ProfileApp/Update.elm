module ProfileApp.Update exposing (..)

import Http
import Core.Routes exposing (Route(..))
import Common.Models exposing (bannerForHttpError, errorBanner, successBanner)
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
      ( { model | banner = bannerForHttpError error }
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

    UpdateDisplayName newDisplayName ->
      let
        updatedUser = case model.user of
                        Just user ->
                          Just { user | displayName = newDisplayName }
                        Nothing ->
                          model.user
      in
        ( { model | user = updatedUser
                  , banner = Nothing
          }
        , Cmd.none
        )

    SaveUser ->
      case model.user of
        Just user ->
          ( model
          , ProfileApp.Api.saveUser user.id user.displayName model.newPassword
          )
        Nothing ->
          (model, Cmd.none)

    SaveUserResult (Err error) ->
      ( { model | banner = bannerForHttpError error }
      , Cmd.none
      )

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
