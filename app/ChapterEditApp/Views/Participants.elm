module ChapterEditApp.Views.Participants exposing (participantListView)

import Html exposing (Html, ul, li, img, a, text)
import Html.Attributes exposing (href, src, target)
import Html.Events exposing (onClick)

import Common.Models exposing (FullCharacter)
import ChapterEditApp.Messages exposing (..)

participantView : Int -> FullCharacter -> Html Msg
participantView chapterId character =
  li []
    [ a [ href ("/read/" ++ (toString chapterId) ++ "/" ++ character.token)
        , target "_blank"
        ]
        [ text character.name ]
    , text " "
    , img [ src "/img/delete.png"
          , onClick (RemoveParticipant character)
          ]
        []
    ]

nonParticipantView : FullCharacter -> Html Msg
nonParticipantView character =
  li []
    [ text character.name
    , text " "
    , img [ src "/img/add.png"
          , onClick (AddParticipant character)
          ]
        []
    ]

participantListView : Int -> List FullCharacter -> List FullCharacter -> Html Msg
participantListView chapterId allCharacters currentParticipants =
  let
    nonParticipants =
      List.filter (\c -> not (List.member c currentParticipants)) allCharacters

    participantItems = List.map (participantView chapterId) currentParticipants

    nonParticipantItems = List.map nonParticipantView nonParticipants
  in
    ul []
      (List.append participantItems nonParticipantItems)
