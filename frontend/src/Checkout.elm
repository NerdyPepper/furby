module Checkout exposing (..)

import Browser
import Browser.Navigation as Nav
import Css exposing (..)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Http
import Json.Decode as D
import Json.Encode as Encode
import Styles exposing (..)
import Tuple exposing (..)
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
    | CheckedOut


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
            ( { model | pageStatus = CheckedOut }, Cmd.none )

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

        CheckedOut ->
            "Checked out!"


view : Model -> Html Msg
view model =
    case model.pageStatus of
        Loading ->
            div [] [ text <| viewStatus Loading ]

        _ ->
            div
                [ css
                    [ margin auto
                    , marginTop (pct 5)
                    , Css.width (pct 40)
                    ]
                ]
                [ div [ css [ bigHeading, marginBottom (px 20) ] ] [ text "Checkout" ]
                , div [ css [ cardSupportingText ] ] [ text "Your total is" ]
                , div
                    [ css [ bigHeading, fontWeight bold, marginBottom (px 20) ] ]
                    [ text <| (++) "₹ " <| String.fromFloat <| model.cartTotal ]
                , div [ css [ cardSupportingText ] ] [ text "Select a payment mode" ]
                , div [] [ furbyRadio "Cash" (PaymentModeSelected "Cash") ]
                , div [] [ furbyRadio "Debit Card" (PaymentModeSelected "Debit Card") ]
                , div [] [ furbyRadio "Credit Card" (PaymentModeSelected "Credit Card") ]
                , div
                    []
                    [ div
                        [ css [ float left, Css.width (pct 40), margin (px 15) ] ]
                        [ furbyButton [ style "width" "100%" ] [ a [ href "/cart" ] [ text "Cancel" ] ] ]
                    , div
                        [ css [ float left, Css.width (pct 40), margin (px 15) ] ]
                        [ furbyButton [ onClick CheckoutPressed, style "width" "100%" ] [ text "Confirm and Pay" ] ]
                    ]
                ]
