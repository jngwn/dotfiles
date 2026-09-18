# Repository Contracts

이 문서는 현재 구현만 보고는 복원하기 어려운 저장소의 지속적 결정을 기록한다.
각 계약은 결정의 이유, 반드시 유지할 경계와 그 결정을 다시 논의해야 하는 조건만
소유한다. 명령, 함수, package와 설정값의 일반 목록은 계약이 아니며 실제 동작은
정본 구현이 소유한다. `Locators`는 정본을 찾기 위한 시작점이지 구현 목록이 아니다.
사용 절차와 복구 방법은 README와 workflow 문서가 소유한다.

## PLATFORM-001

**Name:** 지원 계층

**Locators:** `scripts/bootstrap.sh`, `scripts/deploy_dotfiles.sh`,
`config/bash/platform/`, `platform/windows/`

**Why:** 전체 시스템 지원과 일부 설정의 호환 배포를 구분하지 않으면 한 기능의 존재가
의도하지 않은 플랫폼 지원 약속으로 확대된다.

**Boundary:** Native Arch Linux와 Sway가 전체 bootstrap, deployment와 desktop 통합의
기준 환경이다. Arch Linux on WSL은 bootstrap과 제한된 CLI deployment를 지원한다.
그 밖의 Linux와 macOS에는 `DEPLOY-001`의 명시된 user configuration만 배포하며 system
또는 desktop 지원으로 간주하지 않는다. Windows host는 bootstrap과 deployment 대상이
아니며 Windows Terminal theme만 수동 전달 자산으로 유지한다. 새 플랫폼이나 더 넓은
지원 계층은 명시적인 사용자 결정 없이 추가하지 않는다.

**Change condition:** 지원 플랫폼, bootstrap 대상, 제한 배포 범위 또는 host와 guest의
소유권을 바꿀 때 재검토한다.

## DEPLOY-001

**Name:** 정본, 파생 배포와 복구

**Locators:** `scripts/deploy_dotfiles.sh`, `README.md`

**Why:** 정본과 배포 결과를 구분해야 다음 배포가 직접 수정한 파일이나 machine-owned
상태를 덮어쓰지 않는다.

**Boundary:** 현재 checkout이 유일한 정본이다. 다른 위치에서 배포할 때
`~/.dotfiles`는 정본의 파생 사본이며 home과 XDG config 대상은 그 사본을 가리킨다.
기존 대상은 충돌하지 않는 backup으로 보존한다. System path는 `SYSTEM-001`의 bootstrap
경로만 소유하며 user configuration 배포에 포함하지 않는다. 저장소 변경, 배포 성공과
실행 중 동작은 각각 독립적으로 확인한다.

배포 manifest는 배포가 만든 symlink만 추적한다. 다음 배포는 manifest에서 빠진 대상이
여전히 기록된 source를 가리킬 때만 backup으로 이동하며, 사용자가 교체한 파일이나 다른
target을 가리키는 symlink는 보존한다.

제한 배포는 배포 스크립트의 명시적 allowlist만 사용한다. 모든 WSL 배포판은 공통 CLI
설정만 받는다. WSL 밖의 Linux에는 Ghostty와 mpv 설정을, macOS에는 Ghostty 설정을
추가할 수 있다. Native Arch Linux만 system source를 제외한 전체 user configuration을
배포한다. Allowlist 확대는 지원 범위 변경으로 취급한다.

**Change condition:** 정본 위치, symlink와 backup의 소유권, manifest 복구 규칙 또는
플랫폼별 allowlist를 바꿀 때 재검토한다.

## MACHINE-001

**Name:** 공유 설정과 machine-owned 상태

**Locators:** `scripts/deploy_dotfiles.sh`, `scripts/bootstrap.sh`, `config/kanshi/`,
`config/sway/`

**Why:** 장치 식별자, 사용자 신원과 기존 사용자 directory 속성은 다른 기계로 안전하게
복제할 수 없으며 공유 설정이 이를 소유하면 credential 또는 local state가 유출된다.

**Boundary:** `~/.config/kanshi/local.conf`는 공유 배포 밖에 두는 output profile
예외다. 고정 output 이름, PCI 주소, battery, backlight와 lid 장치 식별자는 공유 Sway
설정에 넣지 않는다. 사용자 identity, SSH host, VPN profile, certificate와 credential을
포함하는 상태도 저장소 밖에 둔다.

