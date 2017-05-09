module ChapterEditApp.Api.Json exposing (..)

import Json.Decode as Json exposing (..)
import Json.Encode
import Common.Models exposing (FullCharacter, Narration, Chapter, FileSet)
import Common.Api.Json exposing (parseCharacter)
import ChapterEditApp.Models exposing (LastReactions, LastChapter, LastReaction, LastReactionChapter)


parseFullCharacter : Json.Decoder FullCharacter
parseFullCharacter =
    Json.map3 FullCharacter (field "id" int) (field "name" string) (field "token" string)


parseChapter : Json.Decoder Chapter
parseChapter =
    Json.map8 Chapter
        (field "id" int)
        (field "narrationId" int)
        (field "title" string)
        (maybe (field "audio" string))
        (maybe (field "backgroundImage" string))
        (field "text" Json.value)
        (field "participants" <| list parseFullCharacter)
        (maybe (field "published" string))


parseFileSet : Json.Decoder FileSet
parseFileSet =
    Json.map3 FileSet
        (field "audio" <| list string)
        (field "backgroundImages" <| list string)
        (field "images" <| list string)


parseLastReactionChapter : Json.Decoder LastReactionChapter
parseLastReactionChapter =
    Json.map2 LastReactionChapter
        (field "id" int)
        (field "title" string)


parseLastReaction : Json.Decoder LastReaction
parseLastReaction =
    Json.map3 LastReaction
        (field "chapter" parseLastReactionChapter)
        (field "character" parseCharacter)
        (maybe (field "text" string))


parseLastChapter : Json.Decoder LastChapter
parseLastChapter =
    Json.map3 LastChapter
        (field "id" int)
        (field "title" string)
        (field "text" Json.value)


parseLastReactions : Json.Decoder LastReactions
parseLastReactions =
    Json.map3 LastReactions
        (field "chapterId" int)
        (field "lastReactions" <| list parseLastReaction)
        (field "lastChapters" <| list parseLastChapter)


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
      , ( "participants", Json.Encode.list <| List.map encodeCharacter chapter.participants )
      , ( "published"
        , case chapter.published of
              Just published ->
                  Json.Encode.string published

              Nothing ->
                  Json.Encode.null
        )
      ])
