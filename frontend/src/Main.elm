module Main exposing (Model, Msg(..), init, main, subscriptions, update, view, viewLink)

import Browser
import Browser.Navigation as Nav
import Cart
import Catalog
import Checkout
import Css exposing (..)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Http
import Json.Encode as Encode
import Login
import Product
import Profile
import Signup
import Styles exposing (..)
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
    | ProfilePage
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
        , P.map ProfilePage (P.s "profile")
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
    , profileModel : Profile.Model
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

        profile =
            Profile.init
    in
    ( Model key url start login catalog product signup cart checkout profile, Cmd.none )



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
    | ProfileMessage Profile.Msg
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

                Just ProfilePage ->
                    let
                        cmd =
                            Cmd.map ProfileMessage Profile.tryFetchProfile
                    in
                    ( { model | location = ProfilePage }, cmd )

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

                redir =
                    case cmn.pageStatus of
                        Checkout.CheckedOut ->
                            Nav.replaceUrl model.key "/profile"

                        _ ->
                            Cmd.none

                _ =
                    Debug.log "err" "received checkout message ..."
            in
            ( { model | checkoutModel = cmn }, Cmd.batch [ Cmd.map CheckoutMessage cmd, redir ] )

        ProfileMessage pm ->
            let
                ( pmn, cmd ) =
                    Profile.update pm model.profileModel

                _ =
                    Debug.log "err" "recieved profile message"
            in
            ( { model | profileModel = pmn }, Cmd.map ProfileMessage cmd )

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
        HomePage ->
            { title = "Login"
            , body =
                -- model.loginModel
                --     |> Login.view
                --     |> Html.Styled.map LoginMessage
                --     |> toUnstyled
                --     |> List.singleton
                div []
                    [ ul []
                        (List.map
                            (\l ->
                                li []
                                    [ a [ href l ] [ text l ] ]
                            )
                            [ "/login", "/catalog", "/cart" ]
                        )
                    ]
                    |> toUnstyled
                    |> List.singleton
            }

        LoginPage ->
            { title = "Login"
            , body =
                model.loginModel
                    |> Login.view
                    |> Html.Styled.map LoginMessage
                    |> toUnstyled
                    |> List.singleton
            }

        SignupPage ->
            { title = "Signup"
            , body =
                model.signupModel
                    |> Signup.view
                    |> Html.Styled.map SignupMessage
                    |> toUnstyled
                    |> List.singleton
            }

        NotFoundPage ->
            { title = "404 - Not Found"
            , body =
                div []
                    [ text "404 - Not Found"
                    , a [ href "/" ] [ text "Go back >" ]
                    ]
                    |> toUnstyled
                    |> List.singleton
            }

        CatalogPage ->
            { title = "Catalog"
            , body =
                model.catalogModel
                    |> Catalog.view
                    |> Html.Styled.map CatalogMessage
                    |> pageWrap model
            }

        CartPage ->
            { title = "Cart"
            , body =
                model.cartModel
                    |> Cart.view
                    |> Html.Styled.map CartMessage
                    |> pageWrap model
            }

        CheckoutPage ->
            { title = "Checkout"
            , body =
                model.checkoutModel
                    |> Checkout.view
                    |> Html.Styled.map CheckoutMessage
                    |> pageWrap model
            }

        ProfilePage ->
            { title = "Profile"
            , body =
                model.profileModel
                    |> Profile.view
                    |> Html.Styled.map ProfileMessage
                    |> pageWrap model
            }

        ProductPage item ->
            { title = "Product " ++ String.fromInt item
            , body =
                model.productModel
                    |> Product.view
                    |> Html.Styled.map ProductMessage
                    |> pageWrap model
            }


viewHeader : Model -> Html Msg
viewHeader model =
    let
        links =
            [ ( "Catalog", "/catalog" )
            , ( "Cart", "/cart" )
            ]
    in
    div
        [ css
            [ padding (px 30)
            , paddingTop (px 3)
            , paddingBottom (px 3)
            , textAlign left
            , backgroundColor theme.secondary
            ]
        ]
        [ List.map
            (\( name, loc ) ->
                li [ css [ display inline ] ]
                    [ headerLink [ href loc ] [ text name ]
                    ]
            )
            links
            ++ (if model.loginModel.loginStatus /= Login.LoggedIn then
                    [ furbyButton [] [ headerLink [ href "/login" ] [ text "Login" ] ] ]

                else
                    [ headerLink [ href "/profile" ] [ text "Profile" ]
                    , furbyButton [ onClick LogoutPressed ] [ text "Logout" ]
                    ]
               )
            |> ul
                [ css
                    [ listStyle Css.none
                    , padding (px 0)
                    , margin (px 12)
                    ]
                ]
        ]


pageWrap : Model -> Html Msg -> List (Html.Html Msg)
pageWrap model page =
    div []
        [ viewHeader model
        , page
        ]
        |> toUnstyled
        |> List.singleton


viewLink : String -> Html msg
viewLink path =
    li [] [ a [ href path ] [ text path ] ]
