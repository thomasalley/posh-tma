function Get-AverageOfArray
{
    Param
    (
        [Parameter(Mandatory=$True)]
        [object] $array,

        [Parameter(Mandatory=$False)]
        [int]
        $offset = 1

    )

    $calc = 0
    for($i = $offset; $i -lt $array.Count; $i++)
    {
        $calc += [float]::Parse($array[$i].Value)
    }
    return $calc / ( $i - $offset )
}