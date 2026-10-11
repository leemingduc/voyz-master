$ErrorActionPreference = 'Stop'

# Creates a native PowerPoint deck with editable shapes, transitions, and
# lightweight entrance animations. Requires Microsoft PowerPoint on Windows.

$outDir = Join-Path $PSScriptRoot '..\presentation'
New-Item -ItemType Directory -Path $outDir -Force | Out-Null
$outFile = Join-Path $outDir 'AIVIVU_Gioi_thieu_ung_dung.pptx'
$pdfFile = Join-Path $outDir 'AIVIVU_Gioi_thieu_ung_dung.pdf'
$earth = (Resolve-Path (Join-Path $PSScriptRoot '..\assets\images\cosmic_earth.png')).Path

function Rgb([string]$hex) {
  $h = $hex.TrimStart('#')
  return [Convert]::ToInt32($h.Substring(0,2),16) + 256*[Convert]::ToInt32($h.Substring(2,2),16) + 65536*[Convert]::ToInt32($h.Substring(4,2),16)
}

$Colors = @{
  Ink = (Rgb '06070B'); Surface = (Rgb '10131A'); Panel = (Rgb '161B27')
  Cyan = (Rgb '00E5FF'); Violet = (Rgb '8B5CF6'); Pink = (Rgb 'FF3366')
  White = (Rgb 'F8FAFC'); Muted = (Rgb '94A3B8'); Line = (Rgb '283245')
  Green = (Rgb '22C55E'); Orange = (Rgb 'FF9E45'); Blue = (Rgb '4FACEF')
}

$msoFalse = 0; $msoTrue = -1
$msoShapeRectangle = 1; $msoShapeRoundedRectangle = 5; $msoShapeOval = 9
$msoShapeLine = 9; $msoShapeArc = 25
$msoTextOrientationHorizontal = 1
$msoAnimEffectAppear = 1; $msoAnimTriggerAfterPrevious = 3
$ppSaveAsOpenXMLPresentation = 24; $ppSaveAsPDF = 32

$pp = New-Object -ComObject PowerPoint.Application
$pp.Visible = $msoTrue
$pres = $pp.Presentations.Add()
$pres.PageSetup.SlideWidth = 960
$pres.PageSetup.SlideHeight = 540

function Add-Shape($slide, [int]$type, [double]$x, [double]$y, [double]$w, [double]$h, [int]$fill, [int]$line = 0, [double]$radius = 0) {
  $shape = $slide.Shapes.AddShape($type, $x, $y, $w, $h)
  $shape.Fill.Visible = $msoTrue
  $shape.Fill.Solid()
  $shape.Fill.ForeColor.RGB = $fill
  if ($line -eq 0) { $shape.Line.Visible = $msoFalse } else { $shape.Line.Visible = $msoTrue; $shape.Line.ForeColor.RGB = $line; $shape.Line.Weight = 1 }
  return $shape
}

function Add-Text($slide, [string]$text, [double]$x, [double]$y, [double]$w, [double]$h, [double]$size = 18, [int]$color = 0, [string]$font = 'Aptos', [int]$bold = 0, [int]$align = 1) {
  if ($color -eq 0) { $color = $Colors.White }
  $shape = $slide.Shapes.AddTextbox($msoTextOrientationHorizontal, $x, $y, $w, $h)
  $shape.TextFrame.MarginLeft = 0; $shape.TextFrame.MarginRight = 0
  $shape.TextFrame.MarginTop = 0; $shape.TextFrame.MarginBottom = 0
  $shape.TextFrame.WordWrap = $msoTrue
  $shape.TextFrame.TextRange.Text = $text
  $shape.TextFrame.TextRange.Font.Name = $font
  $shape.TextFrame.TextRange.Font.Size = $size
  $shape.TextFrame.TextRange.Font.Bold = $bold
  $shape.TextFrame.TextRange.Font.Color.RGB = $color
  $shape.TextFrame.TextRange.ParagraphFormat.Alignment = $align
  return $shape
}

function Add-Line($slide,[double]$x1,[double]$y1,[double]$x2,[double]$y2,[int]$color,[double]$weight=1) {
  $l = $slide.Shapes.AddLine($x1,$y1,$x2,$y2); $l.Line.ForeColor.RGB=$color; $l.Line.Weight=$weight; return $l
}

