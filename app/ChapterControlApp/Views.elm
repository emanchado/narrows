module ChapterControlApp.Views exposing (..)

import Html exposing (Html, main_, h1, h2, h3, nav, section, img, div, ul, li, textarea, input, button, label, a, strong, em, text)
import Html.Attributes exposing (id, class, href, type_, value, disabled, checked, rows, cols, src)
import Html.Events exposing (onInput, onClick, onCheck)
import Common.Models exposing (Character, FullCharacter, Narration, NarrationStatus(..), loadingPlaceholderChapter)
import Common.Views exposing (messageThreadInteractionView, breadcrumbNavView, bannerView)
import ChapterControlApp.Messages exposing (..)
import ChapterControlApp.Models exposing (Model, ChapterInteractions)


recipientView : List Int -> FullCharacter -> Html Msg
recipientView currentRecipients character =
  label []
    [ input [ type_ "checkbox"
            , value (toString character.id)
            , checked (List.any (\r -> r == character.id) currentRecipients)
            , onCheck (UpdateNewMessageRecipient character.id)
            ]
        []
    , text character.name
    ]


recipientListView : List FullCharacter -> List Int -> Html Msg
recipientListView possibleRecipients currentRecipients =
  div [ class "recipients" ]
    (List.append
       [ label [] [ text "Recipients:" ] ]
       (List.map (recipientView currentRecipients) possibleRecipients))


mainView : Model -> Html Msg
mainView model =
  let
    ( chapter, messageThreads ) =
      case model.interactions of
        Just interactions -> ( interactions.chapter
                             , interactions.messageThreads
                             )
        Nothing -> ( loadingPlaceholderChapter
                   , []
                   )
    narration =
      case model.narration of
        Just narration -> narration
        Nothing -> { id = 0
                   , title = "…"
                   , status = Active
                   , characters = []
                   , defaultAudio = Nothing
                   , defaultBackgroundImage = Nothing
                   , files =
                       { audio = []
                       , backgroundImages = []
                       , images = []
                       }
                   }
  in
    main_ [ id "narrator-app", class "app-container" ]
      [ div [ class "reaction-header" ]
          [ div []
              [ breadcrumbNavView
                  NavigateTo
                  [ { title = "Home"
                    , url = "/"
                    }
                  , { title = narration.title
                    , url = "/narrations/" ++ (toString chapter.narrationId)
                    }
                  , { title = chapter.title
                    , url = "/chapters/" ++ (toString chapter.id) ++ "/edit"
                    }
                  ]
                  (text "Reaction")
              , h1 [] [ text <| chapter.title ]
              ]
          , div []
              [ img [ class "tiny-image-preview"
                    , src (case chapter.backgroundImage of
                             Just image -> "/static/narrations/"
                             ++ (toString chapter.narrationId)
                             ++ "/background-images/"
                             ++ image
                             Nothing -> "/img/no-preview.png")
                    ]
                  []
              ]
          ]
      , bannerView model.banner
      , div [ class "two-column" ]
          [ section []
              [ h2 [] [ text "Chapter text" ]
              , div
                  [ id "chapter-text"
                  , class "chapter"
                  ]
                  []
              ]
          , section []
              [ h2 [] [ text "Messages" ]
              , ul [ class "thread-list narrator" ]
                  (List.map
                      (\mt ->
                          messageThreadInteractionView
                              Nothing
                              (ShowReply mt.participants)
                              UpdateReplyText
                              SendReply
                              CloseReply
                              model.reply
                              model.replySending
                              mt)
                      messageThreads)
              , div [ class "new-message" ]
                  [ h3 [] [ text "New message" ]
                  , textarea [ rows 10
                             , onInput UpdateNewMessageText
                             , value model.newMessageText
                             ]
                      [ text model.newMessageText ]
                  ]
              , recipientListView chapter.participants model.newMessageRecipients
              , div [ class "btn-bar" ]
                  [ button [ class "btn btn-default"
                           , onClick SendMessage
                           , disabled model.newMessageSending
                           ]
                      [ text "Send" ]
                  ]
              ]
          ]
      ]
