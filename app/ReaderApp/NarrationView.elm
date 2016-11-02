module ReaderApp.NarrationView exposing (view)

import String
import Html exposing (Html, h2, div, span, a, input, textarea, text, img, label, button, br, audio)
import Html.Attributes exposing (id, class, style, for, src, href, target, type', checked, preload, loop, alt, value, rows, placeholder)
import Html.Events exposing (onClick, onInput)

import ReaderApp.Models exposing (Model, Chapter, Banner)
import ReaderApp.Messages exposing (..)
import ReaderApp.Views.Banner
import ReaderApp.Views.MessageThreads

chapterContainerClass : Model -> String
chapterContainerClass model =
  case model.state of
    ReaderApp.Models.Narrating -> ""
    ReaderApp.Models.StartingNarration -> "transparent"
    _ -> "invisible transparent"

backgroundImageStyle : Chapter -> Int -> List (String, String)
backgroundImageStyle chapter backgroundBlurriness =
  let
    imageUrl =
      "/static/narrations/" ++ (toString chapter.narrationId) ++
        "/background-images/" ++ chapter.backgroundImage
    filter = "blur(" ++ (toString backgroundBlurriness) ++ "px)"
  in
    [ ("background-image", "url(" ++ imageUrl ++ ")")
    , ("-webkit-filter", filter)
    , ("-moz-filter", filter)
    , ("filter", filter)
    ]

reactionView : Model -> Html Msg
reactionView model =
  let
    character = case model.chapter of
                  Just chapter -> chapter.character
                  Nothing -> { id = 0, name = "", token = "", notes = "" }
  in
    div [ class "interaction" ]
      [ h2 []
          [ text ("Story notes for " ++ character.name) ]
      , div []
          [ textarea [ placeholder "You can write some notes here. These are remembered between chapters!"
                     , rows 10
                     , onInput UpdateNotesText
                     , value character.notes
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
      , h2 []
          [ text "Discussion "
          , a [ target "_blank"
              , href ("/feed/" ++ character.token)
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
                   , value model.reaction
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