function Add-Background($slide, [switch]$Starfield) {
  $bg = Add-Shape $slide $msoShapeRectangle 0 0 960 540 $Colors.Ink
  if ($Starfield) {
    foreach ($s in @(@(70,72,3),@(148,110,2),@(760,82,3),@(880,155,2),@(690,410,3),@(110,450,2),@(850,470,2),@(505,65,2),@(430,470,2))) {
      $dot = Add-Shape $slide $msoShapeOval $s[0] $s[1] $s[2] $s[2] $Colors.Cyan
      $dot.Fill.Transparency = 0.20
    }
  }
  return $bg
}

function Add-Brand($slide, [int]$number, [string]$section = 'AIVIVU') {
  $mark = Add-Text $slide $section 44 28 150 24 12 $Colors.Cyan 'Aptos Display' 1 1
  Add-Line $slide 44 57 916 57 $Colors.Line 1 | Out-Null
  Add-Text $slide ('0{0}' -f $number) 885 28 32 20 11 $Colors.Muted 'Aptos' 0 3 | Out-Null
}

function Add-Anim($slide, $shape, [double]$delay = 0.05) {
  try {
    $effect = $slide.TimeLine.MainSequence.AddEffect($shape, $msoAnimEffectAppear, $msoAnimTriggerAfterPrevious, 1)
    $effect.Timing.Duration = 0.22
    $effect.Timing.TriggerDelayTime = $delay
  } catch { }
}

function Add-Phone($slide, [double]$x, [double]$y, [double]$w, [double]$h, [string]$label='LIVE PREVIEW') {
  $shadow = Add-Shape $slide $msoShapeRoundedRectangle ($x+8) ($y+10) $w $h (Rgb '010205')
  $phone = Add-Shape $slide $msoShapeRoundedRectangle $x $y $w $h (Rgb '0A0E18') $Colors.Line
  $screen = Add-Shape $slide $msoShapeRoundedRectangle ($x+8) ($y+8) ($w-16) ($h-16) $Colors.Surface
  $screen.Line.Visible = $msoFalse
  $notch = Add-Shape $slide $msoShapeRoundedRectangle ($x+$w/2-28) ($y+10) 56 8 $Colors.Ink
  $tag = Add-Text $slide $label ($x+18) ($y+22) ($w-36) 14 8 $Colors.Muted 'Aptos' 1 2
  return @($shadow,$phone,$screen,$notch,$tag)
}

function Add-Card($slide,[double]$x,[double]$y,[double]$w,[double]$h,[int]$accent,[string]$title,[string]$body,[string]$icon='•') {
  $card = Add-Shape $slide $msoShapeRoundedRectangle $x $y $w $h $Colors.Panel $Colors.Line
  $accentBar = Add-Shape $slide $msoShapeRoundedRectangle ($x+14) ($y+15) 34 34 $accent
  Add-Text $slide $icon ($x+14) ($y+19) 34 24 16 $Colors.White 'Segoe UI Symbol' 1 2 | Out-Null
  Add-Text $slide $title ($x+60) ($y+14) ($w-74) 22 14 $Colors.White 'Aptos Display' 1 1 | Out-Null
  Add-Text $slide $body ($x+60) ($y+40) ($w-76) ($h-50) 10.5 $Colors.Muted 'Aptos' 0 1 | Out-Null
  return $card
}

function Add-Arrow($slide,[double]$x,[double]$y,[int]$color=$Colors.Cyan) {
  Add-Line $slide $x $y ($x+46) $y $color 2 | Out-Null
  Add-Line $slide ($x+37) ($y-7) ($x+46) $y $color 2 | Out-Null
  Add-Line $slide ($x+37) ($y+7) ($x+46) $y $color 2 | Out-Null
}

$blank = 12
$slides = @()

