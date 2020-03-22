module NarrationIntroApp.Api exposing (..)

import Http
import Json.Decode as Json exposing (..)
import Json.Encode
import Common.Api.Json exposing (parseUserInfo, parseParticipantCharacter)
import NarrationIntroApp.Models exposing (NarrationIntroResponse)
import NarrationIntroApp.Messages exposing (Msg, Msg(..))


parseNarrationIntroResponse : Json.Decoder NarrationIntroResponse
parseNarrationIntroResponse =
    Json.map6 NarrationIntroResponse
        (field "id" int)
        (field "title" string)
        (field "characters" <| list parseParticipantCharacter)
        (field "intro" Json.value)
        (maybe (field "backgroundImage" string))
        (maybe (field "audio" string))


fetchCurrentSession : Cmd Msg
fetchCurrentSession =
  Http.get { url = "/api/session"
           , expect = Http.expectJson SessionFetchResult parseUserInfo
           }


fetchNarrationIntro : String -> Cmd Msg
fetchNarrationIntro narrationToken =
  Http.get { url = "/api/narrations/by-token/" ++ narrationToken
           , expect = Http.expectJson NarrationIntroFetchResult parseNarrationIntroResponse
           }

claimCharacter : Int -> String -> Cmd Msg
claimCharacter characterId email =
  let
    jsonEncodedBody = (Json.Encode.object
                         [ ( "email", Json.Encode.string email )
                         ])
  in
    Http.post { url = "/api/characters/by-id/" ++ (String.fromInt characterId) ++ "/claim"
              , body = Http.jsonBody jsonEncodedBody
              , expect = Http.expectWhatever ClaimCharacterFetchResult
              }
