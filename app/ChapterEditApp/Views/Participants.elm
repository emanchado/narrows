module ChapterEditApp.Views.Participants exposing (participantListView, participantPreviewsView)

import Html exposing (Html, div, ul, li, img, label, a, s, text)
import Html.Attributes exposing (class, href, src, target)
import Html.Events exposing (onClick)
import Common.Models exposing (FullCharacter)
import ChapterEditApp.Messages exposing (..)


participantView : Int -> FullCharacter -> Html Msg
participantView chapterId character =
  li []
    [ text character.name
    , text " "
    , img [ src "/img/delete.png"
          , onClick (RemoveParticipant character)
          ]
        []
    ]


nonParticipantView : FullCharacter -> Html Msg
nonParticipantView character =
  li []
    [ s [] [ text character.name ]
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

    participantItems =
      List.map (participantView chapterId) currentParticipants

    nonParticipantItems =
      List.map nonParticipantView nonParticipants
  in
    ul [ class "participant-list" ]
      (List.append participantItems nonParticipantItems)


characterPreviewView : Int -> FullCharacter -> Html Msg
characterPreviewView chapterId character =
  a [ href <| "/read/" ++ (String.fromInt chapterId) ++ "/" ++ character.token
    , target "_blank"
    , class "btn btn-small"
    ]
    [ text character.name
    , text " "
    , div [ class <| "mention-square mention-" ++ (String.fromInt <| (modBy 5 character.id) + 1)
          ]
        []
    ]


participantPreviewsView : Int -> List FullCharacter -> Html Msg
participantPreviewsView chapterId currentParticipants =
  div [ class "btn-bar btn-bar-extra"
      ] <|
    (List.append
       [ label [] [ text "Preview as:" ] ]
       (List.map (characterPreviewView chapterId) currentParticipants))
