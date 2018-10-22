module Common.Views exposing (..)

import String
import Regex exposing (HowMany(All), regex, caseInsensitive)
import Json.Decode
import Html exposing (Html, h2, div, nav, textarea, button, span, ul, li, img, a, em, strong, text)
import Html.Attributes exposing (class, rows, value, disabled, href, src, title)
import Html.Events exposing (defaultOptions, onWithOptions, onClick, onInput)
import Common.Models exposing (MessageThread, Message, Banner, ReplyInformation, Breadcrumb, ChapterOverview, Narration, NarrationOverview, NarrationStatus(..), narrationStatusString)


onPreventDefaultClick : msg -> Html.Attribute msg
onPreventDefaultClick message =
  onWithOptions
    "click"
    { defaultOptions | preventDefault = True }
    (Json.Decode.succeed message)


onStopPropagationClick : msg -> Html.Attribute msg
onStopPropagationClick message =
  onWithOptions
    "click"
    { defaultOptions | stopPropagation = True }
    (Json.Decode.succeed message)


-- This regex cannot have capture groups, as they trigger a very weird
-- bug in Regex.split.
linkRegex : Regex.Regex
linkRegex = caseInsensitive <| regex <|
            "https?://[a-z0-9.-]+(?::[0-9]+)?" ++       -- Protocol/host
            "(?:/(?:[,.]*[a-z0-9/&%_+-]+)*)?" ++        -- URL path
            "(?:\\?(?:[a-z0-9]*=[a-z0-9%_-]*&?)+)?" ++  -- Query parameters
            "(?:#[a-z0-9_-]*)?"                         -- Anchor


interleave : List a -> List a -> List a
interleave list1 list2 =
  case list1 of
    []      -> list2
    x :: xs ->
      case list2 of
        []      -> list1
        y :: ys -> y :: x :: interleave xs ys


linkify : String -> List (Html msg)
linkify message =
   let
     links =
       List.map
         (\{match} -> a [ href match ] [ text match ])
         <| Regex.find All linkRegex message
     textChunks =
       List.map
         text
         <| Regex.split All linkRegex message
   in
     interleave links textChunks


messageView : Message -> Html msg
messageView message =
  div [ class "message" ]
    [ strong []
        [ text (case message.sender of
                  Just sender -> sender.name
                  Nothing -> "Narrator")
        ]
    , text ": "
    , span [ class (case message.sender of
                      Just sender -> ""
                      Nothing -> "narrator")
           ]
        (linkify message.body)
    ]


messageThreadInteractionView : Maybe Int -> msg -> (String -> msg) -> msg -> msg -> Maybe ReplyInformation -> Bool -> MessageThread -> Html msg
messageThreadInteractionView maybeCharacterId showReplyMessage updateReplyMessage sendReplyMessage closeReplyMessage maybeReply replyButtonDisabled thread =
  let
    replyButtonDiv =
      div [ class "btn-bar" ]
        [ button [ class "btn btn-small"
                 , onClick showReplyMessage
                 ]
            [ text "Reply" ]
        ]

    replyBoxDiv =
      case maybeReply of
        Just reply ->
          if reply.recipients == thread.participants then
            div []
              [ textarea [ rows 4
                         , value reply.body
                         , onInput updateReplyMessage
                         ]
                  [ text reply.body ]
              , div [ class "btn-bar" ]
                  [ button [ class "btn btn-default btn-small"
                           , onClick sendReplyMessage
                           , disabled replyButtonDisabled
                           ]
                      [ text "Send" ]
                  , button [ class "btn btn-small"
                           , onClick closeReplyMessage
                           ]
                      [ text "Close" ]
                  ]
              ]
          else
            replyButtonDiv

        Nothing ->
          replyButtonDiv
  in
    messageThreadView maybeCharacterId [ replyBoxDiv ] thread


messageThreadView : Maybe Int -> List (Html msg) -> MessageThread -> Html msg
messageThreadView maybeCharacterId extraUi thread =
  let
    participants =
      List.map
        (\c -> c.name)
        (case maybeCharacterId of
          Just characterId ->
            List.filter (\c -> c.id /= characterId) thread.participants
          Nothing ->
            thread.participants)

    participantString =
      String.join ", " participants

    participantStringEnd =
      case maybeCharacterId of
        Nothing ->
          if List.length participants > 1 then
            ", and you"
          else
            " and you"

        Just _ ->
          if List.length participants > 0 then
            ", the narrator, and you"
          else
            "the narrator and you"

    participantsDiv =
      div [ class "thread-participants" ]
        [ text ("Between " ++ participantString ++ participantStringEnd) ]
  in
    li []
      (List.concat
        [ [ participantsDiv ]
        , List.map messageView thread.messages
        , extraUi
        ])


loadingView : Maybe Banner -> Html msg
loadingView maybeBanner =
  div []
    [ bannerView maybeBanner
    , text "Loading…"
    ]


bannerView : Maybe Banner -> Html msg
bannerView maybeBanner =
  case maybeBanner of
    Just banner ->
      div [ class <| "banner banner-" ++ banner.type_ ]
        [ text banner.text ]

    Nothing ->
      text ""


linkTo : (String -> msg) -> String -> List (Html.Attribute msg)
linkTo message url =
  [ href url
  , onPreventDefaultClick (message url)
  ]


