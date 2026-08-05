Add-Type -AssemblyName System.IO.Compression.FileSystem

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$templatePath = Join-Path $root 'multiplication.sb3'
$outDir = Join-Path $root 'Book2_Example_Programs'

if (-not (Test-Path $templatePath)) {
  throw "Template sb3 not found: $templatePath"
}

if (-not (Test-Path $outDir)) {
  New-Item -ItemType Directory -Path $outDir | Out-Null
}

$templateZip = [System.IO.Compression.ZipFile]::OpenRead($templatePath)
$assetBytes = @{}

foreach ($entry in $templateZip.Entries) {
  if ($entry.FullName -eq 'project.json') {
    continue
  }

  $ms = New-Object System.IO.MemoryStream
  $stream = $entry.Open()
  $stream.CopyTo($ms)
  $stream.Dispose()
  $assetBytes[$entry.FullName] = $ms.ToArray()
  $ms.Dispose()
}

$templateZip.Dispose()

function New-StageTarget {
  param(
    [hashtable]$Broadcasts
  )

  return [ordered]@{
    isStage = $true
    name = 'Stage'
    variables = @{}
    lists = @{}
    broadcasts = $Broadcasts
    blocks = @{}
    comments = @{}
    currentCostume = 0
    costumes = @(
      [ordered]@{
        name = 'backdrop1'
        dataFormat = 'svg'
        assetId = 'cd21514d0531fdffb22204e0ec5ed84a'
        md5ext = 'cd21514d0531fdffb22204e0ec5ed84a.svg'
        rotationCenterX = 240
        rotationCenterY = 180
      }
    )
    sounds = @(
      [ordered]@{
        name = 'pop'
        assetId = '83a9787d4cb6f3b7632b4ddfebf74367'
        dataFormat = 'wav'
        format = ''
        rate = 48000
        sampleCount = 1123
        md5ext = '83a9787d4cb6f3b7632b4ddfebf74367.wav'
      }
    )
    volume = 100
    layerOrder = 0
    tempo = 60
    videoTransparency = 50
    videoState = 'on'
    textToSpeechLanguage = $null
  }
}

function New-SpriteTarget {
  param(
    [string]$Name,
    [hashtable]$Blocks,
    [int]$LayerOrder,
    [int]$X,
    [int]$Y
  )

  return [ordered]@{
    isStage = $false
    name = $Name
    variables = @{}
    lists = @{}
    broadcasts = @{}
    blocks = $Blocks
    comments = @{}
    currentCostume = 0
    costumes = @(
      [ordered]@{
        name = 'costume1'
        bitmapResolution = 1
        dataFormat = 'svg'
        assetId = 'bcf454acf82e4504149f7ffe07081dbc'
        md5ext = 'bcf454acf82e4504149f7ffe07081dbc.svg'
        rotationCenterX = 48
        rotationCenterY = 50
      },
      [ordered]@{
        name = 'costume2'
        bitmapResolution = 1
        dataFormat = 'svg'
        assetId = '0fb9be3e8397c983338cb71dc84d0b25'
        md5ext = '0fb9be3e8397c983338cb71dc84d0b25.svg'
        rotationCenterX = 46
        rotationCenterY = 53
      }
    )
    sounds = @(
      [ordered]@{
        name = 'Meow'
        assetId = '83c36d806dc92327b9e7049a565c6bff'
        dataFormat = 'wav'
        format = ''
        rate = 48000
        sampleCount = 40681
        md5ext = '83c36d806dc92327b9e7049a565c6bff.wav'
      }
    )
    volume = 100
    layerOrder = $LayerOrder
    visible = $true
    x = $X
    y = $Y
    size = 100
    direction = 90
    draggable = $false
    rotationStyle = 'all around'
  }
}

function Write-Sb3 {
  param(
    [string]$OutputPath,
    [hashtable]$ProjectObject
  )

  if (Test-Path $OutputPath) {
    Remove-Item -Path $OutputPath -Force
  }

  $json = $ProjectObject | ConvertTo-Json -Depth 100 -Compress

  $fileStream = [System.IO.File]::Open($OutputPath, [System.IO.FileMode]::CreateNew)
  $zip = New-Object System.IO.Compression.ZipArchive($fileStream, [System.IO.Compression.ZipArchiveMode]::Create)

  $projectEntry = $zip.CreateEntry('project.json')
  $writer = New-Object System.IO.StreamWriter($projectEntry.Open())
  $writer.Write($json)
  $writer.Dispose()

  foreach ($assetName in $assetBytes.Keys) {
    $assetEntry = $zip.CreateEntry($assetName)
    $assetStream = $assetEntry.Open()
    $assetStream.Write($assetBytes[$assetName], 0, $assetBytes[$assetName].Length)
    $assetStream.Dispose()
  }

  $zip.Dispose()
  $fileStream.Dispose()
}

