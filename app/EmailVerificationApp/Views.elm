module EmailVerificationApp.Views exposing (..)

import Html exposing (Html, main_, h1, code, span, a, text)
import Html.Attributes exposing (id, class, href)

import EmailVerificationApp.Messages exposing (..)
import EmailVerificationApp.Models exposing (..)

mainView : Model -> Html Msg
mainView model =
  main_ [ id "narrator-app"
        , class "app-container app-container-simple"
        ]
    [ h1 [] [ text "Email verification" ]
    , if model.checking then
        text "Checking token…"
      else
        case model.error of
          Just error ->
            span []
              [ text "Could not verify email address with token "
              , code [] [ text model.token ]
              , text ": "
              , text error.text
              , text "."
              ]
          Nothing ->
            span []
              [ text "Verification successful! Now you can continue to the "
              , a [ href "/" ]
                  [ text "front page" ]
              , text "."
              ]
    ]
