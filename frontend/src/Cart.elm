module Cart exposing (..)

import Browser
import Browser.Navigation as Nav
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Http
import Json.Decode as D
import Json.Encode as Encode
import Url
import Url.Parser as P exposing ((</>), Parser, int, oneOf, s, string)


type alias Product =
    { id : Int
    , name : String
    , kind : Maybe String
    , price : Float
    , description : Maybe String
    }


type alias CartListing =
    { productItem : Product
    , quantity : Int
    }


type alias Model =
    { pageStatus : Status
    , products : List CartListing
    }


type Status
    = Loading
    | Loaded
    | NotLoaded


type Msg
    = CartLoaded (Result Http.Error (List CartListing))
    | FetchCartItems
    | RemoveFromCart Int
    | CartItemRemoved (Result Http.Error ())
    | AddToCartSuccess (Result Http.Error ())
    | AddToCartPressed Int


init : Model
init =
    Model NotLoaded []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CartLoaded res ->
            case res of
                Ok s ->
                    ( { model | products = s, pageStatus = Loaded }, Cmd.none )

                Err e ->
                    let
                        _ =
                            Debug.log "error" e
                    in
                    ( { model | pageStatus = NotLoaded }, Cmd.none )

        RemoveFromCart id ->
            ( model, removeProduct id )

        CartItemRemoved _ ->
            ( { model | pageStatus = Loading }, fetchCartItems )

        FetchCartItems ->
            ( { model | pageStatus = Loading }, fetchCartItems )

        AddToCartPressed id ->
            ( model, addToCart id )

        AddToCartSuccess _ ->
            ( { model | pageStatus = Loading }, fetchCartItems )


decodeProduct : D.Decoder Product
decodeProduct =
    D.map5 Product
        (D.field "id" D.int)
        (D.field "name" D.string)
        (D.field "kind" (D.nullable D.string))
        (D.field "price" D.float)
        (D.field "description" (D.nullable D.string))


decodeResponse : D.Decoder (List CartListing)
decodeResponse =
    D.list
        (D.map2 CartListing
            (D.field "product_item" decodeProduct)
            (D.field "quantity" D.int)
        )


removeProduct : Int -> Cmd Msg
removeProduct id =
    let
        _ =
            Debug.log "cart" "fetching cart items"
    in
    Http.riskyRequest
        { method = "POST"
        , headers = []
        , url = "http://127.0.0.1:7878/cart/remove"
        , body = Http.stringBody "application/json" <| String.fromInt id
        , expect = Http.expectWhatever CartItemRemoved
        , timeout = Nothing
        , tracker = Nothing
        }


fetchCartItems : Cmd Msg
fetchCartItems =
    let
        _ =
            Debug.log "cart" "fetching cart items"
    in
    Http.riskyRequest
        { method = "GET"
        , headers = []
        , url = "http://127.0.0.1:7878/cart/items"
        , body = Http.emptyBody
        , expect = Http.expectJson CartLoaded decodeResponse
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


addToCart : Int -> Cmd Msg
addToCart id =
    let
        _ =
            Debug.log "err" <| "adding to cart: " ++ String.fromInt id
    in
    Http.riskyRequest
        { method = "POST"
        , headers = []
        , url = "http://127.0.0.1:7878/cart/add"
        , body = Http.stringBody "applcation/json" <| String.fromInt <| id
        , expect = Http.expectWhatever AddToCartSuccess
        , timeout = Nothing
        , tracker = Nothing
        }


calculateTotal : Model -> Float
calculateTotal model =
    let
        items =
            model.products
    in
    items
        |> List.map (\i -> toFloat i.quantity * i.productItem.price)
        |> List.foldl (+) 0


viewCartItemListing : CartListing -> Html Msg
viewCartItemListing listing =
    div []
        [ text listing.productItem.name
        , div [] [ text <| Maybe.withDefault "" listing.productItem.kind ]
        , div [] [ text <| Maybe.withDefault "" listing.productItem.description ]
        , div [] [ text <| String.fromFloat listing.productItem.price ]
        , div [] [ text <| String.fromInt listing.quantity ]
        , div [] [ button [ onClick (AddToCartPressed listing.productItem.id) ] [ text "Add" ] ]
        , div [] [ button [ onClick (RemoveFromCart listing.productItem.id) ] [ text "Remove" ] ]
        , div [] [ a [ href ("/product/" ++ String.fromInt listing.productItem.id) ] [ text "View Product" ] ]
        ]


view : Model -> Html Msg
view model =
    case model.pageStatus of
        Loading ->
            div [] [ text <| viewStatus Loading ]

        _ ->
            div []
                [ let
                    cart =
                        List.map viewCartItemListing model.products
                  in
                  if List.isEmpty cart then
                    text "No items in cart"

                  else
                    ul [] cart
                , calculateTotal model |> String.fromFloat |> text
                , a [ href "/checkout" ] [ text "Checkout" ]
                ]