# 1. Hero
$s = $pres.Slides.Add(1,$blank); $slides += $s
$s.Shapes.AddPicture($earth,$msoFalse,$msoTrue,0,0,960,540) | Out-Null
$veil = Add-Shape $s $msoShapeRectangle 0 0 960 540 $Colors.Ink; $veil.Fill.Transparency = 0.24
$dark = Add-Shape $s $msoShapeRectangle 0 350 960 190 $Colors.Ink; $dark.Fill.Transparency = 0.12
$eyebrow = Add-Text $s 'CÔNG BỐ ỨNG DỤNG' 70 84 310 24 14 $Colors.Cyan 'Aptos' 1 1
$title = Add-Text $s 'AIVIVU' 66 124 500 65 49 $Colors.White 'Aptos Display' 1 1
$sub = Add-Text $s 'AI Travel Advisor' 70 192 440 34 24 $Colors.White 'Aptos' 0 1
$tag = Add-Text $s 'Từ một ý định — đến một hành trình rõ ràng.' 70 252 460 30 17 $Colors.Muted 'Aptos' 0 1
$pill = Add-Shape $s $msoShapeRoundedRectangle 70 312 214 34 $Colors.Cyan
$pill.Fill.Transparency = 0.12
Add-Text $s 'PLAN • EXPLORE • GO' 85 322 184 14 10 $Colors.White 'Aptos' 1 2 | Out-Null
Add-Text $s '2026  |  TRAVEL, MADE PERSONAL' 70 485 360 16 9 $Colors.Muted 'Aptos' 1 1 | Out-Null
Add-Anim $s $eyebrow 0.1; Add-Anim $s $title 0.15; Add-Anim $s $sub 0.1; Add-Anim $s $tag 0.1; Add-Anim $s $pill 0.1

# 2. Purpose
$s = $pres.Slides.Add(2,$blank); $slides += $s; Add-Background $s -Starfield | Out-Null; Add-Brand $s 2 'AIVIVU / WHY'
$h = Add-Text $s 'Du lịch không nên bắt đầu
với hàng chục tab.' 54 104 570 108 34 $Colors.White 'Aptos Display' 1 1
$accent = Add-Text $s 'AIVIVU biến nhu cầu mơ hồ thành lựa chọn có căn cứ.' 56 230 580 30 17 $Colors.Cyan 'Aptos' 0 1
$q = Add-Shape $s $msoShapeRoundedRectangle 688 100 200 250 $Colors.Panel $Colors.Line
Add-Text $s '“' 718 112 70 60 52 $Colors.Pink 'Georgia' 1 1 | Out-Null
Add-Text $s 'Đi đâu cho 3 ngày,
vừa chill vừa hợp túi tiền?' 716 185 144 62 16 $Colors.White 'Aptos Display' 1 2 | Out-Null
Add-Text $s 'Một câu hỏi. Một luồng trả lời.' 710 302 158 28 10 $Colors.Muted 'Aptos' 0 2 | Out-Null
$a = Add-Card $s 56 340 250 95 $Colors.Cyan 'Tối giản' 'Một nơi cho toàn bộ hành trình.' '1'
$b = Add-Card $s 330 340 250 95 $Colors.Violet 'Cá nhân hóa' 'Theo thời gian, ngân sách, sở thích.' '2'
$c = Add-Card $s 604 340 250 95 $Colors.Pink 'Có thể hành động' 'Từ gợi ý đến lịch trình đã lưu.' '3'
Add-Anim $s $h 0.1; Add-Anim $s $accent 0.1; Add-Anim $s $q 0.15; Add-Anim $s $a 0.1; Add-Anim $s $b 0.08; Add-Anim $s $c 0.08

