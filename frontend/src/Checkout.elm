module Checkout exposing (..)

import Browser
import Browser.Navigation as Nav
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Http
import Json.Decode as D
import Json.Encode as Encode
import Tuple exposing (..)
import Url
import Url.Parser as P exposing ((</>), Parser, int, oneOf, s, string)
import Utils exposing (..)


type alias Model =
    { pageStatus : Status
    , paymentMode : String
    , cartTotal : Float
    }


type Status
    = Loading
    | Loaded
    | NotLoaded


type Msg
    = CheckoutPressed
    | CheckoutSuccessful (Result Http.Error ())
    | AmountLoaded (Result Http.Error Float)
    | FetchAmount
    | PaymentModeSelected String


init : Model
init =
    Model NotLoaded "Cash" 0


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CheckoutPressed ->
            ( model, tryCheckout model.paymentMode )

        CheckoutSuccessful _ ->
            ( model, Cmd.none )

        AmountLoaded res ->
            case res of
                Ok v ->
                    ( { model | cartTotal = v }, Cmd.none )

                Err _ ->
                    ( { model | pageStatus = NotLoaded }, Cmd.none )

        FetchAmount ->
            let
                _ =
                    Debug.log "err" "fetching checkout amount"
            in
            ( { model | pageStatus = Loading }, fetchAmount )

        PaymentModeSelected s ->
            ( { model | paymentMode = s }, Cmd.none )


fetchAmount : Cmd Msg
fetchAmount =
    Http.riskyRequest
        { method = "GET"
        , headers = []
        , url = "http://127.0.0.1:7878/cart/total"
        , body = Http.emptyBody
        , expect = Http.expectJson AmountLoaded D.float
        , timeout = Nothing
        , tracker = Nothing
        }


tryCheckout : String -> Cmd Msg
tryCheckout pm =
    Http.riskyRequest
        { method = "POST"
        , headers = []
        , url = "http://127.0.0.1:7878/transaction/checkout"
        , body = Http.stringBody "application/json" pm
        , expect = Http.expectWhatever CheckoutSuccessful
        , timeout = Nothing
        , tracker = Nothing
        }


viewStatus : Status -> String
viewStatus s =
    case s of
        Loading ->
            "Loading"

        Loaded ->
            "Ready!"

        NotLoaded ->
            "Not loaded ..."


view : Model -> Html Msg
view model =
    case model.pageStatus of
        Loading ->
            div [] [ text <| viewStatus Loading ]

        _ ->
            div []
                [ div [] [ text <| String.fromFloat <| model.cartTotal ]
                , select []
                    [ option [ onInput PaymentModeSelected ] [ text "Cash" ]
                    , option [ onInput PaymentModeSelected ] [ text "Debit Card" ]
                    , option [ onInput PaymentModeSelected ] [ text "Credit Card" ]
                    ]
                , div [] [ a [ href "/cart" ] [ text "Cancel" ] ]
                , div [] [ button [ onClick CheckoutPressed ] [ text "Confirm and Pay" ] ]
                ]
