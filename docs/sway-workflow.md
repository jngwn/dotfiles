# Sway 데스크톱 사용 안내

이 문서는 Sway 데스크톱의 사용법과 복구 절차를 설명한다. 키와 실제 동작은
`config/sway/config`, 비가시적인 소유권과 변경 경계는
[`Repository Contracts`](contracts.md)가 각각 소유한다.

## 5분 빠른 시작

`Super`는 키보드의 Super 키를 뜻한다.

처음에는 다음 키만 기억하면 된다.

| 키 | 동작 |
|---|---|
| `Super+Enter` | 터미널 열기 |
| `Super+D` | 애플리케이션 검색 |
| `Super+P` | 열린 창 전체 검색 |
| `Super+Shift+P` | 표준 사용자 폴더의 파일 검색 |
| `Super+H/J/K/L` 또는 방향키 | 창 사이의 초점 이동 |
| `Super+Shift+H/J/K/L` 또는 방향키 | 창 위치 이동 |
| `Super+Tab` | 직전에 사용한 워크스페이스로 돌아가기 |
| `Super+1` … `Super+0` | 워크스페이스 1~10으로 이동 |
| `Super+Shift+1` … `Super+Shift+0` | 현재 창을 워크스페이스로 보내기 |
| `Super+F` | 전체 화면 전환 |
| `Super+Q` | 현재 창 닫기 |
| `Super+Esc` | 화면 잠금 |
| `Super+F1` | 이 문서 열기 |

애플리케이션을 찾을 때는 `Super+D`를 누르고 이름 일부를 입력한 뒤 `Enter`를 누른다. 대부분의 작업은 이 실행기를 출발점으로 삼는다.

## 일상 작업

### 기본 개념

#### 창과 컨테이너

Sway는 새 창을 현재 컨테이너에 타일로 배치한다. 창을 겹쳐 놓고 위치를 매번 조절하는 대신 화면을 분할하고, 분할된 영역 안에 창을 넣는다.

- 초점: 현재 키 입력을 받는 창
- 컨테이너: 창 또는 여러 창을 감싸는 레이아웃 단위
- 워크스페이스: 서로 독립된 작업 화면
- Floating: 타일에서 분리해 자유롭게 움직이는 창
- Scratchpad: 필요할 때만 꺼내 쓰는 숨김 공간

#### 방향 문법

방향 동작은 항상 같은 규칙을 따른다.

- `Super+방향`: 초점 이동
- `Super+Shift+방향`: 창 이동
- `Super+O`: 출력 조작 모드

H/J/K/L이 익숙하지 않으면 방향키를 그대로 사용해도 된다.

### 전체 키맵

#### 애플리케이션과 도구

| 키 | 동작 |
|---|---|
| `Super+Enter` | Ghostty 터미널 |
| `Super+D` | Fuzzel 애플리케이션 실행기 |
| `Super+P` | 모든 워크스페이스의 열린 창 검색 |
| `Super+Shift+P` | Documents, Downloads, 미디어와 Projects 파일 검색 |
| `Super+F1` | 이 안내서 열기 |
| `Super+Ctrl+R` | Sway 설정 다시 읽기 |

웹 브라우저, Thunar와 그래픽 설정 도구는 `Super+D`에서 이름을 검색해 실행한다. `System Monitor (btop)`과 `Text Editor (Neovim)`도 동일한 실행기에서 찾을 수 있다. 실행기는 현재 Sway 세션에 맞는 항목만 표시하며, 설치된 의존 package가 XFCE 같은 다른 desktop 전용 항목을 제공하더라도 목록에서 숨긴다.

`Super+P`는 창 제목과 애플리케이션 이름을 사용해 현재 열려 있는 모든 워크스페이스의 창을 찾는다. 목록은 호출한 동안에만 표시하며 Waybar에는 창 제목을 계속 노출하지 않는다. `Super+Shift+P`는 별도 색인을 만들지 않고 표준 사용자 폴더와 `~/Projects`를 호출할 때 검색한 뒤 기본 애플리케이션으로 연다. 대규모 의존성·빌드·IDE 메타데이터 디렉터리는 검색에서 제외한다.

#### 창 초점과 이동