# 3. Journey flow
$s = $pres.Slides.Add(3,$blank); $slides += $s; Add-Background $s -Starfield | Out-Null; Add-Brand $s 3 'AIVIVU / FLOW'
$h = Add-Text $s 'Một cuộc trò chuyện.
Một chuyến đi hoàn chỉnh.' 54 93 560 85 31 $Colors.White 'Aptos Display' 1 1
$sub = Add-Text $s 'Luồng cốt lõi: mô tả → gợi ý → khám phá → lập kế hoạch → lưu.' 56 188 650 22 14 $Colors.Muted 'Aptos' 0 1
$stages = @(
  @{x=54;c=$Colors.Cyan;n='01';t='Mô tả';d='Điều bạn muốn'},
  @{x=228;c=$Colors.Violet;n='02';t='Gợi ý';d='Các lựa chọn AI'},
  @{x=402;c=$Colors.Pink;n='03';t='Khám phá';d='Điểm đến phù hợp'},
  @{x=576;c=$Colors.Orange;n='04';t='Lịch trình';d='Ngày & chi phí'},
  @{x=750;c=$Colors.Green;n='05';t='Lưu chuyến';d='Sẵn sàng lên đường'}
)
foreach($v in $stages) {
  $bubble=Add-Shape $s $msoShapeOval $v.x 277 110 110 $Colors.Panel $v.c
  $num=Add-Text $s $v.n ($v.x+20) 295 70 18 12 $v.c 'Aptos' 1 2
  $name=Add-Text $s $v.t ($v.x+9) 327 92 20 15 $Colors.White 'Aptos Display' 1 2
  $desc=Add-Text $s $v.d ($v.x-10) 404 130 28 10 $Colors.Muted 'Aptos' 0 2
  if($v.x -ne 750) { Add-Arrow $s ($v.x+118) 332 $v.c }
  Add-Anim $s $bubble 0.11; Add-Anim $s $num 0.02; Add-Anim $s $name 0.02
}

# 4. Smart Planner
$s = $pres.Slides.Add(4,$blank); $slides += $s; Add-Background $s -Starfield | Out-Null; Add-Brand $s 4 'AIVIVU / SMART PLANNER'
$h = Add-Text $s 'Bắt đầu bằng điều
bạn thật sự muốn.' 54 101 360 84 30 $Colors.White 'Aptos Display' 1 1
$sub = Add-Text $s 'Smart Planner đặt ngữ cảnh trước khi gợi ý.' 56 201 340 38 14 $Colors.Muted 'Aptos' 0 1
$one = Add-Card $s 54 286 316 70 $Colors.Cyan 'Nhập tự nhiên' 'Ví dụ: “3 ngày ở Đà Lạt, đi cùng bạn, chi phí vừa phải.”' '↗'
$two = Add-Card $s 54 374 316 70 $Colors.Violet 'Nhận phương án' 'AI hỏi thêm khi thiếu dữ kiện, rồi đề xuất các lựa chọn.' '✦'
$p = Add-Phone $s 570 64 230 412 'SMART PLANNER'
Add-Text $s 'AIVIVU' 596 105 178 20 15 $Colors.Cyan 'Aptos Display' 1 2 | Out-Null
$bubble1 = Add-Shape $s $msoShapeRoundedRectangle 592 149 184 53 (Rgb '1A2941') $Colors.Line
Add-Text $s '3 ngày ở Đà Lạt,
đi cùng bạn, chill & vừa túi tiền.' 603 159 165 35 10 $Colors.White 'Aptos' 0 1 | Out-Null
$bubble2 = Add-Shape $s $msoShapeRoundedRectangle 592 220 184 55 (Rgb '211B35') $Colors.Violet
Add-Text $s 'Bạn thích săn mây, cafe
hay trải nghiệm thiên nhiên?' 603 231 163 33 10 $Colors.White 'Aptos' 0 1 | Out-Null
$chip1=Add-Shape $s $msoShapeRoundedRectangle 592 296 83 24 $Colors.Cyan; $chip1.Fill.Transparency=0.74
$chip2=Add-Shape $s $msoShapeRoundedRectangle 683 296 92 24 $Colors.Pink; $chip2.Fill.Transparency=0.74
Add-Text $s 'Săn mây' 599 302 70 10 8.5 $Colors.Cyan 'Aptos' 1 2 | Out-Null
Add-Text $s 'Thiên nhiên' 690 302 80 10 8.5 $Colors.Pink 'Aptos' 1 2 | Out-Null
$input=Add-Shape $s $msoShapeRoundedRectangle 592 412 184 32 (Rgb '0C111C') $Colors.Line
Add-Text $s 'Mô tả chuyến đi của bạn…' 603 422 150 12 8.5 $Colors.Muted 'Aptos' 0 1 | Out-Null
Add-Anim $s $h 0.1; Add-Anim $s $sub 0.1; Add-Anim $s $one 0.1; Add-Anim $s $two 0.1; Add-Anim $s $p[1] 0.15; Add-Anim $s $bubble1 0.15; Add-Anim $s $bubble2 0.12; Add-Anim $s $chip1 0.1; Add-Anim $s $chip2 0.05

