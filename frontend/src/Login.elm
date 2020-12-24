module Login exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Encode as Encode
import Url
import Url.Parser as P exposing ((</>), Parser, int, oneOf, s, string)


type alias Model =
    { username : String
    , password : String
    , loginStatus : LoginStatus
    }


type LoginStatus
    = NotLoggedIn
    | LoggedIn
    | InvalidLogin
    | LoggingIn


type Msg
    = PassEntered String
    | UserEntered String
    | LoginPressed
    | LoginSuccess (Result Http.Error ())
    | LoginFail


init : Model
init =
    Model "" "" NotLoggedIn


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PassEntered s ->
            ( { model | password = s }
            , Cmd.none
            )

        UserEntered s ->
            ( { model | username = s }
            , Cmd.none
            )

        LoginPressed ->
            ( { model | loginStatus = LoggingIn }, tryLogin model )

        LoginSuccess res ->
            case res of
                Ok s ->
                    ( { model | loginStatus = LoggedIn }, Cmd.none )

                Err e ->
                    ( { model | loginStatus = InvalidLogin }, Cmd.none )

        LoginFail ->
            ( { model | loginStatus = InvalidLogin }, Cmd.none )


encodeLogin : Model -> Encode.Value
encodeLogin model =
    Encode.object
        [ ( "username", Encode.string model.username )
        , ( "password", Encode.string model.password )
        ]


tryLogin : Model -> Cmd Msg
tryLogin model =
    Http.riskyRequest
        { method = "POST"
        , headers = []
        , url = "http://127.0.0.1:7878/user/login"
        , body = model |> encodeLogin |> Http.jsonBody
        , expect = Http.expectWhatever LoginSuccess
        , timeout = Nothing
        , tracker = Nothing
        }


viewStatus : LoginStatus -> String
viewStatus ls =
    case ls of
        NotLoggedIn ->
            "Not Logged In"

        InvalidLogin ->
            "Invalid Login"

        LoggedIn ->
            "Logged in!"

        LoggingIn ->
            "Logging In ..."


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input [ type_ t, placeholder p, value v, onInput toMsg ] []


view : Model -> Html Msg
view model =
    div []
        [ div [] [ viewInput "text" "Enter name here" model.username UserEntered ]
        , div [] [ viewInput "password" "Password" model.password PassEntered ]
        , div [] [ button [ onClick LoginPressed ] [ text "Login" ] ]
        , div [] [ text (viewStatus model.loginStatus) ]
        , div [] [ text "Don't have an account? ", a [ href "/signup" ] [ text "Register now!" ] ]
        ]
