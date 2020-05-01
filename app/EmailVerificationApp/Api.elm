module EmailVerificationApp.Api exposing (..)

import Http
import Json.Decode as Json exposing (..)
import Json.Encode
import EmailVerificationApp.Messages exposing (Msg, Msg(..))


verifyEmailToken : String -> Cmd Msg
verifyEmailToken token =
  Http.post { url = "/api/verify-email/" ++ token
            , expect = Http.expectString VerifyEmailTokenResult
            , body = Http.emptyBody
            }
