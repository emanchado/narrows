module NarratorApp.Views.Participants exposing (participantListView)

import Html exposing (Html, ul, li, img, a, text)
import Html.Attributes exposing (href, src, target)
import Html.Events exposing (onClick)

import NarratorApp.Models exposing (Character)
import NarratorApp.Messages exposing (..)

participantView : Character -> Html Msg
participantView character =
  li []
    [ a [ href ("/read/" ++ "1" ++ character.token)
        , target "_blank"
        ]
        [ text character.name ]
    , text " "
    , img [ src "/img/delete.png"
          , onClick (RemoveParticipant character)
          ]
        []
    ]

nonParticipantView : Character -> Html Msg
nonParticipantView character =
  li []
    [ text character.name
    , text " "
    , img [ src "/img/add.png"
          , onClick (AddParticipant character)
          ]
        []
    ]

participantListView : List Character -> List Character -> Html Msg
participantListView allCharacters currentParticipants =
  let
    nonParticipants =
      List.filter (\c -> not (List.member c currentParticipants)) allCharacters

    participantItems = List.map participantView currentParticipants

    nonParticipantItems = List.map nonParticipantView nonParticipants
  in
    ul []
      (List.append participantItems nonParticipantItems)
