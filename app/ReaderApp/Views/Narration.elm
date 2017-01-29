module ReaderApp.Views.Narration exposing (view)

import String
import Html exposing (Html, h2, div, span, a, input, textarea, strong, text, img, label, button, br, audio, ul, li)
import Html.Attributes exposing (id, class, style, for, src, href, target, type', checked, preload, loop, alt, defaultValue, rows, placeholder)
import Html.Events exposing (onClick, onInput)
import Http exposing (uriEncode)

import ReaderApp.Models exposing (Model, Chapter, ParticipantCharacter, Banner)
import ReaderApp.Messages exposing (..)
import ReaderApp.Views.Banner
import ReaderApp.Views.MessageThreads

chapterContainerClass : Model -> String
chapterContainerClass model =
  case model.state of
    ReaderApp.Models.Loader -> "invisible transparent"
    ReaderApp.Models.StartingNarration -> "transparent"
    ReaderApp.Models.Narrating -> ""

backgroundImageStyle : Chapter -> Int -> List (String, String)
backgroundImageStyle chapter backgroundBlurriness =
  let
    imageUrl =
      "/static/narrations/" ++ (toString chapter.narrationId) ++
        "/background-images/" ++ (uriEncode <| chapter.backgroundImage)
    filter = "blur(" ++ (toString backgroundBlurriness) ++ "px)"
  in
    [ ("background-image", "url(" ++ imageUrl ++ ")")
    , ("-webkit-filter", filter)
    , ("-moz-filter", filter)
    , ("filter", filter)
    ]

characterView : Int -> ParticipantCharacter -> Html Msg
characterView narrationId character =
  let
    avatarUrl =
      case character.avatar of
        Just avatar ->
          "/static/narrations/" ++ (toString narrationId) ++ "/avatars/" ++ avatar
        Nothing ->
          "/img/default-avatar.png"
    description =
      case character.description of
        Just desc -> desc
        Nothing -> ""
  in
    li []
      [ img [ class "avatar"
            , src avatarUrl
            ]
          []
      , div []
          [ strong [] [ text character.name ]
          , br [] []
          , text description
          ]
      ]

reactionView : Model -> Html Msg
reactionView model =
  let
    (character, participants, narrationId) =
      case model.chapter of
        Just chapter -> ( chapter.character
                        , chapter.participants
                        , chapter.narrationId
                        )
        Nothing -> ( { id = 0, name = "", token = "", notes = Nothing }
                   , []
                   , 0
                   )
  in
    div [ class "interaction" ]
      [ div [ class <| "reference-container" ++ if model.referenceInformationVisible then "" else " hidden"
            ]
          [ h2 [] [ text "Reference information" ]
          , ul [ class "dramatis-personae" ]
            (List.map (characterView narrationId) participants)
          , h2 [] [ text ("Story notes for " ++ character.name) ]
          , div []
              [ textarea [ placeholder "You can write some notes here. These are remembered between chapters!"
                         , rows 10
                         , onInput UpdateNotesText
                         , defaultValue (case character.notes of
                                           Just notes -> notes
                                           Nothing -> "")
                         ]
                  []
              ]
          , div [ class "btn-bar" ]
              [ span [ id "save-notes-message"
                    , style [ ("display", "none") ]
                    ]
                  [ text "Notes saved" ]
              , button [ class "btn"
                       , onClick SendNotes
                       ]
                  [ text "Save " ]
              ]
          , div [ class "arrow arrow-up", onClick HideReferenceInformation ] []
          ]
      , if not model.referenceInformationVisible then
          div [ class "arrow arrow-down", onClick ShowReferenceInformation ] []
        else
          text ""
      , h2 []
          [ text "Discussion "
          , a [ target "_blank"
              , href ("/feeds/" ++ character.token)
              ]
              [ img [ src "/img/rss.png" ] [] ]
          ]
      , div [ class "messages" ]
          [ ReaderApp.Views.MessageThreads.listView model
          ]
      , h2 [] [ text "Action" ]
      , case model.banner of
          Just banner -> ReaderApp.Views.Banner.view banner
          Nothing -> text ""
      , div [ class ("player-reply" ++ (if model.reactionSent then
                                          " invisible"
                                        else
                                          "")) ]
        [ textarea [ placeholder "What do you do? Try to consider several possibilities…"
                   , rows 10
                   , defaultValue model.reaction
                   , onInput UpdateReactionText
                   ]
            []
        , div [ class "btn-bar" ]
            [ button [ class "btn btn-default"
                     , onClick SendReaction
                     ]
                [ text "Send" ]
            ]
        ]
      ]

view : Model -> Html Msg
view model =
  case model.chapter of
    Just chapter ->
      div [ id "chapter-container", class (chapterContainerClass model) ]
        [ div [ id "top-image"
              , style (backgroundImageStyle chapter model.backgroundBlurriness)
              ]
            [ text (if (String.isEmpty chapter.title) then
                      "Untitled"
                    else
                      chapter.title) ]
        , img [ id "play-icon"
              , src ("/img/" ++
                       (if model.musicPlaying then "play" else "mute") ++
                       "-small.png")
              , alt (if model.musicPlaying then "Stop" else "Start")
              , onClick PlayPauseMusic
              ]
            []
        , audio [ id "background-music"
                , src ("/static/narrations/" ++
                         (toString chapter.narrationId) ++
                         "/audio/" ++ chapter.audio)
                , loop True
                , preload (if model.backgroundMusic then "auto" else "none")
                ]
            []
        , div [ id "chapter-text", class "chapter" ]
            [ text "Chapter contents go here" ]
        , reactionView model
        ]
    Nothing ->
      div [ id "chapter-container", class (chapterContainerClass model) ]
        [ text "Internal Error: no chapter." ]
