# Sway 데스크톱 사용 안내

이 문서는 이 리포가 구성하는 Sway 단일 데스크톱의 사용법과 복구 절차를 설명한다. 공용 설정의 기준 파일은 `config/sway/config`이며, 키를 변경할 때는 이 문서도 같은 변경에서 갱신한다.

이 구성은 현대적인 개인용 데스크톱에 필요한 기능을 최소 중복으로 갖춘 저오버헤드 Sway 환경을 목표로 한다. 각 기능은 명확한 소유자를 가지며, 자동화와 상주 서비스는 실사용에 필요한 경우에만 둔다.

NetworkManager, firewall, Firefox, 인증 실패와 로컬 기록의 공통 경계는
[개인정보와 보안 운영 정책](privacy-security.md)이 소유한다. 이 문서는 그 정책을
Sway UI와 세션 서비스가 적용하는 방식만 설명한다.

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
| `Super+Enter` | Foot 터미널 |
| `Super+D` | Fuzzel 애플리케이션 실행기 |
| `Super+P` | 모든 워크스페이스의 열린 창 검색 |
| `Super+Shift+P` | Documents, Downloads, 미디어와 Projects 파일 검색 |
| `Super+F1` | 이 안내서 열기 |
| `Super+Ctrl+R` | Sway 설정 다시 읽기 |

웹 브라우저, Thunar와 그래픽 설정 도구는 `Super+D`에서 이름을 검색해 실행한다. `System Monitor (btop)`과 `Text Editor (Neovim)`도 동일한 실행기에서 찾을 수 있다. 실행기는 현재 Sway 세션에 맞는 항목만 표시하며, 설치된 의존 package가 XFCE 같은 다른 desktop 전용 항목을 제공하더라도 목록에서 숨긴다.

`Super+P`는 창 제목과 애플리케이션 이름을 사용해 현재 열려 있는 모든 워크스페이스의 창을 찾는다. 목록은 호출한 동안에만 표시하며 Waybar에는 창 제목을 계속 노출하지 않는다. `Super+Shift+P`는 별도 색인을 만들지 않고 표준 사용자 폴더와 `~/Projects`를 호출할 때 검색한 뒤 기본 애플리케이션으로 연다. 대규모 의존성·빌드·IDE 메타데이터 디렉터리는 검색에서 제외한다.

키는 같은 글자의 기억 단서와 기능군을 일관되게 재사용한다. `P`는 선택 대상 검색, `C`는 클립보드,
`R`은 크기 조절이나 설정 다시 읽기처럼 상태를 다시 구성하는 동작을 뜻한다. 같은
기능군에서 `Shift`는 대상 이동·범위 확장·삭제 같은 강한 변형이고, 드물게 실행하는
전역 설정 재로딩에는 `Ctrl`을 더해 일상 동작과 구분한다. 방향 동작은 화면 방향과
같은 H/J/K/L 또는 방향키를 사용한다.

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

알림센터 안에서는 `Shift+D`로 방해 금지를 전환하고 `Shift+C`로 알림을 모두 지울 수 있다. `Escape`로 닫는다.

방해 금지는 로그인할 때 항상 켜지므로 팝업 배너가 자동으로 나타나지 않는다. 알림은 현재 세션의 알림센터에만 쌓이고 `Super+N`으로 직접 확인할 수 있으며, 로그아웃할 때 모두 지운다. 필요한 동안만 `Shift+D` 또는 Waybar 알림 항목의 오른쪽 클릭으로 팝업을 다시 허용할 수 있다.

클립보드 검색에서 항목을 선택하면 해당 내용이 시스템 클립보드로 복사된다. 이후 애플리케이션의 일반 붙여넣기 키를 사용한다.

Cliphist는 최근 텍스트와 이미지를 현재 로그인용 runtime DB에 저장하므로 복사한 비밀번호 같은 민감한 내용도 기록될 수 있다. 기본값은 최대 100개, 항목당 1 MiB로 제한하고 Sway 로그인 시작과 종료에 전체 기록을 자동 삭제한다. 현재 세션에서도 즉시 지워야 하면 `Super+Shift+C`를 사용한다.

#### 스크린샷

| 키 | 동작 |
|---|---|
| `Print` | 전체 화면을 `~/Pictures/Screenshots`에 저장 |
| `Shift+Print` | 선택 영역을 `~/Pictures/Screenshots`에 저장 |
| `Ctrl+Print` | 전체 화면을 클립보드로 복사 |
| `Ctrl+Shift+Print` | 선택 영역을 클립보드로 복사 |
| `Super+Print` | 선택 영역을 캡처해 주석 편집기로 열기 |
| `Super+Shift+Print` | 선택 영역 녹화 시작/종료 |

스크린샷을 저장하거나 클립보드로 복사하면 짧은 OSD가 표시된다. `Super+Print`의 Swappy에서는 화살표·도형·텍스트·블러를 추가한 뒤 `~/Pictures/Screenshots`에 저장하거나 클립보드로 복사할 수 있다. 영역 선택을 취소하려면 `Escape`를 누른다.

