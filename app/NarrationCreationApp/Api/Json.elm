module NarrationCreationApp.Api.Json exposing (..)

import Json.Decode as Json exposing (..)
import Json.Encode

import Common.Api.Json exposing (parseNarrationStatus, parseFullCharacter, parseFileSet)
import NarrationCreationApp.Models exposing (NewNarrationProperties, NarrationUpdateProperties, CreateNarrationResponse, NarrationInternal, StyleSet)


parseStyleSet : Json.Decoder StyleSet
parseStyleSet =
    Json.map8 StyleSet
        (maybe (field "titleFont" string))
        (maybe (field "titleFontSize" string))
        (maybe (field "titleColor" string))
        (maybe (field "titleShadowColor" string))
        (maybe (field "bodyTextFont" string))
        (maybe (field "bodyTextFontSize" string))
        (maybe (field "bodyTextColor" string))
        (maybe (field "bodyTextBackgroundColor" string))
    |> andThen (\r ->
                  Json.map r
                    (maybe (field "separatorImage" string)))

parseNarrationInternal : Json.Decoder NarrationInternal
parseNarrationInternal =
    Json.map8 NarrationInternal
        (field "id" int)
        (field "title" string)
        (field "status" parseNarrationStatus)
        (field "intro" Json.value)
        (field "introUrl" string)
        (maybe (field "introAudio" string))
        (maybe (field "introBackgroundImage" string))
        (field "notes" string)
    |> andThen (\r ->
               Json.map5 r
                 (field "characters" <| list parseFullCharacter)
                 (maybe (field "defaultAudio" string))
                 (maybe (field "defaultBackgroundImage" string))
                 (field "files" parseFileSet)
                 (field "styles" parseStyleSet))


parseCreateNarrationResponse : Json.Decoder CreateNarrationResponse
parseCreateNarrationResponse =
  Json.map2 CreateNarrationResponse
      (field "id" int)
      (field "title" string)


encodeNewNarration : NewNarrationProperties -> Value
encodeNewNarration props =
  (Json.Encode.object
     [ ( "title", Json.Encode.string props.title )
     ])


encodeStyles : StyleSet -> Value
encodeStyles styles =
  (Json.Encode.object
     [ ( "titleFont", case styles.titleFont of
                        Just font -> Json.Encode.string font
                        Nothing -> Json.Encode.null
       )
     , ( "titleFontSize", case styles.titleFontSize of
                            Just font -> Json.Encode.string font
                            Nothing -> Json.Encode.null
       )
     , ( "titleColor", case styles.titleColor of
                         Just color -> Json.Encode.string color
                         Nothing -> Json.Encode.null
       )
     , ( "titleShadowColor", case styles.titleShadowColor of
                               Just color -> Json.Encode.string color
                               Nothing -> Json.Encode.null
       )
     , ( "bodyTextFont", case styles.bodyTextFont of
                           Just font -> Json.Encode.string font
                           Nothing -> Json.Encode.null
       )
     , ( "bodyTextFontSize", case styles.bodyTextFontSize of
                               Just font -> Json.Encode.string font
                               Nothing -> Json.Encode.null
       )
     , ( "bodyTextColor", case styles.bodyTextColor of
                            Just color -> Json.Encode.string color
                            Nothing -> Json.Encode.null
       )
     , ( "bodyTextBackgroundColor", case styles.bodyTextBackgroundColor of
                                      Just color -> Json.Encode.string color
                                      Nothing -> Json.Encode.null
       )
     , ( "separatorImage", case styles.separatorImage of
                             Just image -> Json.Encode.string image
                             Nothing -> Json.Encode.null
       )
     ])


encodeNarrationUpdate : NarrationUpdateProperties -> Value
encodeNarrationUpdate props =
  let
    newEncodedIntroBackgroundImage =
      case props.introBackgroundImage of
        Just bgImage -> Json.Encode.string bgImage
        Nothing -> Json.Encode.null
    newEncodedIntroAudio =
      case props.introAudio of
        Just audio -> Json.Encode.string audio
        Nothing -> Json.Encode.null
    newEncodedDefaultBackgroundImage =
      case props.defaultBackgroundImage of
        Just bgImage -> Json.Encode.string bgImage
        Nothing -> Json.Encode.null
    newEncodedDefaultAudio =
      case props.defaultAudio of
        Just audio -> Json.Encode.string audio
        Nothing -> Json.Encode.null
  in
    (Json.Encode.object
       [ ( "title", Json.Encode.string props.title )
       , ( "intro", props.intro )
       , ( "introBackgroundImage", newEncodedIntroBackgroundImage )
       , ( "introAudio", newEncodedIntroAudio )
       , ( "defaultBackgroundImage", newEncodedDefaultBackgroundImage )
       , ( "defaultAudio", newEncodedDefaultAudio )
       , ( "styles", encodeStyles props.styles )
       ])