| 키 | 동작 |
|---|---|
| `Super+H/J/K/L` | 왼쪽/아래/위/오른쪽 창에 초점 |
| `Super+방향키` | 같은 동작의 방향키 버전 |
| `Alt+Tab` | 다음 창 |
| `Alt+Shift+Tab` | 이전 창 |
| `Super+Shift+H/J/K/L` | 창을 해당 방향으로 이동 |
| `Super+Shift+방향키` | 같은 동작의 방향키 버전 |
| `Super+A` | 부모 컨테이너에 초점 |
| `Super+Shift+A` | 자식 컨테이너로 초점 복귀 |
| `Super+Space` | 타일 창과 Floating 창 사이의 초점 전환 |
| `Super+Shift+Space` | 현재 창의 Floating 상태 전환 |
| `Super+Shift+M` | 현재 Floating 창을 워크스페이스 중앙으로 회수 |
| `Super+Q` | 현재 창 닫기 |

파일 선택창, 저장창, 오디오·네트워크·블루투스 설정창은 자동으로 Floating 배치된다.
Firefox와 Chromium 계열 브라우저의 PiP 영상은 기존 창의 초점을 유지한 채 Floating으로
열리고 같은 출력의 모든 워크스페이스에 계속 표시된다. 다른 제목을 사용하는 브라우저는
일반 창에 영향을 주지 않도록 확인한 PiP 제목만 같은 규칙에 추가한다.
일반 창이 예상과 달리 작은 창으로만 보이면 먼저 그 창에 초점을 두고
`Super+Shift+Space`를 눌러 타일 상태로 되돌린다. 이동과 상태 전환 단축키는
마우스 아래 창이 아니라 현재 초점을 받은 창에 적용된다.
Floating 창을 화면 밖으로 옮겨 클릭할 수 없으면 `Super+P`에서 그 창을 선택한 뒤
`Super+Shift+M`으로 현재 워크스페이스 중앙에 회수한다. 타일 창은 Sway가 작업 영역
안에 배치하므로 화면 밖의 자유 좌표로 이동하지 않는다.

Floating 창은 `Super`를 누른 채 마우스 왼쪽 버튼으로 끌어 이동하고, 오른쪽 버튼으로
끌어 크기를 조절한다.

#### 레이아웃

| 키 | 동작 |
|---|---|
| `Super+B` | 현재 컨테이너를 좌우 분할로 전환 |
| `Super+V` | 현재 컨테이너를 위아래 분할로 전환 |
| `Super+S` | Stacking 레이아웃 |
| `Super+W` | Tabbed 레이아웃 |
| `Super+E` | 현재 컨테이너의 분할 방향 전환 |
| `Super+Shift+E` | 현재 중첩 컨테이너를 한 단계 평탄화 |
| `Super+F` | 전체 화면 전환 |

`Super+B`와 `Super+V`는 현재 컨테이너의 레이아웃을 직접 바꾼다. 반복 입력해도 다음 창을 위한 단일 자식 컨테이너가 중첩되지 않으므로 Tabbed 제목에 `H[V[…]]` 같은 내부 구조가 나타나지 않는다.

컨테이너 구조를 확인하려면 `Super+A`로 부모 방향으로 올라가고
`Super+Shift+A`로 자식 방향으로 돌아온다. `A`는 Ancestor를 뜻한다.
`Super+Shift+E`는 초점을 포함하는 안쪽 그룹을 바깥 부모에 합쳐 중첩을 한 단계만
줄인다. 단일 자식 분할은 Sway의 기본 해제 동작을 사용하고, 여러 창이 든 그룹은
창 순서와 원래 초점을 유지한 채 평탄화한다. `H[T[…]]`처럼 여러 단계라면 필요한
만큼 반복한다. 워크스페이스에 tiled 그룹 하나만 있으면 그 그룹의 레이아웃을
워크스페이스로 승격해 불필요한 최상위 래퍼도 제거한다. 다른 최상위 tiled 항목이
있거나 적용할 안쪽 그룹이 없으면 구조를 바꾸지 않고 OSD로 알린다.

#### 크기 조절

`Super+R`을 누르면 Resize 모드가 된다. Waybar에 현재 모드가 표시된다.

| Resize 모드 키 | 동작 |
|---|---|
| `H` 또는 `Left` | 너비 10px 줄이기 |
| `L` 또는 `Right` | 너비 10px 늘리기 |
| `K` 또는 `Up` | 높이 10px 줄이기 |
| `J` 또는 `Down` | 높이 10px 늘리기 |
| 위 조합에 `Shift` 추가 | 같은 방향으로 1px 미세 조절 |
| `Enter` 또는 `Escape` | Resize 모드 종료 |