화면 녹화는 `~/Videos/Recordings`에 MP4로 저장한다. 같은 키를 다시 누르면 이 workflow에서 시작한 녹화를 정상 종료하며, 시작·중지·저장 결과는 OSD로 표시한다. 녹화 중에는 Waybar에 빨간 `REC`를 계속 표시한다. 마이크나 시스템 오디오를 실수로 수집하지 않도록 기본 녹화에는 소리를 포함하지 않는다.

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

20% 배터리 경고는 기본 방해 금지 정책에 따라 알림센터에 쌓인다. 10% critical 상태는 데이터 손실을 피하기 위해 알림센터 기록과 함께 OSD로 즉시 표시한다. 5%까지 내려가면 60초 종료 유예를 OSD로 알린 뒤 정상 종료한다. 유예 중 전원을 연결하거나 충전이 시작되거나 잔량이 5%를 넘으면 자동 종료를 취소한다. 이 정책은 시스템 배터리에만 적용되며 주변기기 배터리는 제외한다.

#### 세션

| 키 | 동작 |
|---|---|
| `Super+Esc` | 즉시 잠금 |
| `Super+Shift+Esc` | 잠금·절전·로그아웃·재부팅·종료 메뉴 |

세션 메뉴와 클립보드 삭제 확인 창은 같은 조작을 다시 실행하면 닫힌다. 확인 버튼을 선택해 작업을 실행한 뒤에도 화면에 남지 않는다.

종료와 재부팅에는 직접 단축키를 두지 않는다. 세션 메뉴를 거쳐 실수로 종료하는 일을 막는다.

### 일상 작업 예시

#### 다른 워크스페이스의 창이나 파일 찾기

1. 열린 창으로 이동하려면 `Super+P`를 누르고 애플리케이션 또는 창 제목 일부를 입력한다.
2. 파일을 찾으려면 `Super+Shift+P`를 누르고 파일 이름 일부를 입력한다.
3. 선택한 파일은 MIME 기본 애플리케이션으로 열리며, 텍스트 파일은 Foot 안의 Neovim으로 연다.

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

#### 터미널 두 개를 좌우로 배치하기

1. `Super+Enter`로 첫 터미널을 연다.
2. `Super+B`로 좌우 분할을 선택한다.
3. `Super+Enter`로 두 번째 터미널을 연다.
4. `Super+H/L`로 두 창을 오간다.

#### 실행기로 브라우저를 열어 다른 워크스페이스로 보내기

1. `Super+D`를 누르고 `Firefox`를 검색해 실행한다.
2. `Super+Shift+2`로 브라우저를 워크스페이스 2에 보낸다.
3. `Super+2`로 브라우저 워크스페이스로 이동한다.

#### 임시 창을 자유 배치하기

1. 창에 초점을 둔다.
2. `Super+Shift+Space`로 Floating으로 바꾼다.
3. `Super`를 누른 채 마우스 왼쪽 버튼으로 이동한다.
4. `Super`를 누른 채 마우스 오른쪽 버튼으로 크기를 바꾼다.

#### 발표나 긴 영상 중 자동 잠금 막기

Waybar의 `IDLE` 항목을 클릭해 `INHIBIT`으로 바꾼다. 작업이 끝나면 다시 클릭해 잠금과 절전을 활성화한다.

#### 타일 경계 크기 조절하기

1. 조절할 창에 초점을 둔다.
2. `Super+R`로 Resize 모드에 들어간다.
3. `H/J/K/L` 또는 방향키로 경계를 움직인다.
4. `Enter` 또는 `Escape`로 기본 모드로 돌아간다.

#### 워크스페이스를 다른 모니터로 옮기기

1. 옮길 워크스페이스로 이동한다.
2. `Super+O`로 Output 모드에 들어간다.
3. `Shift+H/L` 또는 `Shift+Left/Right`로 워크스페이스를 다른 출력으로 옮긴다.
4. `Enter` 또는 `Escape`로 Output 모드를 종료한다.

출력의 위치·회전·배율을 그래픽으로 조정하려면 Output 모드에서 `D`를 눌러 Wdisplays를 연다. Wdisplays를 열면 모드는 자동으로 종료된다.

#### 화면을 캡처하거나 녹화하기

- 전체 화면을 파일로 남기려면 `Print`를 누른다.
- 영역을 파일로 남기려면 `Shift+Print`를 누르고 영역을 선택한다.
- 붙여넣을 이미지는 `Ctrl+Print` 또는 `Ctrl+Shift+Print`로 클립보드에 복사한다.
- 캡처를 가리거나 설명해야 하면 `Super+Print`로 영역을 고른 뒤 Swappy에서 편집한다.
- 영역 녹화는 `Super+Shift+Print`로 시작하고 같은 키로 종료한다.

스크린샷은 `~/Pictures/Screenshots`, 녹화는 `~/Videos/Recordings`에 저장되며 결과는 OSD로 확인한다. Waybar의 `REC`가 사라지면 녹화 프로세스가 종료되고 파일 정리가 끝난 상태다.

#### 이전 클립보드 내용 다시 사용하기

1. `Super+C`로 클립보드 기록을 연다.
2. Fuzzel에서 텍스트 일부를 검색하거나 이미지 항목을 선택한다.
3. 대상 애플리케이션에서 일반 붙여넣기 키를 사용한다.

