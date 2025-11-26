function copilot {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $Args
    )

    $exe = (Get-Command 'copilot.cmd' -CommandType Application -ErrorAction Stop).Source

    $prev = $env:NODE_TLS_REJECT_UNAUTHORIZED
    $env:NODE_TLS_REJECT_UNAUTHORIZED = '0'

    try {
        & $exe @Args
    }
    finally {
        if ($null -ne $prev) {
            $env:NODE_TLS_REJECT_UNAUTHORIZED = $prev
        }
        else {
            Remove-Item Env:NODE_TLS_REJECT_UNAUTHORIZED -ErrorAction SilentlyContinue
        }
    }
}