#### 워크스페이스와 모니터

| 키 | 동작 |
|---|---|
| `Super+Tab` | 직전에 사용한 워크스페이스로 돌아가기 |
| `Super+1` … `Super+0` | 워크스페이스 1~10으로 이동 |
| `Super+Shift+1` … `Super+Shift+0` | 현재 창을 워크스페이스 1~10으로 이동 |
| `Super+O` | Output 모드 시작 |

| Output 모드 키 | 동작 |
|---|---|
| `H/L` 또는 `Left/Right` | 왼쪽/오른쪽 모니터로 초점 이동 |
| `Shift+H/L` 또는 `Shift+Left/Right` | 현재 워크스페이스를 다른 모니터로 이동 |
| `D` | Wdisplays를 실행하고 Output 모드 종료 |
| `Enter` 또는 `Escape` | Output 모드 종료 |

Waybar에는 해당 출력에서 현재 사용 중인 워크스페이스만 표시된다. 워크스페이스 번호를 클릭하거나 마우스 휠로 이동할 수도 있다.

제스처를 지원하는 터치패드에서는 세 손가락을 왼쪽으로 밀면 다음 워크스페이스, 오른쪽으로 밀면 이전 워크스페이스로 이동한다. 별도 제스처 daemon을 사용하지 않으며 터치패드가 없는 데스크톱에는 영향을 주지 않는다.

#### Scratchpad

| 키 | 동작 |
|---|---|
| `Super+Shift+-` | 현재 창을 Scratchpad로 보내기 |
| `Super+-` | Scratchpad 창 표시 또는 숨기기 |

Scratchpad에 창이 있으면 Waybar 왼쪽에 `SP n`으로 개수만 표시한다. 창 제목과
애플리케이션 이름은 표시하지 않는다.

Scratchpad는 다른 데스크톱의 최소화 기능과 다르다. 창을 다시 표시하면 원래
창이나 위치를 복원하지 않고 현재 작업공간 위에 Floating으로 띄우며, 여러 창을
보냈다면 `Super+-`를 반복할 때 차례로 표시한다. 따라서 창을 보내기 전에 제목
테두리로 초점을 확인한다. 일반 창을 실수로 보냈다면 `Super+-`로 표시하고
`Super+Shift+Space`로 타일 상태로 되돌린다.

계산기, 음악 플레이어, 임시 터미널처럼 항상 열어 두되 화면을 차지하지 않아야
하는 창에 적합하다. JetBrains Toolbox처럼 알림 영역에 상주하는 애플리케이션은
창을 닫아도 백그라운드 실행을 유지하도록 설정하고 Waybar 알림 영역에서 다시
여는 편이 자연스럽다.

#### 알림, 클립보드, 패널

| 키 | 동작 |
|---|---|
| `Super+N` | 알림센터 열기/닫기 |
| `Super+C` | 클립보드 기록 검색 및 붙여넣기 준비 |
| `Super+Shift+C` | 확인 후 클립보드 기록 전체 삭제 |

Waybar의 `DND!` 또는 `NOTIFY!`는 알림센터를 확인할 신호다. `Super+N`으로 열고,
안에서는 `Shift+D`로 방해 금지를 전환하거나 `Shift+C`로 알림을 모두 지운다.
`Escape`로 닫는다.

방해 금지는 로그인할 때 항상 켜지므로 팝업 배너가 자동으로 나타나지 않는다. 알림은 현재 세션의 알림센터에만 쌓이고 `Super+N`으로 직접 확인할 수 있으며, 로그아웃할 때 모두 지운다. 필요한 동안만 `Shift+D` 또는 Waybar 알림 항목의 오른쪽 클릭으로 팝업을 다시 허용할 수 있다.

클립보드 검색에서 항목을 선택하면 해당 내용이 시스템 클립보드로 복사된다. 이후 애플리케이션의 일반 붙여넣기 키를 사용한다.

Cliphist는 최근 텍스트와 이미지를 현재 로그인용 runtime DB에 저장하므로 복사한 비밀번호 같은 민감한 내용도 기록될 수 있다. 기본값은 최대 100개, 항목당 1 MiB로 제한하고 Sway 로그인 시작과 종료에 전체 기록을 자동 삭제한다. 현재 세션에서도 즉시 지워야 하면 `Super+Shift+C`를 사용한다.