Bootstrap은 기존 표준 사용자 directory의 owner와 mode를 바꾸지 않으며, 없는
directory만 `0755`로 만든다. GTK Places의 표준 directory bookmark는 관리할 수 있지만
사용자가 다른 label로 만든 bookmark는 보존한다.

**Change condition:** 새 machine-local 예외가 필요하거나 공유 설정, 사용자 directory와
bookmark의 소유권을 바꿀 때 재검토한다.

## SHELL-001

**Name:** Bash와 platform integration

**Locators:** `home/.bashrc`, `config/bash/aliases.sh`, `config/bash/platform/`,
`config/systemd/user/ssh-agent.service`

**Why:** 공통 CLI와 OS integration을 분리해야 공개 명령을 재사용하면서 host와 desktop
상태를 잘못 소유하지 않는다.

**Boundary:** Bash가 유일하게 유지하는 interactive/login shell이다. 공개 명령은 공통
계층이 한 번만 소유하고 platform adapter는 필요한 capability만 제공한다. Native
desktop integration은 Native Arch 계층에만 두며 WSL 계층은 guest 상태만 관리한다.
macOS와 X11 경로는 명시적으로 지원한 capability에만 적용한다.

SSH agent lifecycle은 platform session이 소유한다. Native Sway에서는 session service가
agent를 시작하고 종료하며 `ssh-agent.service`의 `ExecStart`에 있는 `-t 8h`가 identity
기본 수명을 소유한다. Arch WSL에서는 systemd user manager가 OpenSSH agent socket을
소유하고, 다른 WSL 배포에는 deployment가 agent lifecycle을 만들지 않는다. WSL
identity의 수명은 사용자가 지정한 `ssh-add` constraint와 user manager의 수명을 따른다.
상속된 agent와 forwarded agent를 우선하며 Bash가 agent를 직접 생성·종료하거나 key를
자동 등록하거나 forwarding을 전역으로 활성화하지 않는다.

**Change condition:** 유지 shell, 공통 명령과 adapter의 책임, host/guest 경계 또는 SSH
agent lifecycle을 바꿀 때 재검토한다.

## OPEN-001

**Name:** 경로 열기와 파일 작업

**Locators:** `home/.local/bin/open-path`, `config/bash/aliases.sh`,
`config/yazi/yazi.toml`

**Why:** shell과 file manager가 같은 locality 판단을 사용해야 경로 열기가 환경에 따라
예상하지 못한 host application으로 전달되지 않는다.

**Boundary:** Opener는 사용자가 명시한 경로만 현재 session에서 확인된 provider로
전달한다. Native Wayland, Linux/X11, WSL과 macOS의 경로는 서로의 provider를 추측하지
않으며 remote shell에서는 host GUI를 추측하지 않고 실패한다. 삭제와 trash는 opener의
책임에 포함하지 않는다.

**Change condition:** opener의 locality, provider 소유권, remote 동작 또는 경로 전달
범위를 바꿀 때 재검토한다.

## CLIPBOARD-001

**Name:** Clipboard locality와 방향

**Locators:** `config/tmux/tmux.conf`, `config/nvim/init.lua`,
`docs/tmux-workflow.md`

**Why:** Clipboard는 현재 display와 terminal session이 소유한다. 실행 파일의 존재만으로
provider를 선택하면 다른 session의 GUI에 기록하거나 UTF-8 text를 손상할 수 있다.

**Boundary:** Native Wayland, Linux/X11과 macOS에서는 실제 local session과 일치하는
provider만 사용한다. WSL과 SSH에서는 Windows 또는 host GUI clipboard executable을
직접 호출하지 않고 terminal integration과 tmux buffer를 사용한다. Remote application은
terminal을 통해 바깥 clipboard에 쓸 수 있지만 host clipboard를 읽지 않는다. 각
application은 provider를 직접 선택하되 이 locality, 방향과 encoding 경계를 공유한다.

**Change condition:** Clipboard provider의 locality나 우선순위, host/guest 방향,
encoding 또는 복사 데이터 범위를 바꿀 때 재검토한다.

## TERMINAL-001

**Name:** Terminal ownership과 remote boundary

**Locators:** `config/ghostty/config`, `config/tmux/tmux.conf`

**Why:** Terminal emulator가 remote capability, window identity와 persistent state를
과도하게 소유하면 host 정보가 노출되고 tmux와 책임이 충돌한다.