# 5. Explore & decision
$s = $pres.Slides.Add(5,$blank); $slides += $s; Add-Background $s -Starfield | Out-Null; Add-Brand $s 5 'AIVIVU / EXPLORE'
$h=Add-Text $s 'Không chỉ “đi đâu”.
Mà là “vì sao nên đi”.' 54 92 510 85 30 $Colors.White 'Aptos Display' 1 1
$sub=Add-Text $s 'Mỗi lựa chọn được mở rộng thành thông tin đủ để ra quyết định.' 56 190 520 24 14 $Colors.Muted 'Aptos' 0 1
$items=@(
 @{x=54;y=270;c=$Colors.Cyan;t='Khám phá điểm đến';d='Gợi ý nổi bật, đánh giá, trải nghiệm phù hợp.';i='◉'},
 @{x=332;y=270;c=$Colors.Violet;t='So sánh điểm đến';d='Đặt 2–3 nơi cạnh nhau theo chi phí, thời tiết, hoạt động.';i='⇄'},
 @{x=610;y=270;c=$Colors.Pink;t='Thời điểm lý tưởng';d='Đọc mùa, nhiệt độ, lượng mưa và lời khuyên theo tháng.';i='◷'}
)
foreach($v in $items){$c=Add-Card $s $v.x $v.y 246 142 $v.c $v.t $v.d $v.i;Add-Anim $s $c 0.12}
$caption=Add-Text $s 'Điều cần biết xuất hiện đúng lúc — không làm người dùng ngợp thông tin.' 55 446 760 22 13 $Colors.White 'Aptos' 0 1
Add-Anim $s $h 0.1;Add-Anim $s $sub 0.1;Add-Anim $s $caption 0.15

# 6. Plan details
$s = $pres.Slides.Add(6,$blank); $slides += $s; Add-Background $s -Starfield | Out-Null; Add-Brand $s 6 'AIVIVU / PLAN'
$h=Add-Text $s 'Biến gợi ý thành
kế hoạch có thể theo.' 54 94 400 85 30 $Colors.White 'Aptos Display' 1 1
$sub=Add-Text $s 'Lịch trình, ngân sách và tiền tệ hiển thị trong cùng một trải nghiệm.' 56 194 430 42 14 $Colors.Muted 'Aptos' 0 1
$stat1=Add-Shape $s $msoShapeRoundedRectangle 55 282 190 73 $Colors.Panel $Colors.Line
Add-Text $s '01' 71 297 32 17 13 $Colors.Cyan 'Aptos' 1 1 | Out-Null; Add-Text $s 'Lịch trình theo ngày' 71 321 155 16 12 $Colors.White 'Aptos' 1 1 | Out-Null
$stat2=Add-Shape $s $msoShapeRoundedRectangle 55 373 190 73 $Colors.Panel $Colors.Line
Add-Text $s '02' 71 388 32 17 13 $Colors.Violet 'Aptos' 1 1 | Out-Null; Add-Text $s 'Ngân sách ước tính*' 71 412 155 16 12 $Colors.White 'Aptos' 1 1 | Out-Null
$stat3=Add-Shape $s $msoShapeRoundedRectangle 264 327 190 73 $Colors.Panel $Colors.Line
Add-Text $s '03' 280 342 32 17 13 $Colors.Pink 'Aptos' 1 1 | Out-Null; Add-Text $s 'Lưu để quay lại' 280 366 155 16 12 $Colors.White 'Aptos' 1 1 | Out-Null
$p=Add-Phone $s 602 63 222 412 'TRIP PLAN'
Add-Text $s 'Đà Lạt • 3 ngày' 620 106 185 18 14 $Colors.White 'Aptos Display' 1 1 | Out-Null
$date=Add-Text $s '15–17 OCT  •  2 NGƯỜI' 620 132 185 12 8.5 $Colors.Cyan 'Aptos' 1 1
foreach($row in @(@('DAY 1','Check-in • cafe • chợ đêm',$Colors.Cyan),@('DAY 2','Săn mây • đồi chè • BBQ',$Colors.Violet),@('DAY 3','Bảo tàng • mua quà • về nhà',$Colors.Pink))){
  $r=Add-Shape $s $msoShapeRoundedRectangle 620 (161 + 67*([array]::IndexOf(@('DAY 1','DAY 2','DAY 3'),$row[0]))) 184 53 $Colors.Panel $Colors.Line
  Add-Text $s $row[0] 633 (172 + 67*([array]::IndexOf(@('DAY 1','DAY 2','DAY 3'),$row[0]))) 45 12 8 $row[2] 'Aptos' 1 1 | Out-Null
  Add-Text $s $row[1] 633 (190 + 67*([array]::IndexOf(@('DAY 1','DAY 2','DAY 3'),$row[0]))) 155 15 9.5 $Colors.White 'Aptos' 0 1 | Out-Null
}
$budget=Add-Shape $s $msoShapeRoundedRectangle 620 371 184 42 (Rgb '172035') $Colors.Violet
Add-Text $s 'Ước tính  4.8M VND  ›' 634 385 154 14 10 $Colors.White 'Aptos' 1 2 | Out-Null
Add-Text $s '*Mức chi do AI ước tính; tỷ giá hiển thị là tham khảo.' 55 470 440 16 9 $Colors.Muted 'Aptos' 0 1 | Out-Null
Add-Anim $s $h 0.1;Add-Anim $s $sub 0.1;Add-Anim $s $stat1 0.1;Add-Anim $s $stat2 0.07;Add-Anim $s $stat3 0.07;Add-Anim $s $p[1] 0.15;Add-Anim $s $date 0.1;Add-Anim $s $budget 0.2

