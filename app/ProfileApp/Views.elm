module ProfileApp.Views exposing (..)

import Html exposing (Html, main_, aside, h1, h2, div, form, input, label, button, a, strong, text)
import Html.Attributes exposing (id, class, href, type_, placeholder, value, checked, for)
import Html.Events exposing (onInput, onClick, onCheck, onSubmit)
import Common.Models exposing (UserInfo)
import Common.Views exposing (bannerView)
import ProfileApp.Messages exposing (..)
import ProfileApp.Models exposing (..)


userView : UserInfo -> String -> Html Msg
userView user password =
  let
    userLabel = div [ class "user-label" ]
                  (if user.role == "admin" then
                     [ strong [] [ text user.email ]
                     , text " (admin)"
                     ]
                   else
                     [ text user.email ])
  in
    div [ class "user" ]
      [ userLabel
      , form [ class "narrow-form vertical-form"
             , onSubmit SaveUser
             ]
          [ div [ class "form-line" ]
              [ label [ for "password" ] [ text "New password" ]
              , input [ id "password"
                      , type_ "password"
                      , onInput UpdatePassword
                      , value password
                      ]
                  []
              ]
          , div [ class "btn-bar" ]
              [ button [ type_ "submit"
                       , class "btn btn-default"
                       , onClick SaveUser
                       ]
                  [ text "Save" ]
              ]
          ]
      ]


mainView : Model -> Html Msg
mainView model =
  main_ [ id "narrator-app"
        , class "app-container app-container-simple"
        ]
    [ h1 [] [ text "Profile" ]
    , bannerView model.banner
    , case model.user of
        Just user -> userView user model.newPassword
        Nothing -> text "Loading…"
    ]