배터리 경고도 알림센터에서 확인한다. 20% 경고는 기록으로 남고, 10% critical
상태는 OSD로 즉시 표시된다. 이때 작업을 저장하고 전원을 연결한다. 5%에서는 60초 뒤
자동 종료하므로 전원을 연결해 취소하거나 남은 작업을 즉시 정리한다.

#### 스크린샷

| 키 | 동작 |
|---|---|
| `Print` | 전체 화면을 `~/Pictures/Screenshots`에 저장 |
| `Shift+Print` | 선택 영역을 `~/Pictures/Screenshots`에 저장 |
| `Ctrl+Print` | 전체 화면을 클립보드로 복사 |
| `Ctrl+Shift+Print` | 선택 영역을 클립보드로 복사 |
| `Super+Print` | 선택 영역을 캡처해 주석 편집기로 열기 |
| `Super+Shift+Print` | 선택 영역 녹화 시작/종료 |

스크린샷 결과는 짧은 OSD로 확인한다. `Super+Print`로 연 Swappy에서 화살표·도형·
텍스트·블러를 추가한 뒤 `~/Pictures/Screenshots`나 클립보드로 저장한다. 영역 선택은
`Escape`로 취소한다.

녹화는 `~/Videos/Recordings`에 무음 MP4로 저장한다. `Super+Shift+Print`를 다시 누르면
이 workflow에서 시작한 녹화를 정상 종료한다. 시작·중지·저장 결과는 OSD로 표시하고,
Waybar의 빨간 `REC`가 사라지면 프로세스 종료와 파일 정리가 끝난 상태다.

#### 오디오, 밝기, 미디어

키보드에 해당 기능 키가 있을 때 다음 동작이 활성화된다.

| 키 | 동작 |
|---|---|
| 볼륨 높임/낮춤 | 기본 출력 볼륨 조절과 OSD 표시 |
| 음소거 | 출력 음소거 전환 |
| 마이크 음소거 | 기본 입력 음소거 전환 |
| 화면 밝기 높임/낮춤 | 백라이트가 있는 랩탑에서 밝기 조절 |
| 키보드 밝기 높임/낮춤 | 지원하는 키보드 백라이트 조절 |
| 재생/일시정지 | 현재 MPRIS 플레이어 제어 |
| 이전/다음 트랙 | 현재 MPRIS 플레이어 제어 |

Bootstrap은 `Auto-Mute Mode` mixer control을 제공하는 ALSA 카드에서 hardware
auto-mute를 비활성화하고 그 상태를 다음 부팅에도 복원한다. 따라서 헤드폰을
연결해도 내장 스피커가 자동으로 음소거되지 않는다. 해당 control이 없는 사운드
장치에는 이 정책을 적용하지 않는다.

데스크톱처럼 배터리나 백라이트가 없는 시스템에서는 관련 Waybar 모듈과 키 동작이 조용히 비활성화된다. 키보드 밝기 키는 커널이 표준 `kbd_backlight` LED를 제공할 때만 모든 해당 키보드 영역을 조절한다. 특정 기기명은 공유 설정에 기록하지 않으며, 지원하지 않는 랩탑에서는 아무 동작도 하지 않는다.

화면 색온도는 기본 Sway 세션에서 자동으로 바꾸지 않는다. 필요할 때 `sunset on`으로 시작하면 위치 정보나 네트워크 조회 없이 시스템의 현지 시각만 사용해 19:00부터 4000 K로 서서히 낮추고 07:00부터 6500 K로 되돌린다. `sunset off`로 현재 세션에서 즉시 중지하고 `sunset status` 또는 인자 없는 `sunset`으로 상태를 확인한다.

#### 세션

| 키 | 동작 |
|---|---|
| `Super+Esc` | 즉시 잠금 |
| `Super+Shift+Esc` | 잠금·절전·로그아웃·재부팅·종료 메뉴 |

세션 메뉴와 클립보드 삭제 확인 창은 같은 조작을 다시 실행하면 닫힌다. 확인 버튼을 선택해 작업을 실행한 뒤에도 화면에 남지 않는다.
종료와 재부팅에는 직접 단축키를 두지 않는다. 세션 메뉴를 거쳐 실수로 종료하는 일을 막는다.