# Example 1: Sprites and Animation
$ex1Blocks = [ordered]@{
  'a1' = [ordered]@{
    opcode = 'event_whenflagclicked'
    next = 'a2'
    parent = $null
    inputs = @{}
    fields = @{}
    shadow = $false
    topLevel = $true
    x = 240
    y = 120
  }
  'a2' = [ordered]@{
    opcode = 'control_repeat'
    next = $null
    parent = 'a1'
    inputs = [ordered]@{
      TIMES = @(1, @(4, '16'))
      SUBSTACK = @(2, 'a3')
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'a3' = [ordered]@{
    opcode = 'looks_nextcostume'
    next = 'a4'
    parent = 'a2'
    inputs = @{}
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'a4' = [ordered]@{
    opcode = 'motion_movesteps'
    next = 'a5'
    parent = 'a3'
    inputs = [ordered]@{
      STEPS = @(1, @(4, '6'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'a5' = [ordered]@{
    opcode = 'control_wait'
    next = $null
    parent = 'a4'
    inputs = [ordered]@{
      DURATION = @(1, @(4, '0.12'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
}

$project1 = [ordered]@{
  targets = @(
    (New-StageTarget -Broadcasts @{}),
    (New-SpriteTarget -Name 'Sprite1' -Blocks $ex1Blocks -LayerOrder 1 -X 0 -Y 0)
  )
  monitors = @()
  extensions = @()
  meta = [ordered]@{
    semver = '3.0.0'
    vm = '11.2.0-feature-parity.2'
    agent = 'Generated for THYNK teacher references'
  }
}

Write-Sb3 -OutputPath (Join-Path $outDir 'book2_ch1_animation_example.sb3') -ProjectObject $project1

# Example 2: Custom Blocks with input jump(height)
$ex2Blocks = [ordered]@{
  'c1' = [ordered]@{
    opcode = 'event_whenflagclicked'
    next = 'c2'
    parent = $null
    inputs = @{}
    fields = @{}
    shadow = $false
    topLevel = $true
    x = 260
    y = 80
  }
  'c2' = [ordered]@{
    opcode = 'procedures_call'
    next = 'c3'
    parent = 'c1'
    inputs = [ordered]@{
      'arg-height' = @(1, @(4, '20'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
    mutation = [ordered]@{
      tagName = 'mutation'
      children = @()
      proccode = 'jump %s'
      argumentids = '["arg-height"]'
      warp = 'false'
    }
  }
  'c3' = [ordered]@{
    opcode = 'control_wait'
    next = 'c4'
    parent = 'c2'
    inputs = [ordered]@{
      DURATION = @(1, @(4, '0.2'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'c4' = [ordered]@{
    opcode = 'procedures_call'
    next = $null
    parent = 'c3'
    inputs = [ordered]@{
      'arg-height' = @(1, @(4, '50'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
    mutation = [ordered]@{
      tagName = 'mutation'
      children = @()
      proccode = 'jump %s'
      argumentids = '["arg-height"]'
      warp = 'false'
    }
  }
  'd1' = [ordered]@{
    opcode = 'procedures_definition'
    next = 'd3'
    parent = $null
    inputs = [ordered]@{
      custom_block = @(1, 'd2')
    }
    fields = @{}
    shadow = $false
    topLevel = $true
    x = 48
    y = 80
  }
  'd2' = [ordered]@{
    opcode = 'procedures_prototype'
    next = $null
    parent = 'd1'
    inputs = [ordered]@{
      'arg-height' = @(1, 'd2arg')
    }
    fields = @{}
    shadow = $true
    topLevel = $false
    mutation = [ordered]@{
      tagName = 'mutation'
      children = @()
      proccode = 'jump %s'
      argumentids = '["arg-height"]'
      argumentnames = '["height"]'
      argumentdefaults = '["10"]'
      warp = 'false'
    }
  }
  'd2arg' = [ordered]@{
    opcode = 'argument_reporter_string_number'
    next = $null
    parent = 'd2'
    inputs = @{}
    fields = [ordered]@{
      VALUE = @('height', $null)
    }
    shadow = $true
    topLevel = $false
  }
  'd3' = [ordered]@{
    opcode = 'motion_changeyby'
    next = 'd4'
    parent = 'd1'
    inputs = [ordered]@{
      DY = @(3, 'd3arg', @(4, '10'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'd3arg' = [ordered]@{
    opcode = 'argument_reporter_string_number'
    next = $null
    parent = 'd3'
    inputs = @{}
    fields = [ordered]@{
      VALUE = @('height', $null)
    }
    shadow = $false
    topLevel = $false
  }
  'd4' = [ordered]@{
    opcode = 'control_wait'
    next = 'd5'
    parent = 'd3'
    inputs = [ordered]@{
      DURATION = @(1, @(4, '0.1'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'd5' = [ordered]@{
    opcode = 'motion_changeyby'
    next = $null
    parent = 'd4'
    inputs = [ordered]@{
      DY = @(3, 'd6', @(4, '-10'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'd6' = [ordered]@{
    opcode = 'operator_multiply'
    next = $null
    parent = 'd5'
    inputs = [ordered]@{
      NUM1 = @(3, 'd6arg', @(4, ''))
      NUM2 = @(1, @(4, '-1'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'd6arg' = [ordered]@{
    opcode = 'argument_reporter_string_number'
    next = $null
    parent = 'd6'
    inputs = @{}
    fields = [ordered]@{
      VALUE = @('height', $null)
    }
    shadow = $false
    topLevel = $false
  }
}

$project2 = [ordered]@{
  targets = @(
    (New-StageTarget -Broadcasts @{}),
    (New-SpriteTarget -Name 'Sprite1' -Blocks $ex2Blocks -LayerOrder 1 -X 0 -Y 0)
  )
  monitors = @()
  extensions = @()
  meta = [ordered]@{
    semver = '3.0.0'
    vm = '11.2.0-feature-parity.2'
    agent = 'Generated for THYNK teacher references'
  }
}

Write-Sb3 -OutputPath (Join-Path $outDir 'book2_ch2_custom_block_jump_example.sb3') -ProjectObject $project2

# Example 3: Sound and Storytelling timeline
$ex3Blocks = [ordered]@{
  's1' = [ordered]@{
    opcode = 'event_whenflagclicked'
    next = 's2'
    parent = $null
    inputs = @{}
    fields = @{}
    shadow = $false
    topLevel = $true
    x = 240
    y = 90
  }
  's2' = [ordered]@{
    opcode = 'looks_sayforsecs'
    next = 's3'
    parent = 's1'
    inputs = [ordered]@{
      MESSAGE = @(1, @(10, 'I think we are lost...'))
      SECS = @(1, @(4, '2'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  's3' = [ordered]@{
    opcode = 'sound_playuntildone'
    next = 's4'
    parent = 's2'
    inputs = [ordered]@{
      SOUND_MENU = @(1, @(10, 'Meow'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  's4' = [ordered]@{
    opcode = 'motion_glidesecstoxy'
    next = 's5'
    parent = 's3'
    inputs = [ordered]@{
      SECS = @(1, @(4, '1'))
      X = @(1, @(4, '-30'))
      Y = @(1, @(4, '-10'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  's5' = [ordered]@{
    opcode = 'looks_sayforsecs'
    next = 's6'
    parent = 's4'
    inputs = [ordered]@{
      MESSAGE = @(1, @(10, 'Follow me!'))
      SECS = @(1, @(4, '2'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  's6' = [ordered]@{
    opcode = 'control_wait'
    next = 's7'
    parent = 's5'
    inputs = [ordered]@{
      DURATION = @(1, @(4, '0.5'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  's7' = [ordered]@{
    opcode = 'event_broadcast'
    next = $null
    parent = 's6'
    inputs = [ordered]@{
      BROADCAST_INPUT = @(1, @(11, 'scene2', 'bc-scene2'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  's8' = [ordered]@{
    opcode = 'event_whenbroadcastreceived'
    next = 's9'
    parent = $null
    inputs = @{}
    fields = [ordered]@{
      BROADCAST_OPTION = @('scene2', 'bc-scene2')
    }
    shadow = $false
    topLevel = $true
    x = 240
    y = 280
  }
  's9' = [ordered]@{
    opcode = 'looks_sayforsecs'
    next = $null
    parent = 's8'
    inputs = [ordered]@{
      MESSAGE = @(1, @(10, 'Scene 2 starts now.'))
      SECS = @(1, @(4, '2'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
}

$project3 = [ordered]@{
  targets = @(
    (New-StageTarget -Broadcasts @{ 'bc-scene2' = 'scene2' }),
    (New-SpriteTarget -Name 'Sprite1' -Blocks $ex3Blocks -LayerOrder 1 -X -120 -Y -20)
  )
  monitors = @()
  extensions = @()
  meta = [ordered]@{
    semver = '3.0.0'
    vm = '11.2.0-feature-parity.2'
    agent = 'Generated for THYNK teacher references'
  }
}

Write-Sb3 -OutputPath (Join-Path $outDir 'book2_ch3_story_timeline_example.sb3') -ProjectObject $project3

# Example 4: Broadcasting chain with two sprites
$ex4Sprite1 = [ordered]@{
  'm1' = [ordered]@{
    opcode = 'event_whenflagclicked'
    next = 'm2'
    parent = $null
    inputs = @{}
    fields = @{}
    shadow = $false
    topLevel = $true
    x = 90
    y = 90
  }
  'm2' = [ordered]@{
    opcode = 'looks_sayforsecs'
    next = 'm3'
    parent = 'm1'
    inputs = [ordered]@{
      MESSAGE = @(1, @(10, 'Welcome to the show!'))
      SECS = @(1, @(4, '2'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'm3' = [ordered]@{
    opcode = 'event_broadcast'
    next = $null
    parent = 'm2'
    inputs = [ordered]@{
      BROADCAST_INPUT = @(1, @(11, 'scene1', 'bc-scene1'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'm4' = [ordered]@{
    opcode = 'event_whenbroadcastreceived'
    next = 'm5'
    parent = $null
    inputs = @{}
    fields = [ordered]@{
      BROADCAST_OPTION = @('scene1', 'bc-scene1')
    }
    shadow = $false
    topLevel = $true
    x = 90
    y = 250
  }
  'm5' = [ordered]@{
    opcode = 'looks_sayforsecs'
    next = 'm6'
    parent = 'm4'
    inputs = [ordered]@{
      MESSAGE = @(1, @(10, 'Hero enters.'))
      SECS = @(1, @(4, '2'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'm6' = [ordered]@{
    opcode = 'event_broadcast'
    next = $null
    parent = 'm5'
    inputs = [ordered]@{
      BROADCAST_INPUT = @(1, @(11, 'scene2', 'bc-scene2'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
}

$ex4Sprite2 = [ordered]@{
  'n1' = [ordered]@{
    opcode = 'event_whenbroadcastreceived'
    next = 'n2'
    parent = $null
    inputs = @{}
    fields = [ordered]@{
      BROADCAST_OPTION = @('scene1', 'bc-scene1')
    }
    shadow = $false
    topLevel = $true
    x = 360
    y = 110
  }
  'n2' = [ordered]@{
    opcode = 'looks_sayforsecs'
    next = $null
    parent = 'n1'
    inputs = [ordered]@{
      MESSAGE = @(1, @(10, 'Music starts.'))
      SECS = @(1, @(4, '2'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'n3' = [ordered]@{
    opcode = 'event_whenbroadcastreceived'
    next = 'n4'
    parent = $null
    inputs = @{}
    fields = [ordered]@{
      BROADCAST_OPTION = @('scene2', 'bc-scene2')
    }
    shadow = $false
    topLevel = $true
    x = 360
    y = 250
  }
  'n4' = [ordered]@{
    opcode = 'looks_sayforsecs'
    next = $null
    parent = 'n3'
    inputs = [ordered]@{
      MESSAGE = @(1, @(10, 'Next scene begins!'))
      SECS = @(1, @(4, '2'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
}

$project4 = [ordered]@{
  targets = @(
    (New-StageTarget -Broadcasts @{ 'bc-scene1' = 'scene1'; 'bc-scene2' = 'scene2' }),
    (New-SpriteTarget -Name 'Controller' -Blocks $ex4Sprite1 -LayerOrder 1 -X -120 -Y -20),
    (New-SpriteTarget -Name 'Responder' -Blocks $ex4Sprite2 -LayerOrder 2 -X 120 -Y -20)
  )
  monitors = @()
  extensions = @()
  meta = [ordered]@{
    semver = '3.0.0'
    vm = '11.2.0-feature-parity.2'
    agent = 'Generated for THYNK teacher references'
  }
}

Write-Sb3 -OutputPath (Join-Path $outDir 'book2_ch4_broadcast_chain_example.sb3') -ProjectObject $project4

# Mini Project 1: Dance Loop
$mini1Blocks = [ordered]@{
  'p1' = [ordered]@{
    opcode = 'event_whenflagclicked'
    next = 'p2'
    parent = $null
    inputs = @{}
    fields = @{}
    shadow = $false
    topLevel = $true
    x = 180
    y = 90
  }
  'p2' = [ordered]@{
    opcode = 'control_repeat'
    next = $null
    parent = 'p1'
    inputs = [ordered]@{
      TIMES = @(1, @(4, '10'))
      SUBSTACK = @(2, 'p3')
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'p3' = [ordered]@{
    opcode = 'motion_turnright'
    next = 'p4'
    parent = 'p2'
    inputs = [ordered]@{
      DEGREES = @(1, @(4, '30'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'p4' = [ordered]@{
    opcode = 'motion_movesteps'
    next = 'p5'
    parent = 'p3'
    inputs = [ordered]@{
      STEPS = @(1, @(4, '20'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'p5' = [ordered]@{
    opcode = 'looks_nextcostume'
    next = 'p6'
    parent = 'p4'
    inputs = @{}
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'p6' = [ordered]@{
    opcode = 'motion_turnleft'
    next = 'p7'
    parent = 'p5'
    inputs = [ordered]@{
      DEGREES = @(1, @(4, '20'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'p7' = [ordered]@{
    opcode = 'motion_movesteps'
    next = 'p8'
    parent = 'p6'
    inputs = [ordered]@{
      STEPS = @(1, @(4, '15'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'p8' = [ordered]@{
    opcode = 'control_wait'
    next = $null
    parent = 'p7'
    inputs = [ordered]@{
      DURATION = @(1, @(4, '0.2'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
}

$miniProject1 = [ordered]@{
  targets = @(
    (New-StageTarget -Broadcasts @{}),
    (New-SpriteTarget -Name 'Dancer' -Blocks $mini1Blocks -LayerOrder 1 -X 0 -Y 0)
  )
  monitors = @()
  extensions = @()
  meta = [ordered]@{
    semver = '3.0.0'
    vm = '11.2.0-feature-parity.2'
    agent = 'Generated for THYNK teacher references'
  }
}

Write-Sb3 -OutputPath (Join-Path $outDir 'book2_ch1_mini_dance_loop.sb3') -ProjectObject $miniProject1

# Mini Project 2: Pattern Artist (custom blocks + pen)
$mini2Blocks = [ordered]@{
  'q1' = [ordered]@{
    opcode = 'event_whenflagclicked'
    next = 'q2'
    parent = $null
    inputs = @{}
    fields = @{}
    shadow = $false
    topLevel = $true
    x = 280
    y = 80
  }
  'q2' = [ordered]@{
    opcode = 'pen_clear'
    next = 'q3'
    parent = 'q1'
    inputs = @{}
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'q3' = [ordered]@{
    opcode = 'pen_pendown'
    next = 'q4'
    parent = 'q2'
    inputs = @{}
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'q4' = [ordered]@{
    opcode = 'control_repeat'
    next = 'q12'
    parent = 'q3'
    inputs = [ordered]@{
      TIMES = @(1, @(4, '6'))
      SUBSTACK = @(2, 'q5')
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'q5' = [ordered]@{
    opcode = 'procedures_call'
    next = 'q6'
    parent = 'q4'
    inputs = [ordered]@{
      'arg-len' = @(1, @(4, '60'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
    mutation = [ordered]@{
      tagName = 'mutation'
      children = @()
      proccode = 'drawLine %s'
      argumentids = '["arg-len"]'
      warp = 'false'
    }
  }
  'q6' = [ordered]@{
    opcode = 'procedures_call'
    next = $null
    parent = 'q5'
    inputs = [ordered]@{
      'arg-deg' = @(1, @(4, '60'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
    mutation = [ordered]@{
      tagName = 'mutation'
      children = @()
      proccode = 'turnAngle %s'
      argumentids = '["arg-deg"]'
      warp = 'false'
    }
  }
  'q12' = [ordered]@{
    opcode = 'pen_penup'
    next = $null
    parent = 'q4'
    inputs = @{}
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'q7' = [ordered]@{
    opcode = 'procedures_definition'
    next = 'q8'
    parent = $null
    inputs = [ordered]@{
      custom_block = @(1, 'q7p')
    }
    fields = @{}
    shadow = $false
    topLevel = $true
    x = 50
    y = 80
  }
  'q7p' = [ordered]@{
    opcode = 'procedures_prototype'
    next = $null
    parent = 'q7'
    inputs = [ordered]@{
      'arg-len' = @(1, 'q7a')
    }
    fields = @{}
    shadow = $true
    topLevel = $false
    mutation = [ordered]@{
      tagName = 'mutation'
      children = @()
      proccode = 'drawLine %s'
      argumentids = '["arg-len"]'
      argumentnames = '["len"]'
      argumentdefaults = '["20"]'
      warp = 'false'
    }
  }
  'q7a' = [ordered]@{
    opcode = 'argument_reporter_string_number'
    next = $null
    parent = 'q7p'
    inputs = @{}
    fields = [ordered]@{
      VALUE = @('len', $null)
    }
    shadow = $true
    topLevel = $false
  }
  'q8' = [ordered]@{
    opcode = 'motion_movesteps'
    next = $null
    parent = 'q7'
    inputs = [ordered]@{
      STEPS = @(3, 'q8a', @(4, '20'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'q8a' = [ordered]@{
    opcode = 'argument_reporter_string_number'
    next = $null
    parent = 'q8'
    inputs = @{}
    fields = [ordered]@{
      VALUE = @('len', $null)
    }
    shadow = $false
    topLevel = $false
  }
  'q9' = [ordered]@{
    opcode = 'procedures_definition'
    next = 'q10'
    parent = $null
    inputs = [ordered]@{
      custom_block = @(1, 'q9p')
    }
    fields = @{}
    shadow = $false
    topLevel = $true
    x = 50
    y = 250
  }
  'q9p' = [ordered]@{
    opcode = 'procedures_prototype'
    next = $null
    parent = 'q9'
    inputs = [ordered]@{
      'arg-deg' = @(1, 'q9a')
    }
    fields = @{}
    shadow = $true
    topLevel = $false
    mutation = [ordered]@{
      tagName = 'mutation'
      children = @()
      proccode = 'turnAngle %s'
      argumentids = '["arg-deg"]'
      argumentnames = '["deg"]'
      argumentdefaults = '["30"]'
      warp = 'false'
    }
  }
  'q9a' = [ordered]@{
    opcode = 'argument_reporter_string_number'
    next = $null
    parent = 'q9p'
    inputs = @{}
    fields = [ordered]@{
      VALUE = @('deg', $null)
    }
    shadow = $true
    topLevel = $false
  }
  'q10' = [ordered]@{
    opcode = 'motion_turnright'
    next = $null
    parent = 'q9'
    inputs = [ordered]@{
      DEGREES = @(3, 'q10a', @(4, '30'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'q10a' = [ordered]@{
    opcode = 'argument_reporter_string_number'
    next = $null
    parent = 'q10'
    inputs = @{}
    fields = [ordered]@{
      VALUE = @('deg', $null)
    }
    shadow = $false
    topLevel = $false
  }
}

$miniProject2 = [ordered]@{
  targets = @(
    (New-StageTarget -Broadcasts @{}),
    (New-SpriteTarget -Name 'Artist' -Blocks $mini2Blocks -LayerOrder 1 -X 0 -Y 0)
  )
  monitors = @()
  extensions = @('pen')
  meta = [ordered]@{
    semver = '3.0.0'
    vm = '11.2.0-feature-parity.2'
    agent = 'Generated for THYNK teacher references'
  }
}

Write-Sb3 -OutputPath (Join-Path $outDir 'book2_ch2_mini_pattern_artist.sb3') -ProjectObject $miniProject2

# Mini Project 3: One-Minute Story
$mini3Controller = [ordered]@{
  'r1' = [ordered]@{
    opcode = 'event_whenflagclicked'
    next = 'r2'
    parent = $null
    inputs = @{}
    fields = @{}
    shadow = $false
    topLevel = $true
    x = 90
    y = 90
  }
  'r2' = [ordered]@{
    opcode = 'looks_sayforsecs'
    next = 'r3'
    parent = 'r1'
    inputs = [ordered]@{
      MESSAGE = @(1, @(10, 'Scene 1: We are ready to explore.'))
      SECS = @(1, @(4, '2'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'r3' = [ordered]@{
    opcode = 'event_broadcast'
    next = 'r4'
    parent = 'r2'
    inputs = [ordered]@{
      BROADCAST_INPUT = @(1, @(11, 'scene2', 'bc-story-scene2'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'r4' = [ordered]@{
    opcode = 'control_wait'
    next = 'r5'
    parent = 'r3'
    inputs = [ordered]@{
      DURATION = @(1, @(4, '0.5'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'r5' = [ordered]@{
    opcode = 'event_broadcast'
    next = $null
    parent = 'r4'
    inputs = [ordered]@{
      BROADCAST_INPUT = @(1, @(11, 'ending', 'bc-story-ending'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
}

$mini3Actor = [ordered]@{
  't1' = [ordered]@{
    opcode = 'event_whenbroadcastreceived'
    next = 't2'
    parent = $null
    inputs = @{}
    fields = [ordered]@{
      BROADCAST_OPTION = @('scene2', 'bc-story-scene2')
    }
    shadow = $false
    topLevel = $true
    x = 360
    y = 90
  }
  't2' = [ordered]@{
    opcode = 'motion_glidesecstoxy'
    next = 't3'
    parent = 't1'
    inputs = [ordered]@{
      SECS = @(1, @(4, '1'))
      X = @(1, @(4, '40'))
      Y = @(1, @(4, '10'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  't3' = [ordered]@{
    opcode = 'sound_playuntildone'
    next = 't4'
    parent = 't2'
    inputs = [ordered]@{
      SOUND_MENU = @(1, @(10, 'Meow'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  't4' = [ordered]@{
    opcode = 'looks_sayforsecs'
    next = $null
    parent = 't3'
    inputs = [ordered]@{
      MESSAGE = @(1, @(10, 'Scene 2: I found the way!'))
      SECS = @(1, @(4, '2'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  't5' = [ordered]@{
    opcode = 'event_whenbroadcastreceived'
    next = 't6'
    parent = $null
    inputs = @{}
    fields = [ordered]@{
      BROADCAST_OPTION = @('ending', 'bc-story-ending')
    }
    shadow = $false
    topLevel = $true
    x = 360
    y = 250
  }
  't6' = [ordered]@{
    opcode = 'looks_sayforsecs'
    next = $null
    parent = 't5'
    inputs = [ordered]@{
      MESSAGE = @(1, @(10, 'The End. Great teamwork!'))
      SECS = @(1, @(4, '2'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
}

$miniProject3 = [ordered]@{
  targets = @(
    (New-StageTarget -Broadcasts @{ 'bc-story-scene2' = 'scene2'; 'bc-story-ending' = 'ending' }),
    (New-SpriteTarget -Name 'Narrator' -Blocks $mini3Controller -LayerOrder 1 -X -120 -Y -20),
    (New-SpriteTarget -Name 'Explorer' -Blocks $mini3Actor -LayerOrder 2 -X 120 -Y -20)
  )
  monitors = @()
  extensions = @()
  meta = [ordered]@{
    semver = '3.0.0'
    vm = '11.2.0-feature-parity.2'
    agent = 'Generated for THYNK teacher references'
  }
}

Write-Sb3 -OutputPath (Join-Path $outDir 'book2_ch3_mini_one_minute_story.sb3') -ProjectObject $miniProject3

# Mini Project 4: Final Showreel (all chapter skills)
$mini4Controller = [ordered]@{
  'u1' = [ordered]@{
    opcode = 'event_whenflagclicked'
    next = 'u2'
    parent = $null
    inputs = @{}
    fields = @{}
    shadow = $false
    topLevel = $true
    x = 80
    y = 70
  }
  'u2' = [ordered]@{
    opcode = 'looks_sayforsecs'
    next = 'u3'
    parent = 'u1'
    inputs = [ordered]@{
      MESSAGE = @(1, @(10, 'Welcome to THYNK Showreel'))
      SECS = @(1, @(4, '2'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'u3' = [ordered]@{
    opcode = 'event_broadcast'
    next = 'u4'
    parent = 'u2'
    inputs = [ordered]@{
      BROADCAST_INPUT = @(1, @(11, 'intro_done', 'bc-intro-done'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'u4' = [ordered]@{
    opcode = 'control_wait'
    next = 'u5'
    parent = 'u3'
    inputs = [ordered]@{
      DURATION = @(1, @(4, '0.5'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'u5' = [ordered]@{
    opcode = 'event_broadcast'
    next = 'u6'
    parent = 'u4'
    inputs = [ordered]@{
      BROADCAST_INPUT = @(1, @(11, 'demo_start', 'bc-demo-start'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'u6' = [ordered]@{
    opcode = 'control_wait'
    next = 'u7'
    parent = 'u5'
    inputs = [ordered]@{
      DURATION = @(1, @(4, '1'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'u7' = [ordered]@{
    opcode = 'event_broadcast'
    next = $null
    parent = 'u6'
    inputs = [ordered]@{
      BROADCAST_INPUT = @(1, @(11, 'show_end', 'bc-show-end'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
}

$mini4Performer = [ordered]@{
  'v1' = [ordered]@{
    opcode = 'event_whenbroadcastreceived'
    next = 'v2'
    parent = $null
    inputs = @{}
    fields = [ordered]@{
      BROADCAST_OPTION = @('intro_done', 'bc-intro-done')
    }
    shadow = $false
    topLevel = $true
    x = 330
    y = 70
  }
  'v2' = [ordered]@{
    opcode = 'control_repeat'
    next = $null
    parent = 'v1'
    inputs = [ordered]@{
      TIMES = @(1, @(4, '8'))
      SUBSTACK = @(2, 'v3')
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'v3' = [ordered]@{
    opcode = 'looks_nextcostume'
    next = 'v4'
    parent = 'v2'
    inputs = @{}
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'v4' = [ordered]@{
    opcode = 'motion_movesteps'
    next = 'v5'
    parent = 'v3'
    inputs = [ordered]@{
      STEPS = @(1, @(4, '8'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'v5' = [ordered]@{
    opcode = 'control_wait'
    next = $null
    parent = 'v4'
    inputs = [ordered]@{
      DURATION = @(1, @(4, '0.1'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'v6' = [ordered]@{
    opcode = 'event_whenbroadcastreceived'
    next = 'v7'
    parent = $null
    inputs = @{}
    fields = [ordered]@{
      BROADCAST_OPTION = @('demo_start', 'bc-demo-start')
    }
    shadow = $false
    topLevel = $true
    x = 330
    y = 250
  }
  'v7' = [ordered]@{
    opcode = 'procedures_call'
    next = 'v8'
    parent = 'v6'
    inputs = [ordered]@{
      'arg-jump' = @(1, @(4, '35'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
    mutation = [ordered]@{
      tagName = 'mutation'
      children = @()
      proccode = 'jump %s'
      argumentids = '["arg-jump"]'
      warp = 'false'
    }
  }
  'v8' = [ordered]@{
    opcode = 'sound_playuntildone'
    next = $null
    parent = 'v7'
    inputs = [ordered]@{
      SOUND_MENU = @(1, @(10, 'Meow'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'v9' = [ordered]@{
    opcode = 'procedures_definition'
    next = 'v10'
    parent = $null
    inputs = [ordered]@{
      custom_block = @(1, 'v9p')
    }
    fields = @{}
    shadow = $false
    topLevel = $true
    x = 570
    y = 70
  }
  'v9p' = [ordered]@{
    opcode = 'procedures_prototype'
    next = $null
    parent = 'v9'
    inputs = [ordered]@{
      'arg-jump' = @(1, 'v9a')
    }
    fields = @{}
    shadow = $true
    topLevel = $false
    mutation = [ordered]@{
      tagName = 'mutation'
      children = @()
      proccode = 'jump %s'
      argumentids = '["arg-jump"]'
      argumentnames = '["height"]'
      argumentdefaults = '["20"]'
      warp = 'false'
    }
  }
  'v9a' = [ordered]@{
    opcode = 'argument_reporter_string_number'
    next = $null
    parent = 'v9p'
    inputs = @{}
    fields = [ordered]@{
      VALUE = @('height', $null)
    }
    shadow = $true
    topLevel = $false
  }
  'v10' = [ordered]@{
    opcode = 'motion_changeyby'
    next = 'v11'
    parent = 'v9'
    inputs = [ordered]@{
      DY = @(3, 'v10a', @(4, '20'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'v10a' = [ordered]@{
    opcode = 'argument_reporter_string_number'
    next = $null
    parent = 'v10'
    inputs = @{}
    fields = [ordered]@{
      VALUE = @('height', $null)
    }
    shadow = $false
    topLevel = $false
  }
  'v11' = [ordered]@{
    opcode = 'control_wait'
    next = 'v12'
    parent = 'v10'
    inputs = [ordered]@{
      DURATION = @(1, @(4, '0.1'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'v12' = [ordered]@{
    opcode = 'motion_changeyby'
    next = $null
    parent = 'v11'
    inputs = [ordered]@{
      DY = @(3, 'v13', @(4, '-20'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'v13' = [ordered]@{
    opcode = 'operator_multiply'
    next = $null
    parent = 'v12'
    inputs = [ordered]@{
      NUM1 = @(3, 'v13a', @(4, ''))
      NUM2 = @(1, @(4, '-1'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
  'v13a' = [ordered]@{
    opcode = 'argument_reporter_string_number'
    next = $null
    parent = 'v13'
    inputs = @{}
    fields = [ordered]@{
      VALUE = @('height', $null)
    }
    shadow = $false
    topLevel = $false
  }
  'v14' = [ordered]@{
    opcode = 'event_whenbroadcastreceived'
    next = 'v15'
    parent = $null
    inputs = @{}
    fields = [ordered]@{
      BROADCAST_OPTION = @('show_end', 'bc-show-end')
    }
    shadow = $false
    topLevel = $true
    x = 330
    y = 430
  }
  'v15' = [ordered]@{
    opcode = 'looks_sayforsecs'
    next = $null
    parent = 'v14'
    inputs = [ordered]@{
      MESSAGE = @(1, @(10, 'Show complete. Great job!'))
      SECS = @(1, @(4, '2'))
    }
    fields = @{}
    shadow = $false
    topLevel = $false
  }
}

$miniProject4 = [ordered]@{
  targets = @(
    (New-StageTarget -Broadcasts @{ 'bc-intro-done' = 'intro_done'; 'bc-demo-start' = 'demo_start'; 'bc-show-end' = 'show_end' }),
    (New-SpriteTarget -Name 'Host' -Blocks $mini4Controller -LayerOrder 1 -X -150 -Y 0),
    (New-SpriteTarget -Name 'Performer' -Blocks $mini4Performer -LayerOrder 2 -X 90 -Y 0)
  )
  monitors = @()
  extensions = @()
  meta = [ordered]@{
    semver = '3.0.0'
    vm = '11.2.0-feature-parity.2'
    agent = 'Generated for THYNK teacher references'
  }
}

Write-Sb3 -OutputPath (Join-Path $outDir 'book2_ch4_mini_final_showreel.sb3') -ProjectObject $miniProject4

Write-Host "Created Book 2 example and mini-project Scratch programs in: $outDir"