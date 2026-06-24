# Generate all character/enemy/UI sprites via AI API
$ProgressPreference = 'SilentlyContinue'
$API = "https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image"
$DIR = "d:\Claudeworkspace\Lordisland\assets\sprites"
New-Item -ItemType Directory -Force -Path $DIR | Out-Null

$specs = @(
    @{name="parn";      prompt="pixel art, 16-bit JRPG, full body young warrior, blue armor, golden hair, sword, holding sword, transparent background, 96x96 sprite, single pose, detailed, anime style"; size="square_hd"},
    @{name="ehto";      prompt="pixel art, 16-bit JRPG, full body elf priestess, purple robe, brown hair, magic staff, holding staff, transparent background, 96x96 sprite, single pose, detailed, anime style"; size="square_hd"},
    @{name="slayn";     prompt="pixel art, 16-bit JRPG, full body mage, red robe, black hair, dagger, holding dagger, transparent background, 96x96 sprite, single pose, detailed, anime style"; size="square_hd"},
    @{name="tike";      prompt="pixel art, 16-bit JRPG, full body ranger archer, green tunic, blonde hair, bow, holding bow, transparent background, 96x96 sprite, single pose, detailed, anime style"; size="square_hd"},
    @{name="ghim";      prompt="pixel art, 16-bit JRPG, full body dwarf warrior, brown armor, black hair, axe, holding axe, transparent background, 96x96 sprite, single pose, detailed, anime style"; size="square_hd"},
    @{name="goblin";    prompt="pixel art, 16-bit JRPG, fantasy monster goblin, green skin, club weapon, full body, transparent background, 96x96 sprite, single pose, detailed"; size="square_hd"},
    @{name="orc";       prompt="pixel art, 16-bit JRPG, fantasy monster orc warrior, brown skin, muscular, club weapon, full body, transparent background, 96x96 sprite, single pose, detailed"; size="square_hd"},
    @{name="goblin_archer"; prompt="pixel art, 16-bit JRPG, fantasy monster goblin archer, green skin, bow, full body, transparent background, 96x96 sprite, single pose, detailed"; size="square_hd"},
    @{name="kobold";    prompt="pixel art, 16-bit JRPG, fantasy monster kobold, dog-like humanoid, brown skin, spear, full body, transparent background, 96x96 sprite, single pose, detailed"; size="square_hd"},
    @{name="troll";     prompt="pixel art, 16-bit JRPG, fantasy monster troll boss, large muscular, green-grey skin, club, full body, transparent background, 96x96 sprite, single pose, detailed, menacing"; size="square_hd"}
)

foreach ($s in $specs) {
    $out = Join-Path $DIR ($s.name + ".png")
    if (Test-Path $out) { Write-Host "skip $($s.name)"; continue }
    $url = $API + "?prompt=" + [uri]::EscapeDataString($s.prompt) + "&image_size=" + $s.size
    try {
        Write-Host "generate $($s.name)..."
        Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -TimeoutSec 60
        if (Test-Path $out) { Write-Host "  -> $((Get-Item $out).Length / 1KB) KB" }
    } catch { Write-Host "  FAIL: $_" }
}
Write-Host "===DONE==="