### 애플리케이션 사용

#### 이미지 보기

Thunar나 파일 검색에서 이미지를 열면 Imv가 현재 폴더의 지원 이미지도 함께
불러온다. 하위 폴더는 재귀적으로 탐색하지 않는다.

| 키 | 동작 |
|---|---|
| `Left` / `Right` | 이전·다음 이미지 |
| `gg` / `G` | 첫 번째·마지막 이미지 |
| `Up` / `Down`, `i` / `o`, `+` / `-` | 확대·축소 |
| `h/j/k/l` | 확대된 이미지 이동 |
| `Ctrl+R` | 시계 방향으로 90도 회전 |
| `a` | 실제 크기로 표시 |
| `r` | 확대율과 위치 초기화 |
| `s` | 화면 맞춤 방식 전환 |
| `f` | 전체 화면 전환 |
| `d` | 파일 정보 overlay 전환 |
| `t` / `T` | slideshow 시작·간격 증가 / 중지·간격 감소 |
| `Space` / `.` | animation 재생·일시정지 / 다음 frame |
| `x` / `q` | 현재 이미지를 목록에서 닫기 / Imv 종료 |

`:` 명령 모드에서는 `rotate by -90`, `rotate to 180`, `flip horizontal`,
`flip vertical`처럼 방향과 각도를 지정할 수 있다. 회전·반전·확대는 표시 상태만
바꾸며 원본 이미지 파일을 수정하지 않는다.

#### USB 저장장치를 필요할 때만 열기

1. USB 저장장치를 연결하거나 연결된 상태로 부팅한다. 장치는 자동으로 마운트되지 않고 외장 LUKS 장치도 잠긴 상태로 남는다.
2. 사용할 때 Thunar의 `Devices` 또는 Udiskie 트레이 메뉴에서 장치를 직접 연다. 암호화된 장치는 이때 암호를 입력한다.
3. 작업이 끝나면 열린 파일과 터미널을 닫고 파일시스템을 마운트 해제한다.
4. Udiskie 또는 Thunar에서 장치를 잠그거나 안전하게 제거한 뒤 분리한다.

## 상황별 운영

### 한글 입력

Fcitx5가 세션 입력기를 관리한다.

- `Right Alt`: 한/영 전환
- `Shift+Space`: 한/영 전환 대체 키
- Neovim에서 Insert 모드를 나오면 영문 입력으로 자동 복귀

입력기가 보이지 않거나 일부 애플리케이션에서만 동작하지 않으면 다음을 확인한다.

```sh
systemctl --user status fcitx5.service
fcitx5-remote
fcitx5-diagnose
```

`fcitx5-remote` 결과는 일반적으로 비활성 `1`, 활성 `2`, 실행되지 않음 `0`을 의미한다.

### 데스크톱과 랩탑 출력 구성

공용 Sway 설정은 출력 이름, PCI 주소, 해상도, 배율을 하드코딩하지 않는다. 연결된 출력은 우선 Sway의 기본값으로 켜지고, `Super+O` Output 모드에서 `D`를 눌러 Wdisplays로 현재 세션에서 조정한다.

자주 사용하는 구성을 자동 적용하려면 먼저 안정적인 출력 설명을 확인한다.

```sh
swaymsg -t get_outputs
```

`name`은 도킹 순서에 따라 달라질 수 있으므로 가능하면 `make`, `model`, `serial`을 결합한 설명을 Kanshi에서 사용한다. 다음은 실제 값으로 바꾸기 위한 예시다.

```conf
profile desktop {
  output "EXTERNAL_VENDOR MODEL SERIAL" mode preferred position 0,0 scale 1
}

profile laptop {
  output "INTERNAL_VENDOR PANEL SERIAL" mode preferred position 0,0 scale 1.25
}

profile docked {
  output "INTERNAL_VENDOR PANEL SERIAL" disable
  output "EXTERNAL_VENDOR MODEL SERIAL" mode preferred position 0,0 scale 1
}
```

프로필은 `~/.config/kanshi/local.conf`에 기록한 뒤 다음 명령으로 다시 읽는다. 이 파일은 공용 dotfile의 include 대상이지만 리포 복사본 밖에 있으므로 `deploy_dotfiles.sh`를 다시 실행해도 유지된다.

