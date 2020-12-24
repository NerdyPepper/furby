module Utils exposing (..)


between : ( Float, Float ) -> Float -> Bool
between ( l, u ) v =
    v >= l && v <= u


range : Int -> Int -> Int -> List Int
range start stop step =
    if start >= stop then
        []

    else
        start :: range (start + step) stop step
