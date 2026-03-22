<?php

$data = [];

function dpat($x, $y, $cl)
{
    $lookup = [
        [ 0, 32,  8, 40,  2, 34, 10, 42],
        [48, 16, 56, 24, 50, 18, 58, 26],
        [12, 44,  4, 36, 14, 46,  6, 38],
        [60, 28, 52, 20, 62, 30, 54, 22],
        [ 3, 35, 11, 43,  1, 33,  9, 41],
        [51, 19, 59, 27, 49, 17, 57, 25],
        [15, 47,  7, 39, 13, 45,  5, 37],
        [63, 31, 55, 23, 61, 29, 53, 21],
    ];

    return $cl + 1.5*($lookup[$y & 7][$x & 7] - 32);
}

// Конвертируется туда-сюда
function color8($x, $y, $rgb)
{
    $r = ($rgb >> 16) & 255;
    $g = ($rgb >> 8 ) & 255;
    $b = $rgb & 255;
    $u = 128;

    $pat = [
        (int)(dpat($x, $y, $r) >= $u),
        (int)(dpat($x, $y, $g) >= $u),
        (int)(dpat($x, $y, $b) >= $u)
    ];

    return $pat[0]*4 + $pat[1]*2 + $pat[2];
}

switch ($argv[1] ?? "") {

    // Загрузка программы
    case 'p':

        $a = 0;
        $bin = file_get_contents($argv[2] ?? "tb.bin");
        for ($i = 0; $i < strlen($bin); $i += 4) {
            $data[$a++] = unpack("V*", substr($bin, $i, 4))[1];
        }

        break;

    // 640x400x16C
    case 'hi':

        $im = imagecreatefromstring(file_get_contents($argv[2] ?? "city.png"));

        $a = 0x8000;
        for ($y = 0; $y < 400; $y++) {

            for ($x = 0; $x < 640; $x += 8) {

                $num = 0;
                for ($i = 0; $i < 8; $i++) {

                    $cl  = imagecolorat($im, $x + $i, $y);
                    $cl  = color8($i, $y, $cl);
                    $num = ($cl & 15) << 28 + ($num >> 28);
                }

                $data[$a++] = $num;
            }
        }

        imagedestroy($im);

        break;

    default:

        die("Требуется мощное и активное супер-действие, бу-бука!\n");
}

$out = [
    "WIDTH=32;",
    "DEPTH=65536;",
    "ADDRESS_RADIX=HEX;",
    "DATA_RADIX=HEX;",
    "CONTENT BEGIN",
];

for ($i = 0; $i < 65536; $i++) $out[] = sprintf("  %04X: %08X;", $i, ($data[$i] ?? 0));

$out[] = "END;";
file_put_contents($argv[3] ?? "m256.mif", join("\n", $out));

