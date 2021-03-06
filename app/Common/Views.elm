module Common.Views exposing (..)

import String
import Regex
import Json.Decode
import ISO8601
import Http

import Html exposing (Html, h2, div, nav, textarea, button, span, ul, li, img, a, em, strong, text)
import Html.Attributes exposing (class, rows, value, disabled, href, src, width, height, alt, title)
import Html.Events exposing (onClick, onInput, preventDefaultOn, stopPropagationOn)
import Common.Models exposing (MessageThread, Message, Banner, ReplyInformation, Breadcrumb, ChapterOverview, Narration, NarrationOverview, NarrationStatus(..), narrationStatusString, toUtcString)


onPreventDefaultClick : msg -> Html.Attribute msg
onPreventDefaultClick message =
  preventDefaultOn "click"
    (Json.Decode.map (\m -> (m, True)) (Json.Decode.succeed message))


onStopPropagationClick : msg -> Html.Attribute msg
onStopPropagationClick message =
  stopPropagationOn "click"
    (Json.Decode.map (\m -> (m, True)) (Json.Decode.succeed message))


-- This regex cannot have capture groups, as they trigger a very weird
-- bug in Regex.split.
linkRegex : Maybe Regex.Regex
linkRegex = Regex.fromStringWith
              { caseInsensitive = True
              , multiline = False
              } <|
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
  case linkRegex of
    Just regex ->
      let
        links =
          List.map
            (\{match} -> a [ href match ] [ text match ])
            <| Regex.find regex message
        textChunks =
          List.map
            text
            <| Regex.split regex message
      in
        interleave links textChunks
    Nothing ->
      [ text message ]


characterInitials : String -> String
characterInitials name =
  String.join "" <|
    List.take 2 <|
      List.map
        (\word -> String.left 1 word)
        (String.words name)


formatError : Http.Error -> String
formatError httpError =
  case httpError of
    Http.BadStatus status ->
      "Got status " ++ (String.fromInt status)
    _ ->
      "Unknown network error"


type AvatarSize
  = Small
  | Normal


characterAvatarView : Int -> AvatarSize -> { a | name : String, avatar : Maybe String } -> Html msg
characterAvatarView narrationId avatarSize character =
  let
    (size, sizeClassPostfix) = case avatarSize of
                                 Small -> (50, " small")
                                 Normal -> (100, "")
  in
    case character.avatar of
      Just avatar ->
        img [ class <| "avatar" ++ sizeClassPostfix
            , src <| "/static/narrations/" ++ (String.fromInt narrationId) ++ "/avatars/" ++ avatar
            , alt character.name
            , title character.name
            , width size
            , height size
            ]
          []
      Nothing ->
        div [ class <| "avatar placeholder" ++ sizeClassPostfix
            , title character.name
            ]
          [ text <| characterInitials character.name
          ]


humanTimeDifference : Int -> String
humanTimeDifference timeDifference =
  let
    secondsDifference = timeDifference // 1000
    minutesDifference = secondsDifference // 60
    hoursDifference = minutesDifference // 60
    daysDifference = hoursDifference // 24
    weeksDifference = daysDifference // 7
  in
    if secondsDifference < 0 then
      "unknown"
    else if secondsDifference < 60 then
      "less than one minute ago"
    else if minutesDifference < 2 then
      "one minute ago"
    else if minutesDifference < 60 then
      (String.fromInt <| minutesDifference) ++ " minutes ago"
    else if hoursDifference < 2 then
      "one hour ago"
    else if hoursDifference < 24 then
      (String.fromInt <| hoursDifference) ++ " hours ago"
    else if daysDifference < 2 then
      "one day ago"
    else if daysDifference < 7 then
      (String.fromInt <| daysDifference) ++ " days ago"
    else
      (String.fromInt <| weeksDifference) ++ " weeks ago"


