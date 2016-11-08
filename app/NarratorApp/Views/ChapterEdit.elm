module NarratorApp.Views.ChapterEdit exposing (..)

import Html exposing (Html, h2, div, main', nav, section, aside, ul, li, img, a, input, button, text)
import Html.Attributes exposing (id, class, href, src, target, type', value, placeholder, checked, disabled)
import Html.Events exposing (onClick, onInput)
import Json.Encode

import NarratorApp.Models exposing (Model, Chapter, Character, Narration)
import NarratorApp.Messages exposing (..)

fakeChapter : Chapter
fakeChapter =
  { id = 0
  , narrationId = 0
  , title = ""
  , audio = ""
  , backgroundImage = ""
  , text = Json.Encode.list []
  , participants = []
  , published = Nothing
  }

fakeNarration : Narration
fakeNarration =
  { id = 0
  , title = ""
  , characters = []
  , defaultAudio = Nothing
  , defaultBackgroundImage = Nothing
  , files = { audio = []
            , backgroundImages = []
            , images = []
            }
  }

participantView : Character -> Html Msg
participantView character =
  li []
    [ a [ href ("/read/" ++ "1" ++ character.token)
        , target "_blank"
        ]
        [ text character.name ]
    , img [ src "/img/delete.png"
          , onClick (RemoveParticipant character)
          ]
        []
    ]

nonParticipantView : Character -> Html Msg
nonParticipantView character =
  li []
    [ text character.name
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

--   <ul>
--     ${ chapter.participants.map(p => html`
--         <li><a href="/read/${ chapter.id }/${ p.token }">${ p.name }</a>
--         <img onclick=${ () => send("removeParticipant", { characterId: p.id }) } src="/img/delete.png" /></li>
--       `) }
--   </ul>


chapterView : Chapter -> Narration -> Html Msg
chapterView chapter narration =
  div [ id "narrator-app" ]
    [ nav []
        [ a [ href ("/narrations/" ++ (toString chapter.narrationId)) ]
            [ text "Narration" ]
        , text " ⇢ "
        , text chapter.title
        ]
    , main' [ class "page-aside" ]
        [ section []
            [ input [ class "chapter-title"
                    , type' "text"
                    , placeholder "Title"
                    , value chapter.title
                    , onInput UpdateChapterTitle
                    ]
                []
            , div [ id "editor-container" ] []
            -- , addImageView
            -- , markForCharacter
            , div [ class "btn-bar" ]
                [ button [ class "btn"
                         , onClick SaveChapter
                         ]
                    [ text "Save" ]
                , button [ class "btn btn-default"
                         -- , onClick PublishChapter
                         ]
                    [ text "Publish" ]
                ]
            ]
        , aside []
            [ div [ class "participants" ]
                [ h2 [] [ text "Participants" ]
                , participantListView narration.characters chapter.participants
                ]
            ]
        ]
    ]


view : Model -> Html Msg
view model =
  let
    chapter = case model.chapter of
                Just chapter -> chapter
                Nothing -> fakeChapter
    narration = case model.narration of
                  Just narration -> narration
                  Nothing -> fakeNarration
  in
    chapterView chapter narration
