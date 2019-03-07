module ChapterEditApp.Api.Json exposing (..)

import Json.Decode as Json exposing (..)
import Json.Encode
import Common.Models exposing (FullCharacter, Narration, Chapter, FileSet)
import Common.Api.Json exposing (parseCharacter, parseFullCharacter, parseChapter, parseMessageThread)
import ChapterEditApp.Models exposing (LastReactionsResponse, LastChapter)


parseFileSet : Json.Decoder FileSet
parseFileSet =
    Json.map3 FileSet
        (field "audio" <| list string)
        (field "backgroundImages" <| list string)
        (field "images" <| list string)


parseLastReactionResponse : Json.Decoder LastReactionsResponse
parseLastReactionResponse =
    Json.map LastReactionsResponse
        (field "lastChapters" <| list parseLastChapter)


parseLastChapter : Json.Decoder LastChapter
parseLastChapter =
    Json.map5 LastChapter
        (field "id" int)
        (field "title" string)
        (field "text" Json.value)
        (field "participants" <| list parseCharacter)
        (field "messageThreads" <| list parseMessageThread)


encodeCharacter : FullCharacter -> Json.Encode.Value
encodeCharacter character =
    (Json.Encode.object
        [ ( "id", Json.Encode.int character.id )
        , ( "name", Json.Encode.string character.name )
        , ( "token", Json.Encode.string character.token )
        ]
    )


encodeChapter : Chapter -> Json.Encode.Value
encodeChapter chapter =
  (Json.Encode.object
      [ ( "title", Json.Encode.string chapter.title )
      , ( "text", chapter.text )
      , ( "audio"
        , case chapter.audio of
              Just audio ->
                  Json.Encode.string audio

              Nothing ->
                  Json.Encode.null
        )
      , ( "backgroundImage"
        , case chapter.backgroundImage of
              Just bgImage ->
                  Json.Encode.string bgImage

              Nothing ->
                  Json.Encode.null
        )
      , ( "participants", Json.Encode.list encodeCharacter chapter.participants )
      , ( "published"
        , case chapter.published of
              Just published ->
                  Json.Encode.string published

              Nothing ->
                  Json.Encode.null
        )
      ])
