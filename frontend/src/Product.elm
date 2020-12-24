module Product exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as D
import Json.Encode as Encode
import Url
import Url.Parser as P exposing ((</>), Parser, int, oneOf, s, string)


type SubmitStatus
    = SubmitSuccess
    | SubmitFail
    | Submitting
    | NotSubmitted


type alias Product =
    { id : Int
    , name : String
    , kind : Maybe String
    , price : Float
    , description : Maybe String
    }


emptyProduct =
    Product -1 "" Nothing 0 Nothing


type alias Rating =
    { commentDate : String
    , commentText : Maybe String
    , customerName : String
    , productName : String
    , stars : Int
    }


type alias Model =
    { pageStatus : Status
    , listing : Product
    , ratings : List Rating
    , ratingStars : Int
    , ratingText : String
    , addRatingStatus : SubmitStatus
    }


type Status
    = Loading
    | Loaded
    | NotLoaded


type Msg
    = ListingLoaded (Result Http.Error Product)
    | RatingsLoaded (Result Http.Error (List Rating))
    | FetchProduct Int
    | FetchRatings Int
    | AddRatingStars Int
    | AddRatingComment String
    | AddRatingPressed
    | AddRatingSuccess (Result Http.Error ())
    | AddRatingFail
    | AddToCartSuccess (Result Http.Error ())
    | AddToCartPressed


init : Model
init =
    Model NotLoaded emptyProduct [] 0 "" NotSubmitted


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ListingLoaded res ->
            case res of
                Ok s ->
                    ( { model | listing = s, pageStatus = Loaded }, Cmd.none )

                Err e ->
                    let
                        _ =
                            Debug.log "error" e
                    in
                    ( { model | pageStatus = NotLoaded }, Cmd.none )

        RatingsLoaded res ->
            case res of
                Ok s ->
                    ( { model | ratings = s, pageStatus = Loaded }, Cmd.none )

                Err e ->
                    let
                        _ =
                            Debug.log "error" e
                    in
                    ( { model | pageStatus = NotLoaded }, Cmd.none )

        FetchProduct id ->
            ( { model | pageStatus = Loading }, fetchListing id )

        FetchRatings id ->
            ( { model | pageStatus = Loading }, fetchRatings id )

        AddRatingStars i ->
            ( { model | ratingStars = i }, Cmd.none )

        AddRatingComment s ->
            ( { model | ratingText = s }, Cmd.none )

        AddRatingPressed ->
            ( { model | addRatingStatus = Submitting }
            , submitRating model
            )

        AddRatingSuccess res ->
            case res of
                Ok _ ->
                    ( { model | addRatingStatus = SubmitSuccess }, fetchRatings model.listing.id )

                Err _ ->
                    ( { model | addRatingStatus = SubmitFail }, Cmd.none )

        AddRatingFail ->
            ( { model | addRatingStatus = SubmitFail }, Cmd.none )

        AddToCartPressed ->
            ( model, addToCart model )

        AddToCartSuccess _ ->
            ( model, Cmd.none )


decodeProduct : D.Decoder Product
decodeProduct =
    D.map5 Product
        (D.field "id" D.int)
        (D.field "name" D.string)
        (D.field "kind" (D.nullable D.string))
        (D.field "price" D.float)
        (D.field "description" (D.nullable D.string))


decodeRating : D.Decoder Rating
decodeRating =
    D.map5 Rating
        (D.field "comment_date" D.string)
        (D.field "comment_text" (D.nullable D.string))
        (D.field "customer_name" D.string)
        (D.field "product_name" D.string)
        (D.field "stars" D.int)


decodeRatings : D.Decoder (List Rating)
decodeRatings =
    D.list decodeRating


fetchListing : Int -> Cmd Msg
fetchListing id =
    let
        _ =
            Debug.log "err" <| "fetching listing " ++ String.fromInt id
    in
    Http.get
        { url = "http://127.0.0.1:7878/product/" ++ String.fromInt id
        , expect = Http.expectJson ListingLoaded decodeProduct
        }


fetchRatings : Int -> Cmd Msg
fetchRatings id =
    let
        _ =
            Debug.log "err" <| "fetching ratings " ++ String.fromInt id
    in
    Http.get
        { url = "http://127.0.0.1:7878/product/reviews/" ++ String.fromInt id
        , expect = Http.expectJson RatingsLoaded decodeRatings
        }


encodeRatingForm : Model -> Encode.Value
encodeRatingForm model =
    Encode.object
        [ ( "product_id", Encode.int model.listing.id )
        , ( "stars", Encode.int model.ratingStars )
        , ( "comment_text", Encode.string model.ratingText )
        ]


submitRating : Model -> Cmd Msg
submitRating model =
    let
        _ =
            Debug.log "err" <| "submitting rating for" ++ String.fromInt model.listing.id
    in
    Http.riskyRequest
        { method = "POST"
        , headers = []
        , url = "http://127.0.0.1:7878/rating/add"
        , body = model |> encodeRatingForm |> Http.jsonBody
        , expect = Http.expectWhatever AddRatingSuccess
        , timeout = Nothing
        , tracker = Nothing
        }


addToCart : Model -> Cmd Msg
addToCart model =
    let
        _ =
            Debug.log "err" <| "adding to cart: " ++ String.fromInt model.listing.id
    in
    Http.riskyRequest
        { method = "POST"
        , headers = []
        , url = "http://127.0.0.1:7878/cart/add"
        , body = Http.stringBody "applcation/json" <| String.fromInt <| model.listing.id
        , expect = Http.expectWhatever AddToCartSuccess
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


viewProduct : Product -> Html Msg
viewProduct p =
    div []
        [ text p.name
        , text <| Maybe.withDefault "" p.kind
        , text <| Maybe.withDefault "" p.description
        , text <| String.fromFloat p.price
        ]


viewRating : Rating -> Html Msg
viewRating r =
    div []
        [ text <| r.customerName ++ " posted on "
        , text <| r.commentDate ++ " "
        , text <| Maybe.withDefault "" r.commentText
        , text <| " Stars: " ++ String.fromInt r.stars
        ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input [ type_ t, placeholder p, value v, onInput toMsg ] []


viewStars : Html Msg
viewStars =
    ul []
        (List.map
            (\i -> button [ onClick (AddRatingStars i) ] [ text <| String.fromInt i ])
            [ 0, 1, 2, 3, 4, 5 ]
        )


view : Model -> Html Msg
view model =
    case model.pageStatus of
        Loading ->
            div [] [ text <| viewStatus Loading ]

        _ ->
            div []
                [ div [] [ viewProduct model.listing ]
                , ul [] (List.map viewRating model.ratings)
                , div [] [ text "Add Rating: " ]
                , div []
                    [ viewStars
                    , viewInput "text" "Enter Comment Text" model.ratingText AddRatingComment
                    , button [ onClick AddRatingPressed ] [ text "Submit Rating" ]
                    ]
                , div []
                    [ button [ onClick AddToCartPressed ] [ text "Add To Cart" ]
                    ]
                , div []
                    [ a [ href "/catalog" ] [ text "Back to catalog" ]
                    ]
                ]