현재 세션의 기록을 모두 지우려면 `Super+Shift+C`를 누르고 확인한다. 확인 창은 같은 키로 취소할 수도 있다.

#### 알림과 배터리 경고 확인하기

1. Waybar가 `DND!` 또는 `NOTIFY!`를 표시하면 `Super+N`으로 알림센터를 연다.
2. 팝업 알림이 필요한 동안에는 알림센터에서 `Shift+D`로 방해 금지를 해제한다.
3. 확인이 끝나면 `Escape`로 닫고 필요하면 방해 금지를 다시 켠다.

배터리 20% 경고는 알림센터에 쌓이며, 10% critical 상태는 OSD에도 즉시 표시된다. critical OSD가 보이면 작업을 저장하고 전원을 연결한다. 5%에서는 60초 뒤 자동 종료하므로 전원을 연결해 취소하거나 남은 작업을 즉시 정리한다.

#### Thunar에서 일반 파일과 숨김 파일 오가기

1. `Super+D`에서 `Thunar`를 검색해 실행한다.
2. 왼쪽 `Places`에서 Downloads, Documents, Pictures 또는 Projects로 이동한다.
3. 숨김 설정 파일이 필요할 때만 `Ctrl+H`로 표시한다.
4. 작업이 끝나면 `Ctrl+H`를 다시 눌러 일반 파일 중심 보기로 돌아간다.

#### USB 저장장치를 필요할 때만 열기

1. USB 저장장치를 연결하거나 연결된 상태로 부팅한다. 장치는 자동으로 마운트되지 않고 외장 LUKS 장치도 잠긴 상태로 남는다.
2. 사용할 때 Thunar의 `Devices` 또는 Udiskie 트레이 메뉴에서 장치를 직접 연다. 암호화된 장치는 이때 암호를 입력한다.
3. 작업이 끝나면 열린 파일과 터미널을 닫고 파일시스템을 마운트 해제한다.
4. Udiskie 또는 Thunar에서 장치를 잠그거나 안전하게 제거한 뒤 분리한다.

마운트와 잠금 해제는 사용자가 직접 요청할 때만 일어나며, 로그인이나 장치 연결만으로 파일시스템을 열거나 암호를 묻지 않는다. 별도의 자동 이동식 미디어 관리기도 설치하지 않으므로 장치 연결을 계기로 파일 관리자나 미디어 앱을 실행하지 않는다.

## 상황별 운영

### 한글 입력

Fcitx5가 세션 입력기를 관리한다.

- `Right Alt`: 한/영 전환
- `Ctrl+Space`: 한/영 전환 대체 키
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

Thunar의 왼쪽 `Places`에는 Downloads, Documents, Pictures, Music, Videos와 Projects shortcut을 표시한다. Arch bootstrap을 실행할 때 GTK bookmarks를 이 기본 목록으로 교체한다.

Sway는 compositor이므로 GTK 애플리케이션 설정까지 직접 관리하지 않는다. 이 리포는 역할에 따라 다음처럼 분리한다.

- GTK 3·4의 밝은 테마, 고대비 아이콘·글꼴, 애니메이션, 시스템 이벤트음과 최근 파일 기록 여부는 각각의 `settings.ini`가 관리한다. `gtk.css`는 Paper 배경, 검정 글자와 작은 여백을 사용하는 공통 툴팁을 관리한다. 버튼·경고·입력 피드백음은 끄되 영상·음악의 일반 출력은 음소거하지 않는다.
- GTK 3·4 파일 선택기의 24시간 시계, 숨김 파일 기본 비표시, 폴더 우선 정렬, 목록 보기와 현재 디렉터리 시작은 GLib `gsettings`로 bootstrap 시 적용한다.
- Thunar는 상세 목록 보기, 숨김 파일 기본 비표시, 폴더 우선 정렬을 사용하고 이미지 미리보기와 썸네일 생성을 비활성화한다. 숨김 파일이 필요하면 `Ctrl+H`로 전환한다.
- 디렉터리는 Thunar, 텍스트·Markdown·JSON·XML·YAML은 Foot 안의 Neovim, 이미지는 Imv, 영상·음악은 mpv, PDF와 웹 URL은 기본 웹 브라우저로 연다. 이미지 한 장을 열면 현재 폴더의 다른 이미지도 함께 불러와 왼쪽·오른쪽 방향키로 이동할 수 있다.
- `Text Editor (Neovim)`과 `System Monitor (btop)` 데스크톱 항목은 시스템 패키지의 터미널 프로그램을 Fuzzel과 MIME 연결에서 일반 데스크톱 앱처럼 발견할 수 있게 한다. 같은 패키지가 제공하는 stock desktop entry는 사용자 override로 숨겨 중복 항목을 만들지 않는다. Neovim 항목은 system `/usr/bin/nvim`을 실행하되 mise 환경을 전달해 user-owned language runtime과 도구를 찾게 한다. 숨겨진 Imv desktop 항목은 선택한 이미지가 있는 폴더를 함께 여는 MIME 연결만 제공한다. 이 항목들은 별도 프로세스나 데이터를 추가하지 않는다.