```sh
systemctl --user reload-or-restart kanshi.service
```

전원 버튼은 실수로 즉시 종료하지 않도록 시스템 절전을 요청한다. 랩탑 덮개는 배터리와 외부 전원에서 모두 절전하고, 도킹됐거나 여러 출력이 연결된 상태에서는 외부 모니터 사용을 방해하지 않도록 무시한다. 이 정책은 systemd-logind가 담당하며 다음 부팅부터 적용된다. 공용 설정에서 특정 내장 패널 이름을 끄는 규칙은 만들지 않는다.

### GTK, 파일 관리자와 기본 애플리케이션

Ghostty 검색은 `Ctrl+Shift+F`, 설정 다시 읽기는 `Ctrl+Shift+,`를 사용한다.

Thunar의 `Places`에는 Downloads, Documents, Pictures, Music, Videos와 Projects가
표시된다. 숨김 파일은 기본적으로 보이지 않으며 `Ctrl+H`로 전환한다. 목록 보기와 폴더
우선 정렬을 사용하고 image preview와 thumbnail 생성은 꺼져 있다.

Directory는 Thunar, text·Markdown·JSON·XML·YAML은 Ghostty 안의 Neovim, image는
Imv, video·audio는 mpv, PDF와 web URL은 기본 browser로 열린다. Image를 열면 같은
directory의 다른 image를 방향키로 이동할 수 있다.

### Waybar 사용법

오른쪽 상태 영역은 하드웨어와 서비스가 존재할 때만 의미 있는 값을 표시한다.

- `IDLE/INHIBIT`: 자동 잠금과 절전 허용 여부
- 빨간 개인정보 표시: PipeWire 화면 공유 또는 마이크 입력 사용 중
- 빨간 `REC`: 이 구성에서 시작한 `wf-recorder` 녹화가 진행 중
- 네트워크: 클릭하면 연결 편집기
- Bluetooth: 클릭하면 장치 관리자
- 볼륨: 클릭하면 믹서, 오른쪽 클릭하면 음소거
- 밝기: 랩탑에서 스크롤로 조절
- 배터리: 랩탑의 충전량과 예상 시간
- 전원 프로필: balanced, performance, power saver
- 알림: 클릭하면 알림센터, 오른쪽 클릭하면 방해 금지
- `POWER`: 세션 메뉴

Waybar는 상태 요약만 표시하며 상세 정보는 해당 항목을 클릭해 확인한다.

트레이에는 NetworkManager, Fcitx5와 Udiskie가 제공하는 상태 아이콘이 표시된다.
Bluetooth는 별도 applet 없이 Waybar의 `BT` 항목으로 상태를 표시하고, 클릭할 때만
Blueman 장치 관리자를 연다.

### 화면 공유

Sway에서는 `xdg-desktop-portal-wlr`가 화면 캡처를 담당하고 `xdg-desktop-portal-gtk`가 파일 선택 같은 일반 인터페이스를 보완한다. 브라우저나 회의 앱에서 화면 공유를 시작하면 출력 또는 영역 선택 UI가 나타나고 Waybar에 빨간 화면 공유 표시가 나타나야 한다. PipeWire 마이크 입력을 사용하는 동안에도 별도의 빨간 표시가 나타난다. 개인정보를 위해 표시의 툴팁에는 애플리케이션 이름을 노출하지 않는다.

문제가 있으면 세션 환경과 서비스를 확인한다.

```sh
systemctl --user show-environment | rg 'WAYLAND_DISPLAY|XDG_CURRENT_DESKTOP'
systemctl --user status xdg-desktop-portal.service xdg-desktop-portal-wlr.service
journalctl --user -b -u xdg-desktop-portal -u xdg-desktop-portal-wlr
```

### 웹캠과 마이크

장치 목록과 기능만 확인하려면 다음을 실행한다. 이 명령은 영상을 캡처하지 않는다.

```sh
v4l2-ctl --list-devices
```

Firefox 권한 예외는 Firefox GUI에서 직접 관리한다. Waybar의 개인정보 표시는 PipeWire
화면 공유와 마이크 입력을 보여주지만 모든 카메라 사용을 탐지하지는 않는다. 가능하면
물리 셔터나 하드웨어 LED도 확인한다.

### 자동 잠금과 절전