**Boundary:** Ghostty는 Native Arch/Sway와 Ghostty 설정을 받는 제한 배포 환경의 주
terminal이다. WSL host terminal은 저장소 밖에서 소유하며 Windows Terminal theme은
수동 전달만 한다. Remote host에는 emulator 전용 terminfo나 host cache를 설치하지 않고
`xterm-256color` 호환 경로를 사용한다. Window title에 application content를 자동으로
반영하지 않는다. Ghostty scrollback은 `scrollback-limit = 10485760`의 10 MiB memory
상한 안에서만 유지하고 disk history를 추가하지 않는다. Terminal tab과 tmux window의
interaction 소유권을 섞지 않는다.

**Change condition:** 주 terminal, host/guest integration, remote terminfo, window title,
scrollback persistence 또는 terminal과 tmux의 interaction 소유권을 바꿀 때 재검토한다.

## TOOLS-001

**Name:** 도구, package와 update 소유권

**Locators:** `scripts/bootstrap.sh`, `config/mise/config.toml`,
`.pre-commit-config.yaml`

**Why:** 한 도구를 여러 manager가 소유하거나 재현성 자료를 임의의 version pin처럼
다루면 update와 rollback의 책임이 불명확해진다.

**Boundary:** Arch package manager는 OS integration과 Native container runtime을,
mise는 사용자 개발 도구를 소유한다. Project는 자신의 dependency, runtime, build,
test, image, credential, port, volume과 service lifecycle을 소유한다. 제한 배포 환경의
나머지 package는 사용자가 관리하며 deployment가 package manager 상태를 바꾸지 않는다.

새 capability는 stock OS, Arch package, 작은 reviewed upstream install 순으로
선택한다. OS 동작은 platform owner에 두고 update와 cleanup은 사용자 명령으로만
시작한다. User-owned tool과 Neovim plugin은 current upstream release를, Arch package는
Arch repository release를 따른다. Manager가 요구하는 immutable revision과 lockfile은
재현성 자료로 보존한다. 별도 compatibility pin에는 입증된 constraint와 재검토 조건이
필요하다. 새 installer, binary source, remote 또는 integrity 검증 우회는 별도의
supply-chain 결정 없이는 추가하지 않는다.

WSL container runtime은 Windows host가 소유한다. 개발은 source, toolchain, build/test,
server와 browser를 local에서 실행하는 범위가 기본이며 SSH와 GUI-less fallback의 존재가
remote workstation 지원을 의미하지 않는다.

**Change condition:** Manager나 package source, version 정책, 자동 update, container
runtime 또는 local/remote 개발 범위를 바꿀 때 재검토한다.

## SYSTEM-001

**Name:** Native system 설치 경계

**Locators:** `config/system/`, `scripts/bootstrap.sh`

**Why:** System path의 파생 파일을 직접 수정하면 다음 bootstrap에 덮어쓰이고 저장소와
실제 system의 상태가 갈라진다.

**Boundary:** `config/system/`이 Native bootstrap이 system path에 설치하는 파일의
정본이다. WSL bootstrap은 이를 설치하지 않는다. Graphical session 명령은 interactive
shell의 `PATH`에 의존하지 않는다. Source의 제거 또는 rename만으로 기존 system 사본을
삭제하지 않으며, 같은 변경에서 이전 destination의 명시적 cleanup과 recovery를 제공해야
제거가 완료된다.

**Change condition:** System source와 destination의 소유권, 설치 대상 또는 graphical
session의 executable resolution을 바꿀 때 재검토한다.

## DESKTOP-001

**Name:** Sway session과 service lifecycle

**Locators:** `config/sway/`, `config/systemd/user/`, `config/power/`,
`docs/sway-workflow.md`

**Why:** Compositor와 user service가 같은 process를 동시에 소유하면 중복 실행, 느린
logout과 불완전한 cleanup이 발생한다.

**Boundary:** `sway-session.target`이 session-scoped service의 시작과 종료를 소유하며
한 process에는 한 owner만 둔다. Compositor fallback은 user manager가 없을 때만
사용한다. Logout은 service와 session state를 정리하되 cleanup 실패가 logout을 막지
않는다. Wayland가 기본이고 XWayland는 호환 경로다. Hardware capability는 해당 장치가
있을 때만 활성화한다. 교체된 desktop 구현은 migration 뒤에 병행 유지하지 않는다.
Night color는 fixed local time을 쓰는 opt-in capability이며 geolocation이나 자동
활성화를 추가하지 않는다.

**Change condition:** Process owner, session lifecycle, desktop environment, hardware
fallback 또는 background desktop capability를 바꿀 때 재검토한다.

