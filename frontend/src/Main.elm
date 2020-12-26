module Main exposing (Model, Msg(..), init, main, subscriptions, update, view, viewLink)

import Browser
import Browser.Navigation as Nav
import Cart
import Catalog
import Checkout
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Encode as Encode
import Login
import Product
import Signup
import Url
import Url.Parser as P exposing ((</>), Parser, int, oneOf, s, string)



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- MODEL


type Route
    = LoginPage
    | SignupPage
    | HomePage
    | CatalogPage
    | CartPage
    | ProductPage Int
    | CheckoutPage
    | NotFoundPage


parseRoute : Parser (Route -> a) a
parseRoute =
    oneOf
        [ P.map LoginPage (P.s "login")
        , P.map HomePage P.top
        , P.map CatalogPage (P.s "catalog")
        , P.map CartPage (P.s "cart")
        , P.map SignupPage (P.s "signup")
        , P.map CheckoutPage (P.s "checkout")
        , P.map ProductPage (P.s "product" </> P.int)
        ]


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , location : Route
    , loginModel : Login.Model
    , catalogModel : Catalog.Model
    , productModel : Product.Model
    , signupModel : Signup.Model
    , cartModel : Cart.Model
    , checkoutModel : Checkout.Model
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        start =
            HomePage

        login =
            Login.init

        catalog =
            Catalog.init

        product =
            Product.init

        signup =
            Signup.init

        cart =
            Cart.init

        checkout =
            Checkout.init
    in
    ( Model key url start login catalog product signup cart checkout, Cmd.none )



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | LoginMessage Login.Msg
    | CatalogMessage Catalog.Msg
    | ProductMessage Product.Msg
    | SignupMessage Signup.Msg
    | CartMessage Cart.Msg
    | CheckoutMessage Checkout.Msg
    | LogoutPressed
    | LogoutSuccess (Result Http.Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        LogoutPressed ->
            ( model, tryLogout )

        LogoutSuccess _ ->
            ( { model | loginModel = Login.init }, Nav.replaceUrl model.key "/login" )

        UrlChanged url ->
            let
                parsedUrl =
                    P.parse parseRoute url
            in
            case parsedUrl of
                Just CatalogPage ->
                    ( { model | location = CatalogPage }, Cmd.map CatalogMessage Catalog.fetchProducts )

                Just (ProductPage id) ->
                    let
                        cmds =
                            List.map (Cmd.map ProductMessage)
                                [ Product.fetchListing id
                                , Product.fetchRatings id
                                ]
                    in
                    ( { model | location = ProductPage id }, Cmd.batch cmds )

                Just CartPage ->
                    let
                        cmd =
                            Cmd.map CartMessage Cart.fetchCartItems
                    in
                    ( { model | location = CartPage }, cmd )

                Just CheckoutPage ->
                    let
                        _ =
                            Debug.log "err" "loading checkout page ..."

                        cmd =
                            Cmd.map CheckoutMessage Checkout.fetchAmount
                    in
                    ( { model | location = CheckoutPage }, cmd )

                Just p ->
                    ( { model | location = p }, Cmd.none )

                Nothing ->
                    ( { model | location = NotFoundPage }, Cmd.none )

        LoginMessage lm ->
            let
                ( lmn, cmd ) =
                    Login.update lm model.loginModel

                redir =
                    case lmn.loginStatus of
                        Login.LoggedIn ->
                            Nav.replaceUrl model.key "/catalog"

                        _ ->
                            Cmd.none
            in
            ( { model | loginModel = lmn }, Cmd.batch [ Cmd.map LoginMessage cmd, redir ] )

        SignupMessage sm ->
            let
                ( smn, cmd ) =
                    Signup.update sm model.signupModel

                redir =
                    case smn.status of
                        Signup.CreatedSuccessfully ->
                            Nav.replaceUrl model.key "/login"

                        _ ->
                            Cmd.none
            in
            ( { model | signupModel = smn }, Cmd.batch [ Cmd.map SignupMessage cmd, redir ] )

        CatalogMessage cm ->
            let
                ( cmn, cmd ) =
                    Catalog.update cm model.catalogModel
            in
            ( { model | catalogModel = cmn }, Cmd.map CatalogMessage cmd )

        CartMessage cm ->
            let
                ( cmn, cmd ) =
                    Cart.update cm model.cartModel
            in
            ( { model | cartModel = cmn }, Cmd.map CartMessage cmd )

        CheckoutMessage cm ->
            let
                ( cmn, cmd ) =
                    Checkout.update cm model.checkoutModel

                _ =
                    Debug.log "err" "received checkout message ..."
            in
            ( { model | checkoutModel = cmn }, Cmd.map CheckoutMessage cmd )

        ProductMessage pm ->
            let
                ( pmn, cmd ) =
                    Product.update pm model.productModel

                redir =
                    case pm of
                        Product.AddToCartSuccess _ ->
                            Nav.replaceUrl model.key "/cart"

                        _ ->
                            Cmd.none
            in
            ( { model | productModel = pmn }, Cmd.batch [ Cmd.map ProductMessage cmd, redir ] )


tryLogout : Cmd Msg
tryLogout =
    Http.riskyRequest
        { method = "POST"
        , headers = []
        , url = "http://127.0.0.1:7878/user/logout"
        , body = Http.emptyBody
        , expect = Http.expectWhatever LogoutSuccess
        , timeout = Nothing
        , tracker = Nothing
        }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    case model.location of
        LoginPage ->
            { title = "Login"
            , body = [ Html.map LoginMessage (Login.view model.loginModel) ]
            }

        SignupPage ->
            { title = "Signup"
            , body = [ Html.map SignupMessage (Signup.view model.signupModel) ]
            }

        HomePage ->
            { title = "URL Interceptor"
            , body =
                [ text "The current URL is: "
                , b [] [ text (Url.toString model.url) ]
                , ul []
                    [ viewLink "/login"
                    , viewLink "/catalog"
                    , viewLink "/cart"
                    , viewLink "/signup"
                    ]
                ]
            }

        NotFoundPage ->
            { title = "404 - Not Found"
            , body =
                [ text "404 - Not Found"
                , a [ href "/" ] [ text "Go back >" ]
                ]
            }

        CatalogPage ->
            { title = "Catalog"
            , body = pageWrap model (Html.map CatalogMessage (Catalog.view model.catalogModel))
            }

        CartPage ->
            { title = "Cart"
            , body = pageWrap model (Html.map CartMessage (Cart.view model.cartModel))
            }

        CheckoutPage ->
            { title = "Checkout"
            , body = pageWrap model (Html.map CheckoutMessage (Checkout.view model.checkoutModel))
            }

        ProductPage item ->
            { title = "Product " ++ String.fromInt item
            , body = pageWrap model (Html.map ProductMessage (Product.view model.productModel))
            }


viewHeader : Model -> Html Msg
viewHeader model =
    let
        links =
            [ ( "Home", "/" )
            , ( "Catalog", "/catalog" )
            , ( "Cart", "/cart" )
            ]
    in
    div []
        [ List.map
            (\( name, loc ) ->
                li []
                    [ a [ href loc ] [ text name ]
                    ]
            )
            links
            ++ [ if model.loginModel.loginStatus /= Login.LoggedIn then
                    li [] [ a [ href "/login" ] [ text "Login" ] ]

                 else
                    button [ onClick LogoutPressed ] [ text "Logout" ]
               ]
            |> ul []
        ]


pageWrap : Model -> Html Msg -> List (Html Msg)
pageWrap model page =
    [ div []
        [ viewHeader model
        , page
        ]
    ]


viewLink : String -> Html msg
viewLink path =
    li [] [ a [ href path ] [ text path ] ]
