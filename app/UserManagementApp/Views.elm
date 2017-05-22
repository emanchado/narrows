module UserManagementApp.Views exposing (..)

import Html exposing (Html, main_, aside, h1, h2, div, form, input, label, button, ul, li, a, strong, text)
import Html.Attributes exposing (id, class, href, type_, placeholder, value, checked, for)
import Html.Events exposing (onInput, onClick, onCheck, onSubmit)
import Common.Models exposing (UserInfo)
import Common.Views exposing (bannerView)
import UserManagementApp.Messages exposing (..)
import UserManagementApp.Models exposing (..)


userView : Maybe UserChanges -> UserInfo -> Html Msg
userView maybeUserChanges user =
    let
        userLabel =
            div [ class "user-label" ]
                (if user.role == "admin" then
                    [ strong [] [ text user.email ]
                    , text " (admin)"
                    ]
                 else
                    [ text user.email ]
                )

        ( isSelected, password, isAdmin ) =
            case maybeUserChanges of
                Just userChanges ->
                    ( userChanges.userId == user.id, userChanges.password, userChanges.isAdmin )

                Nothing ->
                    ( False, "", False )
    in
        li [ class "user" ]
            [ if isSelected then
                div [ class "expanded-user" ]
                    [ userLabel
                    , form [ onSubmit SaveUser ]
                        [ div [ class "form-line" ]
                            [ label [ for "password" ] [ text "Password: " ]
                            , input
                                [ id "password"
                                , type_ "password"
                                , onInput UpdatePassword
                                , value password
                                ]
                                []
                            ]
                        , div [ class "form-line" ]
                            [ label [ for "is-admin" ] [ text "Admin?" ]
                            , input
                                [ id "is-admin"
                                , type_ "checkbox"
                                , onCheck UpdateIsAdmin
                                , checked isAdmin
                                ]
                                []
                            ]
                        , div [ class "btn-bar" ]
                            [ button
                                [ class "btn btn-default"
                                , type_ "submit"
                                ]
                                [ text "Save" ]
                            , button
                                [ class "btn"
                                , onClick UnselectUser
                                ]
                                [ text "Cancel" ]
                            ]
                        ]
                    ]
              else
                div []
                    [ userLabel
                    , div [ class "btn-bar" ]
                        [ button
                            [ class "btn"
                            , onClick (SelectUser user.id)
                            ]
                            [ text "Edit" ]
                        ]
                    ]
            ]


userListView : Maybe (List UserInfo) -> Maybe UserChanges -> Html Msg
userListView maybeUsers maybeUserChanges =
    case maybeUsers of
        Just users ->
            ul [ class "user-list" ]
                (List.map (userView maybeUserChanges) users)

        Nothing ->
            text "Loading users…"


mainView : Model -> Html Msg
mainView model =
    main_
        [ id "narrator-app"
        , class "app-container app-container-simple"
        ]
        [ h1 [] [ text "Users" ]
        , bannerView model.banner
        , userListView model.users model.userUi
        , form
            [ class "create-form"
            , onSubmit SaveNewUser
            ]
            [ h2 [] [ text "Create new user" ]
            , div [ class "form-line" ]
                [ label [ for "new-user-email" ] [ text "E-mail: " ]
                , input
                    [ id "new-user-email"
                    , type_ "email"
                    , placeholder "user@example.com"
                    , value model.newUserEmail
                    , onInput UpdateNewUserEmail
                    ]
                    []
                ]
            , div [ class "form-line" ]
                [ label [ for "new-user-is-admin" ] [ text "Admin? " ]
                , input
                    [ id "new-user-is-admin"
                    , type_ "checkbox"
                    , checked model.newUserIsAdmin
                    , onCheck UpdateNewUserIsAdmin
                    ]
                    []
                ]
            , div [ class "btn-bar" ]
                [ button
                    [ class "btn btn-default"
                    , type_ "submit"
                    ]
                    [ text "New user" ]
                ]
            ]
        ]