## INTERACTION-001

**Name:** Desktop interaction 경계

**Locators:** `config/sway/`, `config/waybar/`, `config/swaync/`,
`docs/sway-workflow.md`

**Why:** Key, feedback와 visible state는 개별 component보다 전체 desktop에서 충돌,
실수 비용과 privacy를 판단해야 한다.

**Boundary:** 자주 쓰는 저위험 작업은 직접 실행하고 파괴적이거나 넓은 범위의 작업은
mode, preview 또는 confirmation으로 보호한다. Toggle에는 기본 상태, 즉시 feedback와
명확한 종료 경로가 있어야 한다. 자동화는 local owner가 좁고 결정적인 범위에서 기존
상태를 보존하며 실행한다.

상시 UI에는 SSID, address, device alias, window와 document title 같은 민감한 식별자를
표시하지 않는다. Bell과 자동 banner 대신 passive indicator와 사용자가 요청하는 상세
정보를 사용한다. 장시간 작업은 전역 lock/suspend 정책을 약화하지 않고 해당 명령에만
적용되는 inhibitor를 사용한다. Key family는 빈도와 역할에 따라 일관되게 구성하고 기존
provider, 일상 경로와 notification을 중복하지 않는다. Text는 읽기 쉬운 크기, 보통
굵기와 좁은 여백을 우선하고 color semantics는 `COLOR-001`을 따른다.

**Change condition:** Key family, mode, destructive action의 보호 방식, persistent
indicator 또는 privacy-visible surface를 바꿀 때 재검토한다.

## POWER-001

**Name:** 전원과 저장장치 안전 경계

**Locators:** `config/power/`, `config/sway/`, `scripts/bootstrap.sh`

**Why:** Battery 오인식과 일괄 storage 최적화는 작업 유실, 부팅 실패 또는 암호화
metadata 노출을 일으킬 수 있다.

**Boundary:** 자동 저전력 suspend, hibernate와 power-off threshold는 명시적인 사용자
결정 없이 바꾸지 않는다. 자동 power-off는 system-scoped battery만 판단하고 grace
period 뒤에 조건을 다시 확인한다. 조건이 해제되면 취소하며 battery가 없으면 아무
동작도 하지 않는다. 암호화 system volume의 dm-crypt discard pass-through는 입증된
필요 없이 활성화하지 않는다. Zram 외의 disk-backed swap과 resume은 구성하지 않으며
hibernate와 `suspend-then-hibernate`를 제공하지 않는다.

**Change condition:** Threshold, 전원 동작, battery scope, swap/resume 또는 encrypted
volume discard를 바꾸려면 memory persistence, disk와 boot 구성을 함께 재검토한다.

## NETWORK-001

**Name:** Network privacy와 firewall

**Locators:** `scripts/bootstrap.sh`, `config/system/NetworkManager/`,
`config/system/systemd/resolved.conf.d/60-network-privacy.conf`,
`config/system/firefox/policies/policies.json`, `scripts/network_privacy_mode.sh`

**Why:** DNS, VPN split DNS, connection profile, firewall와 현재 SSH session은 함께
동작하므로 일부만 바꾸면 name resolution 또는 원격 복구 경로가 끊길 수 있다.

**Boundary:** 이 계약은 Native system만 소유하며 Windows host networking은 소유하지
않는다. NetworkManager가 연결별 DNS와 routing domain을 `systemd-resolved`에 전달하고
`/etc/resolv.conf`는 local stub resolver를 사용한다. Shared resolver는 public DNS나
strict DoT를 전역 강제하지 않아 VPN과 profile별 예외를 보존한다. NetworkManager의
HTTP connectivity check는 비활성화하고 captive portal은 사용자가 browser에서 연다.

Bootstrap 시 존재하는 모든 Ethernet과 Wi-Fi profile에는 이름과 무관하게 다음 trusted
baseline을 적용한다.

- random cloned MAC address
- Cloudflare `1.1.1.1`, `1.0.0.1`과 `one.one.one.one` 인증 이름을 쓰는 strict DoT
- DHCP DNS 무시
- IPv6 비활성화

실행 중인 profile은 강제로 재연결하지 않으며 새 profile은 다음 bootstrap 전까지
관리하지 않는다. VPN profile은 변경하지 않는다. Hotspot, connection sharing, 고정
MAC이나 DHCP DNS가 필요한 profile은 자동 예외로 추측하지 않는다. Resolver 선행
조건이 없으면 profile을 바꾸지 않는다. `ipv6.ip6-privacy=2`는 사용자가 IPv6를 다시
활성화한 profile의 fallback이며 DHCP hostname 억제와 동시 연결의 negative DNS
priority는 이 계약에 포함하지 않는다.