messageView : Int -> Message -> Html msg
messageView nowMilliseconds message =
  let
    sentAtPosix = ISO8601.toPosix message.sentAt
    sentAtMilliseconds = ISO8601.toTime message.sentAt
    timeDifference = nowMilliseconds - sentAtMilliseconds
  in
    div [ class "message" ]
      [ strong [ title <| (humanTimeDifference timeDifference) ++ " – " ++ (toUtcString sentAtPosix) ]
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


messageThreadInteractionView : Int -> msg -> (String -> msg) -> msg -> msg -> Maybe ReplyInformation -> Bool -> Int -> MessageThread -> Html msg
messageThreadInteractionView narrationId showReplyMessage updateReplyMessage sendReplyMessage closeReplyMessage maybeReply replyButtonDisabled nowMilliseconds thread =
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
    messageThreadView narrationId [ replyBoxDiv ] nowMilliseconds thread


messageThreadView : Int -> List (Html msg) -> Int -> MessageThread -> Html msg
messageThreadView narrationId extraUi nowMilliseconds thread =
  let
    participantAvatars =
      List.intersperse
        (text " ")
        (List.map
           (characterAvatarView narrationId Small)
           (List.sortBy .id thread.participants))

    participantsDiv =
      div [ class "thread-participants" ] <|
        participantAvatars
  in
    li []
      (List.concat
        [ [ participantsDiv ]
        , List.map (messageView nowMilliseconds) thread.messages
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


breadcrumbView : Breadcrumb -> Html msg
breadcrumbView link =
  a [ href link.url ]
    [ text link.title ]


breadcrumbNavView : List Breadcrumb -> Html msg -> Html msg
breadcrumbNavView links pageTitle =
  let
    parts =
      List.concat
        [ (List.map breadcrumbView links)
        , [ pageTitle ]
        ]
  in
    nav [ class "breadcrumbs" ]
      (List.intersperse
        (text " ⇢ ")
        parts)


sanitizedTitle : String -> String
sanitizedTitle title =
  if String.isEmpty <| String.trim title then
    "Untitled"
  else
    title


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
      [ a [ href <| "/chapters/" ++ (String.fromInt chapterOverview.id) ++ "/edit" ]
          [ text <| sanitizedTitle chapterOverview.title ]
      , em [] [ text "Draft" ]
      , if numberNarrationCharacters /= numberChapterParticipants then
          span [ title <| "Only for " ++ participantNames ]
            [ text " — "
            , img [ src "/img/character.png" ] []
            , text <| String.fromInt numberChapterParticipants
            ]
        else
          text ""
      ]


publishedChapterView : Bool -> (String -> msg) -> Narration -> ChapterOverview -> Html msg
publishedChapterView compact navigationMessage narration chapterOverview =
  let
    numberSentReactions = List.length chapterOverview.activeUsers
    numberChapterParticipants = List.length chapterOverview.participants
    numberNarrationCharacters = List.length narration.characters
    participantNames = String.join ", " <|
        List.map
          (\r -> r.name)
          chapterOverview.participants
    reactionsMissingTitle =
      (String.fromInt <| numberChapterParticipants - numberSentReactions)
      ++ " reaction(s) missing"
  in
    li []
      [ a [ href <| "/chapters/" ++ (String.fromInt chapterOverview.id) ]
          [ text <| sanitizedTitle chapterOverview.title
          ]
      , div []
          (List.intersperse (text " — ") <|
             List.concat
               [ if numberSentReactions /= numberChapterParticipants then
                   [ span (if compact then [ title reactionsMissingTitle ]
                           else [])
                       [ text <|
                           (String.fromInt <| numberChapterParticipants - numberSentReactions)
                           ++ (if compact then "" else " reaction(s)")
                           ++ " missing"
                       ]
                   ]
                 else
                   []
               , if not compact && numberNarrationCharacters /= numberChapterParticipants then
                   [ span []
                       [ span [ title <| "Only for " ++ participantNames ]
                           [ img [ src "/img/character.png" ] []
                           , text <| String.fromInt numberChapterParticipants
                           ]
                       ]
                   ]
                 else
                   []
               , if not compact && chapterOverview.numberMessages > 0 then
                   [ span [ class "message-counter" ]
                       [ img [ src "/img/envelope.png" ] []
                       , text <| String.fromInt chapterOverview.numberMessages
                       ]
                   ]
                 else
                   []
               ])
      ]


chapterOverviewView : Bool -> (String -> msg) -> Narration -> ChapterOverview -> Html msg
chapterOverviewView compact navigationMessage narration chapterOverview =
  case chapterOverview.published of
    Just published ->
      publishedChapterView compact navigationMessage narration chapterOverview
    Nothing ->
      unpublishedChapterView navigationMessage narration chapterOverview


narrationOverviewView : Bool -> (String -> msg) -> NarrationOverview -> List (Html msg)
narrationOverviewView compact navigationMessage narrationOverview =
  (List.map
     (chapterOverviewView compact navigationMessage narrationOverview.narration)
     narrationOverview.chapters)


ribbonForNarrationStatus : NarrationStatus -> Html msg
ribbonForNarrationStatus status =
  let
    statusString = narrationStatusString status
  in
    case status of
      Active ->
        text ""
      _ ->
        div [ class <| "corner-ribbon top-right corner-ribbon-" ++ statusString ]
          [ text statusString ]


compactNarrationView : (String -> msg) -> NarrationOverview -> Html msg
compactNarrationView navigationMessage overview =
  let
    ribbon = ribbonForNarrationStatus overview.narration.status
    buttonBar =
      case overview.narration.status of
        Active ->
          button [ class "btn btn-add"
                 , onClick (navigationMessage <| "/narrations/" ++ (String.fromInt overview.narration.id) ++ "/new")
                 ]
            [ text "New chapter" ]
        _ ->
          text ""
  in
    div [ class "narration-container" ]
      [ ribbon
      , div [ class "narration-header" ]
          [ h2 []
            [ a [ href <| "/narrations/" ++ (String.fromInt overview.narration.id) ]
                [ text overview.narration.title ]
            ]
          , buttonBar
          ]
      , ul [ class "chapter-list chapter-list-compact" ] <|
          narrationOverviewView True navigationMessage overview
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
