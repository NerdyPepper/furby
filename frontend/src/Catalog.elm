module Catalog exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as D
import Json.Encode as Encode
import Tuple exposing (..)
import Url
import Url.Parser as P exposing ((</>), Parser, int, oneOf, s, string)
import Utils exposing (..)


type Order
    = Rating
    | Price


type alias Product =
    { id : Int
    , name : String
    , kind : Maybe String
    , price : Float
    , description : Maybe String
    , averageRating : Maybe Float
    }


type alias Filters =
    { price : ( Float, Float )
    , rating : ( Float, Float )
    }


defaultFilters : Filters
defaultFilters =
    Filters ( -1, 10000 ) ( 0, 5 )


type alias Model =
    { pageStatus : Status
    , products : List Product
    , filters : Filters
    }


type Status
    = Loading
    | Loaded
    | NotLoaded


type Msg
    = ProductsLoaded (Result Http.Error (List Product))
    | FetchProducts
    | ChangePriceLower Float
    | ChangePriceUpper Float
    | ChangeRatingLower Float
    | ChangeRatingUpper Float


init : Model
init =
    Model NotLoaded [] defaultFilters


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ProductsLoaded res ->
            case res of
                Ok s ->
                    ( { model | products = s, pageStatus = Loaded }, Cmd.none )

                Err e ->
                    let
                        _ =
                            Debug.log "error" e
                    in
                    ( { model | pageStatus = NotLoaded }, Cmd.none )

        FetchProducts ->
            ( { model | pageStatus = Loading }, fetchProducts )

        ChangePriceLower v ->
            let
                fs =
                    model.filters

                nfs =
                    { fs | price = mapFirst (always v) fs.price }
            in
            ( { model | filters = nfs }, Cmd.none )

        ChangePriceUpper v ->
            let
                fs =
                    model.filters

                nfs =
                    { fs | price = mapSecond (always v) fs.price }
            in
            ( { model | filters = nfs }, Cmd.none )

        ChangeRatingLower v ->
            let
                fs =
                    model.filters

                nfs =
                    { fs | rating = mapFirst (always v) fs.rating }
            in
            ( { model | filters = nfs }, Cmd.none )

        ChangeRatingUpper v ->
            let
                fs =
                    model.filters

                nfs =
                    { fs | rating = mapSecond (always v) fs.rating }
            in
            ( { model | filters = nfs }, Cmd.none )


decodeProduct : D.Decoder Product
decodeProduct =
    D.map6 Product
        (D.field "id" D.int)
        (D.field "name" D.string)
        (D.field "kind" (D.nullable D.string))
        (D.field "price" D.float)
        (D.field "description" (D.nullable D.string))
        (D.field "average_rating" (D.nullable D.float))


decodeResponse : D.Decoder (List Product)
decodeResponse =
    D.list decodeProduct


fetchProducts : Cmd Msg
fetchProducts =
    let
        _ =
            Debug.log "err" "fetching products"
    in
    Http.get
        { url = "http://127.0.0.1:7878/product/catalog"
        , expect = Http.expectJson ProductsLoaded decodeResponse
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


viewProduct : Product -> Html Msg
viewProduct p =
    div []
        [ div [] [ text p.name ]
        , div [] [ text <| Maybe.withDefault "" p.kind ]
        , div [] [ text <| Maybe.withDefault "" p.description ]
        , div [] [ text <| String.fromFloat p.price ]
        , case p.averageRating of
            Just v ->
                text <| "Avg Rating: " ++ String.fromFloat v

            Nothing ->
                text "No Ratings"
        , div [] [ a [ href ("/product/" ++ String.fromInt p.id) ] [ text "View Product" ] ]
        ]


viewFilters : Model -> Html Msg
viewFilters model =
    let
        priceRange =
            range 0 55000 5000

        ratingRange =
            range 1 6 1

        viewRange default scale =
            List.map (\i -> option [ selected (i == default) ] [ text <| String.fromInt i ]) scale

        inp =
            Maybe.withDefault 0 << String.toFloat
    in
    div []
        [ div []
            [ text "Price"
            , select [ onInput (ChangePriceLower << inp) ] (viewRange 0 priceRange)
            , text "to"
            , select [ onInput (ChangePriceUpper << inp) ] (viewRange 50000 priceRange)
            ]
        , div []
            [ text "Rating"
            , select [ onInput (ChangeRatingLower << inp) ] (viewRange 1 ratingRange)
            , text "to"
            , select [ onInput (ChangeRatingUpper << inp) ] (viewRange 5 ratingRange)
            ]
        ]


filterProducts : Model -> List Product
filterProducts model =
    model.products
        |> List.filter (between model.filters.price << .price)
        |> List.filter
            (\p ->
                p.averageRating
                    |> Maybe.withDefault 5.0
                    |> between model.filters.rating
            )


view : Model -> Html Msg
view model =
    case model.pageStatus of
        Loading ->
            div [] [ text <| viewStatus Loading ]

        _ ->
            div []
                [ div [] [ viewFilters model ]
                , ul []
                    (filterProducts model |> List.map viewProduct)
                ]