# 7. AI tools hub
$s = $pres.Slides.Add(7,$blank); $slides += $s; Add-Background $s -Starfield | Out-Null; Add-Brand $s 7 'AIVIVU / AI TOOLS'
$h=Add-Text $s 'Một trợ lý du lịch.
Ba góc nhìn thông minh.' 54 93 475 82 30 $Colors.White 'Aptos Display' 1 1
$sub=Add-Text $s 'Từ chat tự do đến so sánh và chọn đúng thời điểm đi.' 56 191 500 24 14 $Colors.Muted 'Aptos' 0 1
$hub=Add-Phone $s 618 61 220 410 'AI TOOLS'
Add-Text $s 'Công cụ AI' 641 105 175 23 15 $Colors.White 'Aptos Display' 1 1 | Out-Null
$hubCards=@(@(155,$Colors.Pink,'AI Chatbot','Hỏi mọi điều về chuyến đi','✦'),@(235,$Colors.Cyan,'So sánh điểm đến','So sánh 2–3 lựa chọn','⇄'),@(315,$Colors.Green,'Thời điểm tốt nhất','Đọc mùa và lên lịch','◷'))
foreach($r in $hubCards){$card=Add-Shape $s $msoShapeRoundedRectangle 640 $r[0] 177 61 $Colors.Panel $Colors.Line; $ic=Add-Shape $s $msoShapeRoundedRectangle 651 ($r[0]+12) 35 35 $r[1]; Add-Text $s $r[4] 651 ($r[0]+20) 35 14 12 $Colors.White 'Segoe UI Symbol' 1 2 | Out-Null; Add-Text $s $r[2] 695 ($r[0]+13) 112 15 10 $Colors.White 'Aptos' 1 1 | Out-Null;Add-Text $s $r[3] 695 ($r[0]+31) 112 12 8.5 $Colors.Muted 'Aptos' 0 1 | Out-Null;Add-Anim $s $card 0.1}
$card1=Add-Card $s 54 274 480 62 $Colors.Pink 'AI Chatbot' 'Câu hỏi về visa, văn hóa, chi phí, mẹo đi lại… trong giao diện trò chuyện.' '✦'
$card2=Add-Card $s 54 350 480 62 $Colors.Cyan 'AI Compare' 'Đặt các điểm đến cạnh nhau theo 4 khía cạnh: chi phí, thời tiết, hoạt động, ẩm thực.' '⇄'
$card3=Add-Card $s 54 426 480 62 $Colors.Green 'Best Time' 'Xem dữ liệu theo 12 tháng, mùa nổi bật và những mẹo nên biết.' '◷'
Add-Anim $s $h 0.1;Add-Anim $s $sub 0.1;Add-Anim $s $hub[1] 0.15;Add-Anim $s $card1 0.1;Add-Anim $s $card2 0.08;Add-Anim $s $card3 0.08