- 15분 동안 입력이 없으면 잠금
- 잠금 후 1분이 지나면 출력 절전
- 입력이 재개되면 출력 복구
- 2시간 동안 입력이 없으면 시스템 절전
- systemd가 절전에 들어가기 직전에 항상 잠금

영상 플레이어나 브라우저가 idle inhibit 프로토콜을 사용하면 재생 중 잠금이 지연될 수
있다. 수동으로 막으려면 Waybar의 `IDLE`을 클릭해 `INHIBIT`으로 바꾼다. 작업이 끝나면
다시 클릭해 자동 잠금과 절전을 활성화한다.

이 구성은 zram swap만 사용하고 resume 설정이 없어 최대 절전을 제공하지 않는다.
덮개 닫기와 idle 절전은 짧은 작업 중단에 사용한다. 전원에 연결하지 않은 랩탑을
장시간 이동하거나 보관할 때는 작업을 저장한 뒤 `Super+Shift+Esc` 세션 메뉴에서
수동 종료한다. 절전 중에는 사용자 세션의 배터리 감시가 동작한다고 보장할 수 없어
자동 종료를 안전장치로 삼을 수 없다.

장시간 build, test나 migration처럼 명령이 끝날 때까지만 시스템 절전을 막아야
하면 해당 명령을 `keep_awake`로 실행한다. `systemd-inhibit`는 명령이 끝나면 함께
종료된다.

```sh
keep_awake npm test
keep_awake docker compose up
```

## 문제 해결과 복구

### Sway가 시작되지 않을 때

1. `Ctrl+Alt+F3`으로 TTY로 이동한다.
2. 로그인한다.
3. greetd와 현재 부팅 로그를 확인한다.

```sh
systemctl status greetd.service
journalctl -b -u greetd.service
journalctl -b -t sway -t sway-logout
```

Sway를 직접 실행해 설정 오류를 확인할 수 있다.

```sh
/usr/local/bin/start-sway -d
```

NVIDIA 모듈이 로드된 시스템에서는 launcher가 `--unsupported-gpu`를 자동으로
추가한다.

### 패널이나 알림이 사라졌을 때

```sh
systemctl --user status sway-session.target
systemctl --user restart waybar.service swaync.service
journalctl --user -b -u waybar.service -u swaync.service
```

### 전체 데스크톱 서비스를 다시 시작할 때

열린 application과 Sway는 유지하면서 panel, notification, input method와 applet을
다시 시작한다.

```sh
systemctl --user restart sway-session.target
```

### 설정 오류 검사

```sh
swaymsg reload
swaymsg -t get_version
swaymsg -t get_outputs
swaymsg -t get_inputs
```

### 설정 적용 시점

저장소 변경은 [README의 배포 절차](../README.md#bootstrap-dotfile-deployment-and-recovery)를
따른다. 배포 후 Native Sway의 `reloadall`은 Sway, Waybar, SwayNC와 Kanshi 설정을
다시 읽으며 tmux 안에서는 현재 server 설정도 다시 읽는다.

| 변경 대상 | 적용 방법 |
|---|---|
| Sway, Waybar, SwayNC, Kanshi | 배포 후 `reloadall` 또는 해당 component reload |
| Ghostty | 배포 후 `Ctrl+Shift+,`; process/window option은 모든 창을 닫고 다시 실행 |
| Swaylock | 배포 후 다음 실행 |
| Logout helper | 배포 후 다음 logout |
| `config/system/sway/start-sway` | bootstrap 설치 후 다음 Sway login |
| 개별 user service | 배포, `systemctl --user daemon-reload`, 해당 service restart |
| 여러 session service와 unit 관계 | 배포, daemon reload, `systemctl --user restart sway-session.target` |
| GTK, MIME, application 설정 | 배포 후 해당 application 재실행 |
| GTK file chooser GLib 설정 | bootstrap 후 application 재실행 |
| ALSA hardware auto-mute | bootstrap 후 다음 boot |
| Logind, greetd, kernel module | bootstrap 후 reboot |

System policy는 bootstrap으로 설치한 뒤 관련 application 또는 system을 다시 시작해야
적용된다.

`systemctl --user restart sway-session.target`은 Sway 창 자체를 유지하지만 session
service를 다시 시작한다. 실행 중인 graphical session에서는 systemd-logind를 직접
restart하지 말고 reboot한다.