Network privacy mode는 local user가 profile을 명시해 실행하는 예외 경로다. `managed`는
상태를 읽기만 한다. `portal`은 인증 중 pseudonymous MAC을 유지하면서 automatic DNS와
IPv6 privacy를 사용한다. `public`은 같은 MAC을 유지하고 strict DoT와 disabled IPv6로
돌아간다. `vpn`은 현재 MAC을 유지하며 DNS를 VPN application에 넘긴다. Profile을
재활성화하는 변경 mode는 SSH에서 실행하지 않는다.

Firewalld가 기본 backend다. Fresh local bootstrap은 user override가 없을 때 Arch
`public` zone의 packaged SSH allow rule만 제거한다. 기존 zone과 rule은 보존하며 현재
SSH session이 있으면 SSH 접근을 유지한다. Firewalld가 없고 UFW가 이미 active 또는
enabled일 때만 UFW를 유지한다. 두 backend는 unsolicited inbound를 차단하고 outbound는
허용한다.

Strict DoT는 TCP 853이 차단되어도 plaintext로 downgrade하지 않으므로 DNS가 실패할 수
있다. 별도 system-wide DoH service를 추가하지 않는다. Firefox는 자체 DoH를 사용하지
않고 OS resolver를 따라 VPN과 internal split DNS를 보존한다. 이 정책은 DNS transport만
보호하며 resolver 운영자, destination IP와 application traffic을 숨기지 않는다.

**Change condition:** 관련 source는 주석과 formatting을 포함해 사용자가 path 또는
구체적인 security behavior를 명시적으로 요청한 경우에만 바꾼다.

## DATA-001

**Name:** 개인정보와 기록 수명

**Locators:** `config/system/firefox/policies/policies.json`, `config/cliphist/`,
`config/systemd/user/`, `config/system/systemd/journald.conf.d/60-privacy-retention.conf`,
`config/bash/`, `scripts/bootstrap.sh`

**Why:** Activity record는 사용자 metadata다. 생성 owner, 저장 위치, 수명과 삭제 범위가
분명해야 편의 기능이 새 기록을 축적하거나 복구할 data를 지우지 않는다.

**Boundary:** 반복적 외부 통신, telemetry, analytics, crash upload, 자동 update 확인,
geolocation과 cloud sync는 명시적인 결정 없이 추가하지 않는다. 편의를 위한 persistent
history와 index보다 사용자 호출 또는 session 수명의 상태를 우선한다. User data, trash,
browser state, credential과 광범위한 development cache는 아래 예외 외에 자동 삭제하지
않는다.

- 민감한 graphical-session state는 `XDG_RUNTIME_DIR`에 두고 login/logout 경계 안에서만
  유지한다. Cliphist는 `0700`인 `$XDG_RUNTIME_DIR/cliphist/`에 저장하며 SwayNC history도
  session을 넘지 않는다.
- Native desktop은 GTK recent-file 생성을 막고 우회 생성된 기록을 정리한다. File
  chooser는 현재 directory에서 시작하고 thumbnail preview는 비활성화한다. Thumbnail
  cache는 24시간을 초과한 항목만 매일 정리한다.
- Bootstrap과 deployment log는 `$XDG_STATE_HOME/dotfiles/logs/` 아래에 directory
  `0700`, file `0600`으로 저장하며 사용자 cleanup은 1일을 초과한 log만 지운다.
- Bash history는 `$XDG_STATE_HOME/bash/` 아래에 directory `0700`, file `0600`으로
  저장한다. 경로가 symlink, 비정규 file 또는 다른 owner이면 persistent history를
  기록하지 않는다.
- Deployment manifest는 `$XDG_STATE_HOME/dotfiles/deployment-manifest`에 `0600`으로
  저장하며 parent directory는 `0700`이다.
- Journal은 `MaxRetentionSec=1day`와 `MaxFileSec=1day`를 유지한다. Bootstrap은 기존
  1일 초과 journal을 rotate/vacuum하며 ReGreet와 Sway 진단도 같은 수명을 따른다.
  ReGreet는 별도 file log를 만들지 않는다.