`gsettings`는 GLib 설정 저장 인터페이스이므로 Sway에서도 GTK 파일 선택기 설정에
사용한다. Sway 설정을 다시 읽을 때마다 실행하지 않고, 설치 단계에서 한 번 적용해
compositor 수명주기와 분리한다.

관리하는 대화형 데스크톱 표면은 Paper 색을 기본 면으로 공유한다. 로그인 화면 바깥, 빈 출력과 잠금화면은 같은 따뜻한 중간 명도의 backdrop을 사용해 세션 전환 동안 이어지면서도 작업 면과 구분한다. ReGreet의 입력 frame과 swaylock 상태 표시는 Paper 면을 유지한다. 영역 구분이 필요하면 별도의 흰 카드보다 명확한 테두리를 먼저 사용한다. 평상시 글자는 기본 굵기와 읽는 데 필요한 최소 여백을 유지하며, 대비·크기·불필요한 그림자 제거로 먼저 가독성을 확보한다. 굵은 글자와 강한 배경색은 선택, 집중, 경고처럼 의미가 있는 상태에만 사용한다.

기본 시스템 사운드는 계층별로 끈다. GTK 이벤트·경고·입력 피드백음은 GTK 3·4 설정에서, Bash Readline의 입력 벨은 셸 설정에서, 커널의 레거시 PC 스피커 비프음은 `pcspkr`와 `snd_pcsp` 모듈 차단으로 비활성화한다. Foot의 system·visual bell과 GTK의 visual bell도 끄고, Sway 창과 Waybar 워크스페이스의 urgent 상태는 빨간색 대신 차분한 파란색으로만 구분한다. SwayNC는 항상 방해 금지 상태로 시작하므로 팝업 배너는 표시하지 않고 대기 중인 알림만 Waybar의 `DND!`로 알린다. 브라우저·메신저·알람 앱이 일반 미디어 스트림이나 자체 창으로 직접 표시하는 동작까지 막지는 않는다.

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

Waybar에는 활성 창 제목, Wi-Fi SSID, 네트워크 인터페이스·주소·게이트웨이, Bluetooth
장치 별칭과 오디오 장치명을 표시하지 않는다. 화면 공유나 촬영 중에도 연결 종류와
상태만 보이며, 상세 정보는 사용자가 해당 상태 항목을 클릭해 확인한다.

트레이에는 NetworkManager, Fcitx5와 Udiskie가 제공하는 상태 아이콘이 표시된다.
Bluetooth는 별도 applet 없이 Waybar의 `BT` 항목으로 상태를 표시하고, 클릭할 때만
Blueman 장치 관리자를 연다.

로그인 비밀번호는 독립형 Secret Service인 `gnome-keyring`을 잠금 해제하는 데에도
사용된다. NetworkManager와 Secret Service를 사용하는 Flatpak·데스크톱 애플리케이션의 비밀번호를 세션마다 다시
입력하지 않도록 하기 위한 구성이다.

### 화면 공유

Sway에서는 `xdg-desktop-portal-wlr`가 화면 캡처를 담당하고 `xdg-desktop-portal-gtk`가 파일 선택 같은 일반 인터페이스를 보완한다. 브라우저나 회의 앱에서 화면 공유를 시작하면 출력 또는 영역 선택 UI가 나타나고 Waybar에 빨간 화면 공유 표시가 나타나야 한다. PipeWire 마이크 입력을 사용하는 동안에도 별도의 빨간 표시가 나타난다. 개인정보를 위해 표시의 툴팁에는 애플리케이션 이름을 노출하지 않는다.

문제가 있으면 세션 환경과 서비스를 확인한다.

```sh
systemctl --user show-environment | rg 'WAYLAND_DISPLAY|XDG_CURRENT_DESKTOP'
systemctl --user status xdg-desktop-portal.service xdg-desktop-portal-wlr.service
journalctl --user -b -u xdg-desktop-portal -u xdg-desktop-portal-wlr
```

### 웹캠과 마이크

Bootstrap은 표준 Video4Linux 장치를 점검하는 `v4l-utils`와, PipeWire를 기대하는
기존 V4L2 애플리케이션을 위한 `pipewire-v4l2` 호환 계층을 설치한다. PipeWire와
WirePlumber는 이미 오디오·화면 공유 경로의 일부로 설치된다. 이 구성은 카메라를
자동으로 열거나 영상·사진을 저장하거나 네트워크로 전송하는 서비스는 시작하지 않는다.

내장 또는 USB 웹캠이 시스템에 보이는지만 확인하려면 다음을 실행한다. 이 명령은 장치
목록과 기능만 읽으며 영상을 캡처하지 않는다.

```sh
v4l2-ctl --list-devices
```

