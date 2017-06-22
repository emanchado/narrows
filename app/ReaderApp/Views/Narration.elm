module ReaderApp.Views.Narration exposing (view)

import String
import Html exposing (Html, h2, h3, div, span, a, input, textarea, em, strong, text, img, label, button, br, audio, ul, li, blockquote, p)
import Html.Attributes exposing (id, class, style, for, src, href, target, type_, checked, preload, loop, alt, defaultValue, rows, placeholder)
import Html.Events exposing (onClick, onInput)
import Http exposing (encodeUri)
import Common.Views exposing (bannerView, linkTo)
import ReaderApp.Models exposing (Model, Chapter, OwnCharacter, ParticipantCharacter, Banner)
import ReaderApp.Messages exposing (..)
import ReaderApp.Views.MessageThreads


chapterContainerClass : Model -> String
chapterContainerClass model =
  case model.state of
    ReaderApp.Models.Loader -> "invisible transparent"
    ReaderApp.Models.StartingNarration -> "transparent"
    ReaderApp.Models.Narrating -> "fade-in"


backgroundImageStyle : Chapter -> Int -> List ( String, String )
backgroundImageStyle chapter backgroundBlurriness =
  case chapter.backgroundImage of
    Just backgroundImage ->
      let
        imageUrl =
          "/static/narrations/" ++
            (toString chapter.narrationId) ++
            "/background-images/" ++
            (encodeUri <| backgroundImage)

        filter = "blur(" ++ (toString backgroundBlurriness) ++ "px)"
      in
        [ ( "background-image", "url(" ++ imageUrl ++ ")" )
        , ( "-webkit-filter", filter )
        , ( "-moz-filter", filter )
        , ( "filter", filter )
        ]
    Nothing ->
      []


characterView : Int -> OwnCharacter -> ParticipantCharacter -> Html Msg
characterView narrationId ownCharacter participant =
  let
    avatarUrl =
      case participant.avatar of
        Just avatar ->
          "/static/narrations/" ++ (toString narrationId) ++ "/avatars/" ++ avatar

        Nothing ->
          "/img/default-avatar.png"
  in
    li []
      [ img [ class "avatar"
            , src avatarUrl
            ]
          []
      , div []
          [ strong [] [ text participant.name ]
          , if ownCharacter.id == participant.id then
              span []
                [ text " — "
                , a
                  (linkTo
                    NavigateTo
                    ("/characters/" ++ ownCharacter.token)
                  )
                  [ text "character sheet" ]
                ]
            else
              text ""
          , br [] []
          , div [ id <| "description-character-" ++ (toString participant.id)
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
          [ h2 [ style <| if model.referenceInformationVisible then
                            [ ( "display", "none" ) ]
                          else
                            []
               ]
              [ text "Reference information" ]
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
                   , style [ ( "display", "none" ) ]
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
      , h2 [] [ text "Action "
              , img [ src "/img/info.png"
                    , class "help"
                    , onClick ToggleReactionTip
                    ]
                  []
              , if model.showReactionTip then
                  div [ class "floating-tip" ]
                    [ h3 [] [ text "Tips" ]
                    , p []
                        [ text <| "The most important things to convey " ++
                            "are what your character "
                        , strong [] [ text "does" ]
                        , text <| " and what they "
                        , strong [] [ text "think" ]
                        , text " or "
                        , strong [] [ text "feel" ]
                        , text ", eg:"
                        ]
                    , blockquote []
                        [ text <| "I’ll go up the ladder and search the " ++
                            "attic, listening for any signs of activity " ++
                            "up there as I climb. I don’t like this place " ++
                            "one bit so I’ll try to find the chest or any " ++
                            "clue, and leave as soon as I can."
                        ]
                    , p []
                        [ text <| "Often they include possibilities or " ++
                            "plans for the near future:"
                        ]
                    , blockquote []
                        [ text <| "I ask what’s the deal with the victim’s " ++
                            "tattoo and if she has seen it before. She " ++
                            "must be hiding something so if she doesn’t " ++
                            "speak up I will wait outside and follow her " ++
                            "to see if the meets anyone or goes back to " ++
                            "the club."
                        ]
                    , p []
                        [ text <| "Including direct quotes is a good way " ++
                            "to describe your character’s mood, too:"
                        ]
                    , blockquote []
                        [ text <| "“This is awful. We need to contact him " ++
                            "and make him stop.” I call Robert: “Hi… you " ++
                            "need to stop that. I *will* kick you out if " ++
                            "you don’t stop. She is *not* ready. Do you " ++
                            "hear me?”"
                        ]
                    ]
                else
                  text ""
              ]
      , bannerView model.banner
      , div [ class <| "player-reply" ++ (if model.reactionSent then
                                            " invisible"
                                          else
                                            "")
            ]
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
      div [ id "chapter-container"
          , class (chapterContainerClass model)
          ]
        [ div [ id "top-image"
              , style (backgroundImageStyle chapter model.backgroundBlurriness)
              ]
            [ text (if (String.isEmpty chapter.title) then
                      "Untitled"
                    else
                      chapter.title)
            ]
        , img [ id "play-icon"
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
        , case chapter.audio of
            Just audioUrl ->
              audio [ id "background-music"
                    , src ("/static/narrations/" ++
                             (toString chapter.narrationId) ++
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
      div [ id "chapter-container", class (chapterContainerClass model) ]
        [ text "Internal Error: no chapter." ]