- Firefox는 telemetry, studies, account backup, 기본 AI, home content, suggestion과
  새로운 민감 권한 요청을 제한한다. Translation은 유지하되 자동 popup은 사용하지
  않는다. 종료 시 cache, form data와 history만 지우며 cookie, session과 site setting은
  보존한다. Site permission 예외는 사용자가 GUI에서 허용한다.

사용자 cleanup은 confirmation 뒤에 실행하며 browser data, network/firewall policy와
Windows host data를 건드리지 않는다. 편집과 terminal의 복구 상태는 `STATE-001`만
예외로 소유한다.

**Change condition:** Persistent state나 background request, 저장 위치, retention,
자동 삭제 범위 또는 journal vacuum을 바꾸려면 명시적인 사용자 결정이 필요하다.

## AUTH-001

**Name:** 인증 경로

**Locators:** `config/system/security/faillock.conf`, `config/system/pam.d/greetd`,
`config/system/greetd/`

**Why:** Login UI의 존재만으로 PAM enforcement와 credential store unlock을 보장할 수
없으므로 실제 인증 path의 책임을 보호한다.

**Boundary:** PAM stack은 `fail_interval = 900`, `deny = 10`, `unlock_time = 300`으로
15분 동안 10회 실패한 계정을 5분 잠근다. Graphical login의 PAM path는
`gnome-keyring` Secret Service를 함께 unlock하여 session application이 같은 credential
store를 사용하게 한다. 인증 진단 기록의 수명은 `DATA-001`을 따른다.

**Change condition:** Login과 authentication path, credential store integration 또는
faillock 값을 바꾸려면 명시적인 사용자 결정이 필요하다.

## STATE-001

**Name:** Interactive state와 persistence 예외

**Locators:** `config/tmux/tmux.conf`, `config/nvim/init.lua`,
`docs/tmux-workflow.md`

**Why:** 편집과 terminal 복구 상태도 저장 위치와 수명을 제한하지 않으면 privacy와
recovery 동작을 예측할 수 없다.

**Boundary:** Tmux scrollback, mark와 buffer는 server memory에만 두며 session
persistence plugin이나 disk history를 추가하지 않는다. Bash의 tmux entry point와 관리
명령은 하나의 `main` server를 공유하고 사용자가 정한 window name을 자동으로 바꾸지
않는다. Neovim은 일반 file history를 최소화하되 ShaDa와 undo를 명시적인 작업 복구
예외로 유지한다.

**Change condition:** Interactive state를 disk에 기록하거나 저장 수명, server ownership
또는 recovery 범위를 바꿀 때 재검토한다.

## NVIM-001

**Name:** Neovim 책임과 구성 경계

**Locators:** `config/nvim/`

**Why:** 기본 editor, optional feature, plugin과 language server의 책임을 분리해야 한
기능의 부재가 전체 editor startup을 깨뜨리지 않는다.

**Boundary:** `init.lua`는 다른 저장소 Neovim 파일 없이도 오류 없이 기본 editing
session을 제공한다. Optional feature, plugin declaration, plugin configuration과
language server configuration은 각 modular owner에 두며 한 모듈의 부재는 그 기능만
비활성화한다. Language intelligence는 Neovim built-in LSP client를 사용하고 plugin은
built-in으로 충족할 수 없는 기능에만 사용한다. Editor는 project source와 file search를
quickfix navigation 범위에서 담당한다. Dependency 관리, build, test와 debugging은
terminal 또는 project가 소유한다. Language tool 설치와 update는 `TOOLS-001`을 따른다.
Treesitter는 유지 범위에 포함하지 않는다.

**Change condition:** Editor startup의 독립성, module ownership, editor와 project의
책임, plugin 기준 또는 Treesitter 제외 결정을 바꿀 때 재검토한다.

## COLOR-001

**Name:** Paper color system

**Locators:** `docs/color_system.md`

**Why:** Consumer가 palette와 semantic role을 개별적으로 정의하면 같은 상태가 서로
다른 의미로 표시된다.

**Boundary:** `docs/color_system.md`가 Paper token, palette, semantic role과 예외의
유일한 specification이다. Consumer 추가나 교체는 이 specification을 바꿀 권한을
부여하지 않는다. 적용 여부는 설정값의 존재가 아니라 실제 owning application,
toolkit 또는 compositor가 semantic mapping을 소비하는 것으로 확인한다.

**Change condition:** Token, palette, semantic role 또는 명시적 예외를 바꾸려면 사용자
결정과 specification 변경이 함께 필요하다.
