module Core.Api exposing (..)

import Http
import Json.Decode as Json exposing (..)
import Json.Encode
import Core.Models
import Core.Messages exposing (..)


parseSession : Json.Decoder Core.Models.UserInfo
parseSession =
    Json.map3 Core.Models.UserInfo
        (field "id" int)
        (field "email" string)
        (field "role" string)


refreshSession : Cmd Msg
refreshSession =
  Http.send SessionFetchResult <|
    Http.get "/api/session" parseSession


login : String -> String -> Cmd Msg
login email password =
  let
    jsonEncodedBody = (Json.Encode.object
                         [ ( "email", Json.Encode.string email )
                         , ( "password", Json.Encode.string password )
                         ])
  in
    Http.send LoginResult <|
      Http.post "/api/session" (Http.jsonBody jsonEncodedBody) parseSession


logout : Cmd Msg
logout =
  Http.send LogoutResult <|
      Http.request { method = "DELETE"
                   , url = "/api/session"
                   , headers = []
                   , body = Http.emptyBody
                   , expect = Http.expectString
                   , timeout = Nothing
                   , withCredentials = False
                   }
