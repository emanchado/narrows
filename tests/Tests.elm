module Tests exposing (..)

import Test exposing (..)
import Expect
import String
import Json.Decode

import Api exposing (parseMessage)

decodesMessageNoRecipients : Test
decodesMessageNoRecipients =
  test "Decodes message without recipients" <|
    \() ->
      let
        input =
          """
            {"id": 2,
             "body": "Could I make an interstate call?",
             "sentAt": "2016-10-20 19:43:28",
             "sender": {"id": 1, "name": "Mildred Mayfield"}}
          """
        decodedOutput =
          Json.Decode.decodeString parseMessage input
      in
        Expect.equal decodedOutput
          (Ok { id = 2
              , body = "Could I make an interstate call?"
              , sentAt = "2016-10-20 19:43:28"
              , sender = Just { id = 1
                              , name = "Mildred Mayfield"
                              }
              , recipients = Nothing
              })

decodesMessageNoSender : Test
decodesMessageNoSender =
  test "Decodes message without sender" <|
    \() ->
      let
        input =
          """
            {"id": 4,
             "body": "Yes, it's possible although expensive.",
             "sentAt": "2016-10-21 18:10:51",
             "recipients": [
                 {"id": 1, "name": "Mildred Mayfield"}
             ]}
          """
        decodedOutput =
          Json.Decode.decodeString parseMessage input
      in
        Expect.equal decodedOutput
          (Ok { id = 4
              , body = "Yes, it's possible although expensive."
              , sentAt = "2016-10-21 18:10:51"
              , sender = Nothing
              , recipients = Just [ { id = 1
                                    , name = "Mildred Mayfield"
                                    }
                                  ]
              })

all : Test
all =
    describe "JSON decoders"
        [ decodesMessageNoRecipients
        , decodesMessageNoSender
        ]