Firefox의 공통 권한 정책과 예외 방식은
[개인정보와 보안 운영 정책](privacy-security.md#firefox)이 소유한다.
Waybar는 PipeWire 화면 공유와 마이크 입력을 표시하지만, 모든
카메라 사용을 식별하는 공통 Linux 데스크톱 표시기는 이 구성에 추가하지 않는다. 물리
웹캠 셔터나 하드웨어 LED가 있는 장비에서는 그것을 카메라 사용 여부의 우선 확인 수단으로
사용한다.

### 자동 잠금과 절전

- 15분 동안 입력이 없으면 잠금
- 잠금 후 1분이 지나면 출력 절전
- 입력이 재개되면 출력 복구
- 2시간 동안 입력이 없으면 시스템 절전
- systemd가 절전에 들어가기 직전에 항상 잠금

영상 플레이어나 브라우저가 idle inhibit 프로토콜을 사용하면 재생 중 잠금이 지연될 수 있다. 수동 제어가 필요하면 Waybar의 `IDLE` 항목을 사용한다.

현재 저장장치는 zram swap만 사용하고 resume 구성이 없으므로 최대 절전은 제공하지 않는다. 배터리가 5%까지 내려가면 저장되지 않은 메모리 상태에 의존하는 절전 대신 60초 유예 후 정상 종료해 완전 방전 시 데이터 손실 위험을 줄인다.

이 구성에서 랩탑 덮개 닫기와 idle 절전은 배터리 상태를 확인할 수 있는 짧은 작업 중단에만 사용한다. 전원에 연결하지 않은 랩탑을 장시간 이동하거나 보관할 때는 절전에 의존하지 말고, 작업을 저장한 뒤 `Super+Shift+Esc` 세션 메뉴에서 반드시 수동 종료한다. 절전 중에는 사용자 세션의 배터리 감시가 실행된다고 보장할 수 없으므로 5% 자동 종료를 장시간 절전의 안전장치로 간주하지 않는다.

최대 절전을 사용하지 않는 것은 RAM 내용을 영구 swap에 기록하지 않기 위한 의도적인 로컬 상태 최소화 정책이다. 최대 절전, `suspend-then-hibernate`, 디스크 기반 swap 또는 resume 구성을 일반적인 생산성 개선으로 추가하지 않는다. 이 정책을 바꾸려면 개인정보 지속성, 디스크·부팅 구성과 전원 동작에 대한 사용자의 명시적인 결정을 먼저 받아야 한다.

장시간 build, test나 migration처럼 명령이 끝날 때까지만 시스템 절전을 막아야
하면 해당 명령을 `keep_awake`로 실행한다. `systemd-inhibit`는 명령이 끝나면 함께
종료된다.

```sh
keep_awake npm test
keep_awake docker compose up
```

### SSH agent

Sway 세션은 `%t/ssh-agent.socket`에서 OpenSSH agent 하나를 관리한다. Fuzzel에서
실행한 GUI application과 terminal은 같은 socket을 사용하며, agent는 로그아웃할
때 세션 서비스와 함께 종료된다. 복호화된 identity는 메모리에만 유지되고 기본
수명은 8시간이다.

`sshload`는 `~/.ssh`의 key를 자동으로 탐색하지 않는다. 필요한 private key를
명시해야 하며 이때도 8시간 수명을 적용한다.

```sh
sshload ~/.ssh/id_ed25519_personal
ssh-add -l
```

`sshkill`은 다른 terminal이나 IDE가 만든 agent process를 검색해서 종료하지
않는다. 현재 shell이 직접 시작한 agent만 종료하고, Sway가 관리하는 agent에서는
현재 등록된 identity만 제거한다. SSH로 전달받거나 외부에서 관리되는 agent는 기존
`SSH_AUTH_SOCK`을 우선하므로 Sway 전용 socket으로 덮어쓰지 않는다.

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

NVIDIA 모듈이 로드된 시스템에서는 런처가 `--unsupported-gpu`를 자동으로 추가한다. Intel/AMD 전용 시스템에는 해당 플래그를 추가하지 않는다.

### 패널이나 알림이 사라졌을 때

```sh
systemctl --user status sway-session.target
systemctl --user restart waybar.service swaync.service
journalctl --user -b -u waybar.service -u swaync.service
```

### 전체 데스크톱 서비스를 다시 시작할 때

열린 애플리케이션과 Sway 자체는 유지하면서 패널·알림·입력기·애플릿만 다시 시작한다.

```sh
systemctl --user restart sway-session.target
```

### 설정 오류 검사

실행 중인 Sway에서 다음 명령을 사용한다.

```sh
swaymsg reload
swaymsg -t get_version
swaymsg -t get_outputs
swaymsg -t get_inputs
```

### 설정 적용 시점

설정 파일을 고친 뒤 필요한 적용 방법은 소유 구성 요소에 따라 다르다.

Sway 세션의 Bash에서는 `reloadall`로 Sway, Waybar, SwayNC, Kanshi와 Bash aliases를
다시 읽는다. tmux 안에서 실행하면 현재 tmux server의 설정도 다시 읽는다. 이 명령은
이미 실행 중인 서비스만 대상으로 하며 SSH agent, 클립보드 감시, 알림 기록처럼 상태를
소유하는 서비스는 다시 시작하지 않는다. 저장소 원본을 고쳤다면 먼저
`scripts/deploy_dotfiles.sh`로 배포해야 한다.

공통 privacy/security 설정의 적용 시점은
[개인정보와 보안 운영 정책](privacy-security.md#정본과-적용-시점)을 따른다.

| 변경 대상 | 적용 방법 |
|---|---|
| `config/sway/config`, Waybar·SwayNC·Kanshi 설정 | `scripts/deploy_dotfiles.sh`로 배포한 뒤 `reloadall` 또는 해당 구성 요소의 명시적 reload |
| `config/foot/foot.ini` | `scripts/deploy_dotfiles.sh`로 배포한 뒤 다음 Foot 창부터 적용 |
| `config/swaylock/config` | `scripts/deploy_dotfiles.sh`로 배포한 뒤 다음 `swaylock` 실행부터 적용 |
| `config/sway/scripts/logout-session` | `scripts/deploy_dotfiles.sh`로 배포한 뒤 다음 로그아웃부터 적용 |
| `config/system/sway/start-sway` | bootstrap으로 `/usr/local/bin/start-sway`에 설치한 뒤 다음 Sway 로그인부터 적용 |
| 그 밖의 개별 user service 설정 | `scripts/deploy_dotfiles.sh`로 배포하고 `systemctl --user daemon-reload` 후 해당 service 재시작 |
| 여러 Sway 세션 service와 unit 관계 | `scripts/deploy_dotfiles.sh`로 배포하고 `systemctl --user daemon-reload` 후 `systemctl --user restart sway-session.target` |
| GTK `settings.ini`, MIME 연결, 애플리케이션별 설정 | `scripts/deploy_dotfiles.sh`로 배포한 뒤 해당 애플리케이션을 완전히 다시 실행 |
| GTK 파일 선택기 GLib 설정 | bootstrap에서 적용하며, 이미 실행 중인 애플리케이션은 다시 실행 |
| ALSA hardware auto-mute 정책 | bootstrap에서 지원 카드에 적용하고 `/var/lib/alsa/asound.state`에 저장한 뒤 다음 부팅부터 자동 복원 |
| systemd-logind 전원·덮개 정책, greetd, kernel module 차단 | bootstrap으로 설치한 뒤 재부팅 |

`systemctl --user restart sway-session.target`은 Sway 창 자체는 유지하지만 세션에 묶인 알림, 입력기, applet과 보조 service를 다시 시작한다. systemd-logind를 현재 그래픽 세션에서 강제로 재시작하는 대신 안전하게 재부팅한다.

## 참고

### 데스크톱 패키지 소유와 통합 경계

정확한 Arch 패키지와 package group 목록은 `scripts/bootstrap.sh`만 소유한다.
이 문서는 전체 Arch 패키지 목록을 다시 열거하지 않고, 구현만으로 안전하게
추론하기 어려운 통합 이유와 프로세스 수명주기를 기록한다. Sway 데스크톱은 compositor, 로그인,
portal, 알림, 입력기와 하드웨어 서비스를 독립 구성 요소로 조합하며 모든 프로그램을
상주시킨다는 뜻은 아니다.

- Native Wayland를 기본 경로로 사용하고 XWayland는 아직 X11이 필요한 애플리케이션의
  호환 경계로 유지한다. Qt는 Wayland를 우선하고 지원하지 않는 앱에만 X11 fallback을
  허용한다.
- greetd와 ReGreet는 Cage 안에서 로그인 UI만 실행한 뒤 이 리포의
  `/usr/local/bin/start-sway`로 세션을 넘긴다. PAM은 빈 비밀번호를 허용하지 않고
  [공통 인증 실패 정책](privacy-security.md#인증-실패와-system-journal)을 상속한다.
- PipeWire가 오디오와 화면 공유를 소유하고 `pipewire-jack`이 JACK 호환 API를
  제공한다. Bootstrap은 충돌하는 `jack2`를 교체한다. `fcitx5-im` group은 GTK·Qt
  입력 모듈을 제공하고 별도 Hangul engine이 실제 한글 조합을 담당한다.
- 배터리, backlight, hybrid GPU와 출력 관련 도구는 고정 장치 식별자 없이 지원
  하드웨어에서만 동작한다. GPU 패키지는 감지된 Intel·AMD·NVIDIA 경로에 맞춰
  설치하고 hardware decoding이 불가능하면 software decoding으로 돌아간다.

#### 네트워크 UI, Bluetooth, 저장장치와 인쇄

| 패키지 | 역할 | 이 구성에서의 사용 방식 |
|---|---|---|
| `network-manager-applet` | NetworkManager tray icon과 `nm-connection-editor`를 제공한다. | `nm-applet`은 Sway 세션 동안만 실행되며 Waybar 네트워크 항목을 클릭하면 연결 편집기를 연다. 시스템 NetworkManager와 DNS 정책은 [공통 문서](privacy-security.md#네트워크-개인정보와-방화벽)가 소유한다. |
| `bluez`, `bluez-utils`, `blueman` | BlueZ는 Linux Bluetooth protocol stack과 daemon, utils는 `bluetoothctl` 같은 CLI, Blueman은 그래픽 관리자와 선택적인 트레이 applet을 제공한다. | `bluetooth.service`는 시스템 기능을 제공한다. 중복되는 applet은 상주시하지 않고 Waybar가 연결 상태를 표시하며, 클릭할 때만 `blueman-manager`를 연다. |
| `polkit`, `lxqt-policykit` | Polkit은 일반 사용자의 권한 있는 시스템 작업을 중개하고 LXQt agent는 비밀번호 확인창을 표시한다. | 디스크 마운트, 네트워크 변경과 일부 시스템 설정이 필요할 때만 인증창이 나타난다. agent가 없으면 GUI 작업이 설명 없이 실패하거나 터미널 인증이 필요할 수 있다. |
| `udisks2`, `udiskie` | UDisks2는 디스크와 이동식 저장장치 작업을 D-Bus로 제공하고 Udiskie는 사용자 세션에서 수동 마운트·알림·트레이를 담당한다. | 일반 USB와 외장 LUKS 장치는 자동으로 마운트하거나 잠금 해제하지 않는다. Thunar나 Udiskie 트레이에서 직접 열 때만 파일시스템을 마운트하고, 암호화된 장치에는 암호를 묻는다. |
| `gnome-disk-utility` | GTK 디스크 관리 도구다. | Fuzzel에서 Disks를 찾아 필요할 때만 실행한다. UDisks2와 Polkit을 통해 장치 상태 확인, 파티션·파일시스템 관리와 디스크 이미지 작업을 제공하며 상시 서비스나 네트워크 연결을 추가하지 않는다. |
| `cups`, `system-config-printer`, `bluez-cups` | CUPS는 인쇄 queue와 driver backend, system-config-printer는 그래픽 설정, bluez-cups는 Bluetooth 프린터 연결을 제공한다. | 로컬 Unix socket은 준비해 두되 cupsd는 인쇄 클라이언트가 연결할 때만 시작한다. 프린터를 쓰지 않는 장비에는 scheduler process가 상주하지 않는다. |

#### 기본 애플리케이션과 파일 통합

- Foot, Neovim과 btop은 필요할 때만 실행한다. Neovim과 btop의 custom desktop entry는
  Foot 안에서 올바른 실행 환경을 제공하고 stock entry를 숨겨 실행기 중복을 막는다.
- Thunar는 GVfs와 UDisks2를 통해 휴지통과 이동식 장치를 표시하되 사용자가 직접 열
  때만 마운트한다. Tumbler는 Thunar의 service contract를 충족하지만 thumbnail과
  image preview는 비활성화하며, 압축 메뉴는 plugin과 실제 backend를 함께 유지한다.
- Flatpak은 격리된 데스크톱 앱을 위한 선택 경로다. Bootstrap은 Flathub remote만
  등록하고 앱을 자동 설치하지 않으며 파일 선택과 화면 공유는 기존 portal 경계를
  사용한다.

#### 어떤 프로세스가 언제 실행되는가

| 수명주기 | 주요 구성 요소 |
|---|---|
| 시스템 서비스, socket 또는 D-Bus 요청으로 실행 | greetd, NetworkManager, systemd-resolved, firewalld, Bluetooth, CUPS socket, UDisks2, UPower, power-profiles-daemon, switcheroo-control |
| 로그인 화면이 보이는 동안 실행 | Cage, ReGreet |
| Sway 로그인 동안 실행 | Sway, Waybar, SwayNC, Swayidle, SwayOSD, OpenSSH agent, Fcitx5, Kanshi, batsignal, nm-applet, LXQt Polkit agent, Udiskie, Cliphist 감시 서비스, 개인정보 정리 path·timer |
| 요청·이벤트·예약 시 활성화 | Foot, Fuzzel, Wdisplays, Grim, Slurp, Swappy, wf-recorder, Pavucontrol, Thunar, Tumbler, Blueman manager, CUPS scheduler, portal backend, 파일·URL 기본 앱, 개인정보 정리 service |

Sway 세션용 daemon은 가능한 한 `config/systemd/user/`의 unit으로 관리한다. Sway 설정을 다시 읽어도 중복 실행되지 않는 것이 이 구조의 핵심이다. 로그아웃 helper는 먼저 제한 시간이 있는 정상 종료를 요청하고, launcher가 compositor 종료 직후 `sway-session.target`을 정리한다. 정상 종료에 실패한 경우에만 helper가 target을 멈춘 뒤 `SWAYSOCK`의 PID와 사용자·실행 명령을 다시 검증한 해당 process에 `SIGTERM`, 마지막으로 `SIGKILL`을 보낸다. 강제 종료까지 실패하고 Sway가 남으면 target을 다시 시작해 Waybar와 Fcitx5를 복구한다. 모든 종료 명령에 제한 시간을 두므로 응답 없는 IPC나 user service가 ReGreet 복귀를 무한정 막거나 실행 중인 desktop에서 세션 서비스만 사라진 상태를 유지하지 않는다. 비정상적인 compositor 종료 때도 즉시 재시작을 반복하지 않도록 그래픽 서비스의 재시작에는 짧은 지연을 둔다.

Sway, Xwayland와 직접 실행된 자식 process의 진단 출력은 로그인 TTY에 표시하지 않고 system journal의 `sway` identifier로 보낸다. 로그아웃 fallback은 `sway-logout` identifier를 사용하며 두 기록 모두 system journal의 1일 보존 정책을 따른다.

Sway 세션의 개인정보나 백그라운드 동작과 직접 관련된 구성 요소의 범위는 다음과 같다.

| 구성 요소 | 외부 네트워크 | 로컬 데이터와 종료 동작 | 하드웨어가 없을 때 |
|---|---|---|---|
| OpenSSH agent | 사용하지 않음 | 사용자가 등록한 복호화 identity를 최대 8시간 동안 메모리에만 유지하고 Sway 로그아웃 시 종료 | 하드웨어와 무관하게 동작하며 key를 등록하기 전에는 identity를 보관하지 않음 |
| SwayNC | 사용하지 않음 | 현재 세션의 알림을 보관하고 로그아웃 시 모두 지움 | 하드웨어와 무관하게 알림센터 제공 |
| Cliphist 감시 서비스 | 사용하지 않음 | 복사한 텍스트·이미지를 `0700` 전용 runtime 디렉터리의 DB에 저장하고 로그인 시작·종료에 전체 삭제 | 하드웨어와 무관하게 동작 |
| Tumbler | 사용하지 않음 | Thunar의 D-Bus 요청으로 활성화될 수 있지만 thumbnail과 image preview가 비활성화되어 새 미리보기 cache를 만들지 않음 | 하드웨어와 무관하며 파일 미리보기 요청이 없으면 처리할 데이터가 없음 |
| wlsunset | 사용하지 않음 | 기본적으로 실행하지 않으며, 직접 시작한 동안 현지 시각만 읽고 기록을 남기지 않음 | Sway 출력이 있는 세션에서만 의미 있음 |
| batsignal | 사용하지 않음 | 로컬 전원 정보를 읽고 별도 기록을 남기지 않으며 시스템 배터리 5%에서 유예 후 정상 종료 | 시스템 배터리가 없으면 조용히 종료 |
| 개인정보 정리 path·timer·service | 사용하지 않음 | `~/.local/share/recently-used.xbel`과 24시간이 지난 `~/.cache/thumbnails` 항목만 정리 | 대상 경로가 없으면 변경하지 않음 |

### 주요 설정 위치

| 대상 | 위치 |
|---|---|
| Sway와 키맵 | `~/.config/sway/config` |
| 터미널 | `~/.config/foot/foot.ini` |
| 패널 | `~/.config/waybar/` |
| 알림센터 | `~/.config/swaync/` |
| 실행기 | `~/.config/fuzzel/fuzzel.ini` |
| 창·파일 검색, 레이아웃과 화면 캡처 스크립트 | `~/.config/sway/scripts/` |
| 배터리 감시와 임계 상태 보호 | `~/.config/power/` |
| 스크린샷 주석 편집기 | `~/.config/swappy/config` |
| 사용자 desktop 항목 | `~/.local/share/applications/` |
| 클립보드 설정과 현재 세션 기록 | `~/.config/cliphist/config`, `$XDG_RUNTIME_DIR/cliphist/db` |
| GTK 3·4 외형과 최근 파일 정책 | `~/.config/gtk-3.0/`, `~/.config/gtk-4.0/` |
| 기본 파일·URL 연결 | `~/.config/mimeapps.list` |
| Thunar 동작 | `~/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml` |
| 이동식 저장장치 수동 마운트 정책 | `~/.config/udiskie/config.yml` |
| 화면 잠금 | `~/.config/swaylock/config` |
| 공용 모니터 설정 | `~/.config/kanshi/config` |
| 장비별 모니터 프로필 | `~/.config/kanshi/local.conf` |
| 한글 입력 | `~/.config/fcitx5/` |
| 세션 서비스 | `~/.config/systemd/user/` |
| 로그인 화면과 ReGreet 외형 | `/etc/greetd/config.toml`, `/etc/greetd/regreet.toml`, `/etc/greetd/regreet.css` |
| 전원 버튼과 랩탑 덮개 정책 | `/etc/systemd/logind.conf.d/60-sway-desktop.conf` |
| 레거시 PC 스피커 비프음 차단 | `/etc/modprobe.d/60-silent-system-sounds.conf` |

각 프로그램의 상세 문법은 Arch에 설치된 매뉴얼에서 확인한다.

```sh
man 5 sway
man 5 sway-input
man 5 sway-output
man 5 kanshi
man 1 swayidle
```

### 키맵 변경 규칙

1. 전역 창 관리 키는 `Super`를 기본 수정자로 사용한다.
2. 같은 기본 키는 기억 단서나 기능군을 유지하고 수정자로 기본 동작과 변형 동작을 구분한다.
3. `Shift`는 이동·역방향·범위 확장·삭제처럼 기본 동작의 강한 변형에 우선 사용한다.
4. 애플리케이션 내부의 `Ctrl`·`Alt` 단축키를 불필요하게 가로채지 않는다.
5. 방향 동작은 H/J/K/L과 방향키 문법을 유지한다.
6. 종료·재부팅처럼 상태를 잃을 수 있는 동작은 확인 메뉴를 거친다.
7. 새로운 모드는 `Escape`로 빠져나올 수 있어야 한다.
8. `config/sway/config`와 이 문서를 같은 변경에서 갱신한다.
9. 데스크톱과 랩탑 중 한쪽에만 있는 키나 장치는 존재하지 않을 때 조용히 실패해야 한다.
