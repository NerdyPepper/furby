module Styles exposing (..)

import Css exposing (..)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)


type alias Theme =
    { primary : Color
    , secondary : Color
    , bad : Color
    , fg : Color
    , bg : Color
    , fgLight : Color
    , bgLight : Color
    }


theme : Theme
theme =
    Theme
        (hex "fedbd0")
        -- primary
        (hex "feeae6")
        -- secondary
        (hex "ff0000")
        -- bad
        (hex "442c2e")
        -- fg
        (hex "ffffff")
        -- bg
        (hex "442c2e")
        -- fgLight
        (hex "feeae6")



-- bgLight


headerLink : List (Attribute msg) -> List (Html msg) -> Html msg
headerLink =
    styled a
        [ color theme.fgLight
        , padding (px 12)
        , textDecoration Css.none
        , hover
            [ backgroundColor theme.secondary
            , textDecoration underline
            ]
        ]


furbyButton : List (Attribute msg) -> List (Html msg) -> Html msg
furbyButton =
    styled button
        [ margin (px 12)
        , color theme.fg
        , Css.height (px 40)
        , border (px 0)
        , borderRadius (px 2)
        , padding2 (px 6) (px 12)
        , backgroundColor theme.primary
        , hover
            [ backgroundColor theme.secondary
            , color theme.fg
            , margin (px 12)
            ]
        ]


furbyRadio : String -> msg -> Html msg
furbyRadio value msg =
    label
        []
        [ input
            [ type_ "radio"
            , onClick msg
            , name "radio"
            ]
            []
        , text value
        ]


furbySelect : List (Attribute msg) -> List (Html msg) -> Html msg
furbySelect =
    styled select
        [ margin (px 6)
        , color theme.fg
        , border (px 0)
        , borderBottom3 (px 2) solid theme.bgLight
        , textAlign right
        , padding2 (px 3) (px 3)
        , backgroundColor theme.bg
        , hover
            [ borderBottom3 (px 2) solid theme.fg
            ]
        ]


loginInputField : List (Attribute msg) -> List (Html msg) -> Html msg
loginInputField =
    styled input
        [ Css.width (pct 100)
        , color theme.fg
        , border (px 0)
        , borderBottom3 (px 1) solid theme.bgLight
        , focus
            [ borderBottom3 (px 2) solid theme.fg
            ]
        ]


bigHeading : Style
bigHeading =
    fontSize (px 24)



-- card styles


cardPrimaryText =
    fontSize (px 18)


cardSecondaryText =
    Css.batch [ color theme.fgLight, fontSize (px 12) ]


cardSupportingText =
    fontSize (px 16)


money =
    before [ Css.property "content" "\"₹ \"" ]
