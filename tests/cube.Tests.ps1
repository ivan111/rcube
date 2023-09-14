BeforeAll {
    . $PSScriptRoot\..\cube.ps1
    . $PSScriptRoot\..\move.ps1

    $w, $g, $r, $b, $o, $y = @(0..5)
}


Describe "IICubeState" {
    It "スクランブルしたときに正しく変更されるか？" {
        $cube = New-IICube
        [string]$scramble = "U' F' D2 R U2 R' U2 F2 R D2 L2 D2 R' B U' L' B2 D2 B2 U2"
        $cube *= $scramble

        $cube.GetUpColors() | Should -Be @($o, $b, $y, $y, $w, $b, $w, $r, $g)
        $cube.GetFrontColors() | Should -Be @($r, $g, $y, $y, $g, $o, $w, $y, $r)
        $cube.GetRightColors() | Should -Be @($r, $o, $o, $w, $r, $o, $b, $w, $o)
        $cube.GetBackColors() | Should -Be @($b, $r, $w, $g, $b, $g, $g, $w, $b)
        $cube.GetLeftColors() | Should -Be @($b, $b, $g, $w, $o, $r, $r, $o, $o)
        $cube.GetDownColors() | Should -Be @($g, $g, $y, $y, $y, $r, $w, $b, $y)
    }
}
