module Tests exposing (..)

import Test exposing (..)
import Expect
import String
import Json.Decode
import Json.Encode

import Api exposing (parseMessage, parseChapter)

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

decodesChapter : Test
decodesChapter =
  test "Decodes chapter" <|
    \() ->
      let
        input =
          """
            {"id":5,
             "title":"Unpublished chapter",
             "audio":"Twenty_One.mp3",
             "narrationId":1,
             "backgroundImage":"harrises.jpg",
             "text":{"type":"doc","content":[]},
             "published":"2016-10-05T20:57:13.661Z",
             "participants":[{"id":1,"name":"Mildred Mayfield"},
                             {"id":2,"name":"Frank Mayfield"}],
             "character":{"id":1,
                          "name":"Mildred Mayfield",
                          "token":"548fd8de-833a-11e6-80f5-8ba0a58c2f54"},
             "reaction":"Some lame action, yo!",
             "notes":""}
          """
        decodedOutput =
          Json.Decode.decodeString parseChapter input
        decodedText =
          Json.Decode.decodeString Json.Decode.value "[]"
      in
        case decodedText of
          Ok result ->
            Expect.equal decodedOutput
              (Ok { id = 5
                  , title = "Unpublished chapter"
                  , audio = "Twenty_One.mp3"
                  , narrationId = 1
                  , backgroundImage = "harrises.jpg"
                  , text = result
                  , participants = [ { id = 1, name = "Mildred Mayfield"}
                                   , { id = 2, name = "Frank Mayfield"}
                                   ]
                  , character = { id = 1
                                , name = "Mildred Mayfield"
                                , token = "548fd8de-833a-11e6-80f5-8ba0a58c2f54"
                                }
                  , reaction = Just "Some lame action, yo!"
                  , notes = ""
                  })
          _ ->
            Expect.equal 1 0

all : Test
all =
    describe "JSON decoders"
        [ decodesMessageNoRecipients
        , decodesMessageNoSender
        , decodesChapter
        ]
