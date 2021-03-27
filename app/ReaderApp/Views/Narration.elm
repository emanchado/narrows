module ReaderApp.Views.Narration exposing (view)

import String
import Html exposing (Html, h2, h3, div, span, a, input, textarea, em, strong, text, img, label, button, br, audio, ul, li, blockquote, p)
import Html.Attributes exposing (id, class, style, for, src, href, target, type_, checked, preload, loop, alt, rows, placeholder)
import Html.Events exposing (onClick, onInput)
import Common.Views exposing (bannerView, characterAvatarView, AvatarSize(..))
import Common.Views.Reading exposing (backgroundImageStyle, chapterContainerClass)
import Common.Models exposing (ParticipantCharacter)
import ReaderApp.Models exposing (Model, Chapter, OwnCharacter, Banner)
import ReaderApp.Messages exposing (..)
import ReaderApp.Views.MessageThreads


characterView : Int -> OwnCharacter -> ParticipantCharacter -> Html Msg
characterView narrationId ownCharacter participant =
    li []
      [ characterAvatarView narrationId Normal participant
      , div []
          [ strong [] [ text participant.name ]
          , if ownCharacter.id == participant.id then
              span []
                [ text " — "
                , a [ href <| "/characters/" ++ ownCharacter.token ]
                    [ text "character sheet" ]
                ]
            else
              text ""
          , br [] []
          , div [ id <| "description-character-" ++ (String.fromInt participant.id)
                , class "character-description"
                ]
              []
          ]
      ]


reactionView : Model -> Html Msg
reactionView model =
  let
    ( character, participants, narrationId ) =
      case model.chapter of
        Just chapter ->
          ( chapter.character
          , chapter.participants
          , chapter.narrationId
          )

        Nothing ->
          ( { id = 0, name = "", token = "", notes = Nothing }
          , []
          , 0
          )
  in
    div [ class "interaction" ]
      [ div [ class <| "reference-container" ++
                if model.referenceInformationVisible then
                  ""
                else
                  " hidden"
            ]
          [ h2 (if model.referenceInformationVisible then
                  [ style "display" "none" ]
                else
                  [ style "cursor" "pointer"
                  , onClick ShowReferenceInformation
                  ])
              [ text "Reference information" ]
        , h2 [] [ text ("Story notes for " ++ character.name) ]
        , div []
            [ textarea [ placeholder "You can write some notes here. These are remembered between chapters!"
                       , rows 10
                       , onInput UpdateNotesText
                       ]
                [ text (case character.notes of
                                  Just notes -> notes
                                  Nothing -> "") ]
            ]
        , div [ class "btn-bar" ]
            [ span [ id "save-notes-message"
                   , style "display" "none"
                   ]
                [ text "Notes saved" ]
            , button [ class "btn"
                     , onClick SendNotes
                     ]
                [ text "Save " ]
            ]
        , h2 [] [ text "Characters in this chapter" ]
        , ul [ class "dramatis-personae" ]
            (List.map (characterView narrationId character) participants)
        , div [ class "arrow arrow-up", onClick HideReferenceInformation ] []
        ]
      , if not model.referenceInformationVisible then
          div [ class "arrow arrow-down", onClick ShowReferenceInformation ] []
        else
          text ""
      , div [ class "messages" ]
          [ h2 []
            [ text "Discussion "
            , a [ target "_blank"
                , href ("/feeds/" ++ character.token)
                ]
                [ img [ src "/img/rss.png" ] [] ]
            ]
          , ReaderApp.Views.MessageThreads.listView model
          ]
      , bannerView model.banner
      ]


view : Model -> Html Msg
view model =
  case model.chapter of
    Just chapter ->
      div [ id "chapter-container"
          , class (chapterContainerClass model.state)
          ]
        [ div (List.append
                 [ id "top-image" ]
                 (backgroundImageStyle chapter.narrationId chapter.backgroundImage model.backgroundBlurriness))
            [ text (if (String.isEmpty chapter.title) then
                      "Untitled"
                    else
                      chapter.title)
            ]
        , case chapter.audio of
            Just _ ->
              img [ id "play-icon"
                  , src ("/img/" ++ (if model.musicPlaying then
                                       "play"
                                     else
                                       "mute") ++
                           "-small.png")
                  , alt (if model.musicPlaying then
                           "Stop"
                         else
                           "Start")
                  , onClick PlayPauseMusic
                  ]
                []
            Nothing ->
              text ""
        , case chapter.audio of
            Just audioUrl ->
              audio [ id "background-music"
                    , src ("/static/narrations/" ++
                             (String.fromInt chapter.narrationId) ++
                             "/audio/" ++
                             audioUrl)
                    , loop True
                    , preload (if model.backgroundMusic then
                                 "auto"
                               else
                                 "none")
                    ]
                []
            Nothing ->
              text ""
        , div [ id "chapter-text", class "chapter" ]
            [ text "Chapter contents go here" ]
        , reactionView model
        ]

    Nothing ->
      div [ id "chapter-container", class (chapterContainerClass model.state) ]
        [ text "Internal Error: no chapter." ]
