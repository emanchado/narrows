module EmailVerificationApp.Update exposing (..)

import Http
import Browser.Navigation as Nav

import Core.Routes exposing (Route(..))
import Common.Models exposing (bannerForHttpError, errorBanner, successBanner)
import EmailVerificationApp.Api
import EmailVerificationApp.Messages exposing (..)
import EmailVerificationApp.Models exposing (..)


urlUpdate : Route -> Model -> (Model, Cmd Msg)
urlUpdate route model =
  case route of
    EmailVerificationPage token ->
      ( { model | checking = True
                , error = Nothing
                , token = token
        }
      , EmailVerificationApp.Api.verifyEmailToken token
      )

    _ ->
      (model, Cmd.none)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)

    VerifyEmailTokenResult (Err error) ->
      ( { model | checking = False
                , error = bannerForHttpError error
        }
      , Cmd.none
      )

    VerifyEmailTokenResult (Ok resp) ->
      ( { model | checking = False }
      , Cmd.none
      )