# 8. Product qualities
$s = $pres.Slides.Add(8,$blank); $slides += $s; Add-Background $s -Starfield | Out-Null; Add-Brand $s 8 'AIVIVU / EXPERIENCE'
$h=Add-Text $s 'Đủ thông minh để hữu ích.
Đủ gần gũi để dễ dùng.' 54 91 600 85 30 $Colors.White 'Aptos Display' 1 1
$sub=Add-Text $s 'Trải nghiệm được xây quanh chuyến đi của người dùng, không phải quanh công nghệ.' 56 190 650 24 14 $Colors.Muted 'Aptos' 0 1
$features=@(
 @{x=54;y=270;c=$Colors.Cyan;t='Đa ngôn ngữ';d='Việt • English • 한국어';i='A'},
 @{x=278;y=270;c=$Colors.Violet;t='Lưu & tiếp tục';d='Giữ lại cuộc hội thoại và chuyến đi.';i='↺'},
 @{x=502;y=270;c=$Colors.Pink;t='Kết nối bạn bè';d='Chia sẻ điểm đến, trò chuyện cùng nhau.';i='◌'},
 @{x=726;y=270;c=$Colors.Green;t='Hiệu năng có chủ đích';d='Cache kết quả AI để phản hồi mượt hơn.';i='↯'}
)
foreach($v in $features){$card=Add-Card $s $v.x $v.y 190 144 $v.c $v.t $v.d $v.i;Add-Anim $s $card 0.11}
$line=Add-Text $s 'AIVIVU kết hợp AI, dữ liệu hành trình và giao diện tối giản thành một trải nghiệm liền mạch.' 55 450 810 25 13 $Colors.White 'Aptos' 0 1
Add-Anim $s $h 0.1;Add-Anim $s $sub 0.1;Add-Anim $s $line 0.15

# 9. Closing
$s = $pres.Slides.Add(9,$blank); $slides += $s
$s.Shapes.AddPicture($earth,$msoFalse,$msoTrue,0,0,960,540) | Out-Null
$veil=Add-Shape $s $msoShapeRectangle 0 0 960 540 $Colors.Ink; $veil.Fill.Transparency=0.29
$v=Add-Shape $s $msoShapeRectangle 0 0 960 540 (Rgb '0A0914');$v.Fill.Transparency=0.55
$end=Add-Text $s 'AIVIVU' 302 130 356 57 46 $Colors.White 'Aptos Display' 1 2
$tag=Add-Text $s 'Từ ý định đến hành trình.' 270 202 420 33 23 $Colors.Cyan 'Aptos' 0 2
$body=Add-Text $s 'Một người bạn AI giúp việc chuẩn bị chuyến đi trở nên rõ ràng, cá nhân và đầy cảm hứng.' 230 276 500 46 15 $Colors.White 'Aptos' 0 2
$cta=Add-Shape $s $msoShapeRoundedRectangle 370 358 220 39 $Colors.Pink
Add-Text $s 'SẴN SÀNG CÙNG LÊN ĐƯỜNG' 386 371 188 14 10 $Colors.White 'Aptos' 1 2 | Out-Null
Add-Text $s 'THANK YOU' 426 468 108 16 10 $Colors.Muted 'Aptos' 1 2 | Out-Null
Add-Anim $s $end 0.15;Add-Anim $s $tag 0.12;Add-Anim $s $body 0.12;Add-Anim $s $cta 0.15

# Apply subtle fade transition and preserve direct editing of every layout element.
foreach($slide in $slides) {
  try { $slide.SlideShowTransition.EntryEffect = 3849; $slide.SlideShowTransition.Speed = 2 } catch { }
}

$pres.SaveAs($outFile, $ppSaveAsOpenXMLPresentation)
$pres.SaveAs($pdfFile, $ppSaveAsPDF)
$pres.Close()
$pp.Quit()
[Runtime.InteropServices.Marshal]::ReleaseComObject($pp) | Out-Null
Write-Output "Created: $outFile"
Write-Output "Created: $pdfFile"