breadcrumbView : (String -> msg) -> Breadcrumb -> Html msg
breadcrumbView messageConstructor link =
  a (linkTo messageConstructor link.url)
    [ text link.title ]


breadcrumbNavView : (String -> msg) -> List Breadcrumb -> Html msg -> Html msg
breadcrumbNavView messageConstructor links pageTitle =
  let
    parts =
      List.concat
        [ (List.map (breadcrumbView messageConstructor) links)
        , [ pageTitle ]
        ]
  in
    nav [ class "breadcrumbs" ]
      (List.intersperse
        (text " ⇢ ")
        parts)


unpublishedChapterView : (String -> msg) -> Narration -> ChapterOverview -> Html msg
unpublishedChapterView navigationMessage narration chapterOverview =
  let
    numberChapterParticipants = List.length chapterOverview.participants
    numberNarrationCharacters = List.length narration.characters
    participantNames = String.join ", " <|
        List.map
          (\r -> r.name)
          chapterOverview.participants
  in
    li []
      [ a (linkTo
             navigationMessage
             ("/chapters/" ++ (toString chapterOverview.id) ++ "/edit"))
          [ text chapterOverview.title
          ]
      , text " — "
      , em [] [ text "Draft" ]
      , if numberNarrationCharacters /= numberChapterParticipants then
          span [ title <| "Only for " ++ participantNames ]
            [ text " — "
            , img [ src "/img/character.png" ] []
            , text <| toString numberChapterParticipants
            ]
        else
          text ""
      ]


publishedChapterView : (String -> msg) -> Narration -> ChapterOverview -> Html msg
publishedChapterView navigationMessage narration chapterOverview =
  let
    numberSentReactions = List.length chapterOverview.activeUsers
    numberChapterParticipants = List.length chapterOverview.participants
    numberNarrationCharacters = List.length narration.characters
    participantNames = String.join ", " <|
        List.map
          (\r -> r.name)
          chapterOverview.participants
  in
    li []
      [ a (linkTo
             navigationMessage
             ("/chapters/" ++ (toString chapterOverview.id)))
          [ text chapterOverview.title ]
      , if numberSentReactions /= numberChapterParticipants then
          text (" — "
                ++ (toString <| numberChapterParticipants - numberSentReactions)
                ++ " reaction(s) pending")
        else
          text ""
      , if numberNarrationCharacters /= numberChapterParticipants then
          span [ title <| "Only for " ++ participantNames ]
            [ text " — "
            , img [ src "/img/character.png" ] []
            , text <| toString numberChapterParticipants
            ]
        else
          text ""
      , if chapterOverview.numberMessages > 0 then
          span []
            [ text " — "
            , img [ src "/img/envelope.png" ] []
            , text <| toString chapterOverview.numberMessages
            ]
        else
          text ""
      ]


chapterOverviewView : (String -> msg) -> Narration -> ChapterOverview -> Html msg
chapterOverviewView navigationMessage narration chapterOverview =
  case chapterOverview.published of
    Just published ->
      publishedChapterView navigationMessage narration chapterOverview
    Nothing ->
      unpublishedChapterView navigationMessage narration chapterOverview


narrationOverviewView : (String -> msg) -> NarrationOverview -> List (Html msg)
narrationOverviewView navigationMessage narrationOverview =
  (List.map
     (chapterOverviewView navigationMessage narrationOverview.narration)
     narrationOverview.chapters)


ribbonForNarrationStatus : NarrationStatus -> Html msg
ribbonForNarrationStatus status =
  case status of
    Active ->
      text ""
    _ ->
      div [ class "corner-ribbon top-right" ]
        [ text <| narrationStatusString status ]


compactNarrationView : (String -> msg) -> NarrationOverview -> Html msg
compactNarrationView navigationMessage overview =
  let
    ribbon = ribbonForNarrationStatus overview.narration.status
    buttonBar =
      case overview.narration.status of
        Active ->
          button [ class "btn btn-add"
                 , onClick (navigationMessage <| "/narrations/" ++ (toString overview.narration.id) ++ "/new")
                 ]
            [ text "New chapter" ]
        _ ->
          text ""
  in
    div [ class "narration-container" ]
      [ ribbon
      , div [ class "narration-header" ]
          [ h2 []
            [ a
                (linkTo
                  navigationMessage
                  ("/narrations/" ++ (toString overview.narration.id))
                )
                [ text overview.narration.title ]
            ]
          , buttonBar
          ]
      , ul [ class "chapter-list" ] <|
          narrationOverviewView navigationMessage overview
      ]


horizontalSpinner : Html msg
horizontalSpinner =
  div [ class "spinner" ]
    [ div [ class "bounce1" ] []
    , div [ class "bounce2" ] []
    , div [ class "bounce3" ] []
    ]


showDialog : String -> msg -> String -> msg -> String -> msg -> Html msg
showDialog dialogText noopMessage okText okMessage cancelText cancelMessage =
  div [ class "dialog-overlay"
      , onClick cancelMessage
      ]
    [ div [ class "dialog"
          , onStopPropagationClick noopMessage
          ]
        [ div [ class "dialog-text" ]
            [ text dialogText ]
        , div [ class "btn-bar" ]
            [ button [ class "btn btn-small btn-default"
                     , onClick okMessage
                     ]
                [ text okText ]
            , button [ class "btn btn-small"
                     , onClick cancelMessage
                     ]
                [ text cancelText ]
            ]
        ]
    ]
