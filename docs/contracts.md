# Repository Contracts

이 문서는 구현만으로 복원하기 어려운 소유권, 존재 이유와 변경 경계를 정의한다.
각 계약의 `Why`는 이유, `Boundary`는 유지할 결정, `Change condition`은 재검토할
조건이다. `Locators`는 관련 구현으로 가는 탐색 시작점이며 구현 목록이 아니다.
실제 동작은 구현에서, 사용자 절차는 README와 workflow에서 확인한다.

## PLATFORM-001

**Name:** 지원 계층

**Locators:** `AGENTS.md`, `scripts/bootstrap.sh`, `scripts/deploy_dotfiles.sh`,
`config/bash/platform/`, `platform/windows/`

**Why:** 하나의 저장소 안에서 전체 시스템 소유권과 제한된 호환 기능을 구분해야
지원 범위가 우연히 확대되지 않는다.

**Boundary:** Native Arch Linux와 Sway는 전체 bootstrap과 deployment의 기본 환경이다.
Arch Linux on WSL은 bootstrap과 제한된 CLI deployment를 유지한다. 그 밖의 Linux
배포판은 WSL 실행 여부와 관계없이 bootstrap 없이 `DEPLOY-001`의 제한된 user
configuration만 배포하며, 이것이 전체 system 또는 desktop 지원을 의미하지는 않는다.
Windows host는 bootstrap과 배포 대상이 아니며 Windows Terminal theme만 수동 전달
자산으로 유지한다. 새 대상이나 더 넓은 지원 계층에는 명시적인 사용자 결정이 필요하다.

**Change condition:** 플랫폼 지원, bootstrap 대상, deployment 범위 또는 host/guest
소유권을 의도적으로 바꿀 때만 변경한다.

## DEPLOY-001

**Name:** 정본, 파생 배포와 복구

**Locators:** `scripts/deploy_dotfiles.sh`, `README.md`

**Why:** 저장소와 배포 결과를 혼동하면 다음 배포가 직접 수정한 내용을 덮어쓰거나
machine-owned 상태를 공유 설정으로 가져올 수 있다.

**Boundary:** 현재 checkout이 정본이다. 다른 경로에서 배포하면 `~/.dotfiles`는
정본의 파생 사본이고, home과 XDG config 대상은 그 사본을 가리키는 symlink다.
기존 대상은 충돌하지 않는 backup 이름으로 이동한 뒤 연결한다. `config/system/`은
bootstrap이 system path에 설치하므로 사용자 config로 연결하지 않는다. 저장소 변경,
배포 완료와 실행 중 동작 검증은 서로 다른 상태다.

성공한 배포는 `$XDG_STATE_HOME/dotfiles/deployment-manifest`에 자신이 만든 symlink의
source와 destination을 기록한다. 다음 배포에서 목록에서 빠진 destination이 여전히
같은 source를 가리킬 때만 해당 symlink를 현재 run의 backup으로 이동한다. 사용자가
교체한 파일이나 다른 target을 가리키는 symlink는 건드리지 않는다.

모든 제한 배포가 공유하는 목록은 다음이 전부다.

- Home: `.bash_profile`, `.bashrc`, `.codex`, `.editorconfig`,
  `.local/bin/open-path`, `.gitconfig`, `.gitignore_global`, `.ideavimrc`
- XDG config: `bash`, `mise`, `nvim`, `tmux`, `yazi`

WSL의 모든 Linux 배포판에는 공통 목록만 배포한다. WSL 밖의 다른 Linux에는 `ghostty`와
`mpv`를, macOS에는 `ghostty`를 추가로 배포한다. Native Arch Linux는 `config/system/`을
제외한 전체 user configuration을 배포한다.

**Change condition:** 정본 위치, backup/복구 규칙 또는 배포 목록을 바꿀 때만 변경한다.

## MACHINE-001

**Name:** 공유 설정과 machine-owned 상태

**Locators:** `scripts/deploy_dotfiles.sh`, `scripts/bootstrap.sh`, `config/sway/`,
`config/kanshi/`

**Why:** 장치 이름과 신원 정보는 다른 기계에서 재사용할 수 없고 credential을 저장소에
유입할 위험이 있다. 기존 directory attribute와 사용자가 추가한 bookmark도 bootstrap
기본값이 덮어쓰면 machine-owned 상태가 유실된다.

**Boundary:** `~/.config/kanshi/local.conf`는 공유 배포 밖에 있는 output profile
예외다. 고정 output 이름, PCI 주소, battery, backlight와 lid 장치는 공유 Sway 경로에
넣지 않는다. 사용자 identity, SSH host, VPN profile, certificate와 credential-bearing
상태도 저장소 밖에 둔다.

Bootstrap은 기존 표준 사용자 directory의 owner와 mode를 보존하고 없는 directory만
`0755`로 만든다. GTK Places의 표준 directory bookmark는 관리하지만 다른 label의
사용자 bookmark를 보존한다.

**Change condition:** 새 machine-local 예외가 실제로 필요하거나 표준 user directory
attribute 또는 GTK bookmark 소유권을 바꿀 때만 변경한다.

## SHELL-001

**Name:** Bash와 platform overlay

**Locators:** `home/.bashrc`, `config/bash/aliases.sh`, `config/bash/platform/`,
`config/systemd/user/ssh-agent.service`, `scripts/bootstrap.sh`,
`config/bash/AGENTS.md`

**Why:** 공통 명령과 OS 통합을 분리하면 CLI 기능을 재사용하면서 desktop과 host
소유권이 잘못 섞이는 것을 막을 수 있다.

**Boundary:** Bash가 유일하게 유지하는 interactive/login shell이다. 공통 설정 뒤에
OS adapter를 적용한다. Linux에서는 `linux` 다음에 해당하면 `arch`, 그 뒤에 `wsl`
또는 `native_arch`를 적용하고 macOS에서는 `macos`를 적용한다. 한 기능의 공개 명령은
한 곳에서 소유하고 adapter는 필요한 hook만 제공한다. Native desktop 통합은
`native_arch`에만 둔다. WSL adapter는 guest 상태만 관리하고 Windows host 상태를
수정하지 않는다. macOS와 X11 provider는 명시적으로 적응한 기능에만 사용한다.
Bash prompt는 이전 command status를 표시하되 `mise activate bash`를 포함해 먼저
등록된 `PROMPT_COMMAND` hook을 보존한다.

SSH agent lifecycle은 platform session이 소유한다. Native Sway에서는
`sway-session.target`의 `ssh-agent.service`가 agent를 시작하고 logout 때 종료하며,
identity의 기본 수명은 `config/systemd/user/ssh-agent.service`의 `ExecStart`에 있는
`-t 8h`가 소유한다. Arch WSL bootstrap은 OpenSSH package의
`ssh-agent.socket`을 활성화하고 systemd user manager가 agent lifecycle을 소유한다.
이 agent의 identity 수명은 사용자가 `ssh-add`에 지정한 constraint와 user manager의
수명을 따른다. 그 밖의 WSL에서는 deployment가 agent lifecycle을 구성하지 않는다.
Bash는 상속된 외부·forwarded agent를 보존하고, 없을 때에만 platform이 소유한 socket에
연결한다. Bash가 agent를 직접 생성하거나 종료하지 않으며, key를 자동으로 탐색·등록하거나
forwarding을 전역으로 켜지 않는다.

**Change condition:** shell 지원, overlay 순서, 공개 명령이나 prompt hook 소유권 또는
host/guest 경계를 바꿀 때만 변경한다.

## OPEN-001

**Name:** 경로 열기와 파일 작업

**Locators:** `home/.local/bin/open-path`, `config/bash/aliases.sh`,
`config/yazi/yazi.toml`

**Why:** shell과 file manager가 같은 capability 판별을 공유해야 플랫폼별 opener가
서로 다르게 동작하지 않는다.

**Boundary:** `open-path`가 명시적으로 전달된 경로만 platform opener로 넘긴다.
Native Wayland, Linux/X11, WSL과 macOS는 사용할 수 있는 provider만 선택한다. 원격
shell에서는 host GUI를 추측하지 않고 실패한다. 삭제와 trash는 opener와 별도이며,
자동으로 범위를 넓히지 않는다.

**Change condition:** opener provider, remote 동작 또는 path 전달 경계를 바꿀 때만
변경한다.

## CLIPBOARD-001

**Name:** Clipboard locality와 fallback

**Locators:** `config/tmux/tmux.conf`, `config/nvim/init.lua`,
`docs/tmux-workflow.md`

**Why:** clipboard는 display/session 소유권과 전달 경로의 encoding에 의존한다. 실행
파일의 존재만으로 provider를 고르면 원격 환경에서 잘못된 GUI에 기록할 수 있고, tmux의
UTF-8 stream을 Windows clipboard executable에 직접 전달하면 text가 손상될 수 있다.

**Boundary:** Native Wayland, Linux/X11과 macOS에서는 해당 세션에 맞는 local
provider가 있을 때만 OS clipboard를 사용한다. WSL의 tmux는 Windows clipboard
executable을 직접 호출하지 않고 terminal integration을 사용한다. Application별
clipboard 선택은 각 component가 소유하며 같은 locality 경계를 지킨다. Provider
우선순위는 더 구체적인 환경이 일반 환경을 덮어쓰도록 정의한다. SSH에서는 host GUI
provider를 직접 추측하지 않고 terminal integration과 tmux buffer를 fallback으로
사용한다.

**Change condition:** application별 provider 소유권, provider 순서, WSL/SSH locality
또는 복사 데이터 범위를 바꿀 때만 변경한다.

## TERMINAL-001

**Name:** Terminal ownership과 remote boundary

**Locators:** `config/ghostty/config`, `config/tmux/tmux.conf`,
`config/nvim/init.lua`

**Why:** Terminal emulator가 window identity, remote capability와 clipboard를 독자적으로
소유하면 Sway/tmux 경계와 민감한 host state가 함께 노출될 수 있다.

**Boundary:** Ghostty는 Native Arch/Sway와 Ghostty 설정을 포함하는 제한 배포 환경의 주
terminal이다. WSL의 host terminal은 저장소 소유권 밖에 있으며 Windows Terminal
theme은 수동 전달 자산으로만 유지한다. Remote host에는 emulator-specific terminfo를
설치하거나 host cache를 만들지 않고 `xterm-256color` 호환 경로를 사용한다. Remote
application은 OSC 52로 바깥 clipboard에 쓸 수 있지만 host clipboard를 읽지 못한다.
Window title에는 application content를 자동 반영하지 않는다. Ghostty scrollback은
`config/ghostty/config`의 `scrollback-limit = 10485760`이 소유하는 10 MiB memory limit
안에 두며 disk history를 추가하지 않는다. `Ctrl+Shift+Left/Right`
는 terminal tab이 아니라 tmux window 이동에 남긴다.

**Change condition:** 주 terminal 범위, host/guest terminal 소유권, terminfo/SSH
integration, clipboard 방향, title, scrollback persistence 또는 tmux key ownership을
바꿀 때만 변경한다.

## TOOLS-001

**Name:** 도구, package와 update 소유권

**Locators:** `scripts/bootstrap.sh`, `config/bash/aliases.sh`,
`config/bash/platform/`, `config/mise/config.toml`, `.pre-commit-config.yaml`

**Why:** 같은 도구를 여러 manager가 갱신하면 version과 rollback 경계가 불명확해진다.
Manager가 요구하는 revision과 lockfile을 임의의 pin처럼 취급하면 재현성도 깨진다.

**Boundary:** Arch package manager는 OS 통합 도구와 Native container runtime을,
mise는 사용자 version 도구를 소유한다. 각 project는 dependency, runtime, build/test,
container image, credential, port, volume과 service lifecycle을 소유한다. 제한 배포
플랫폼의 나머지 package 설치는 사용자 소유이며 deployment는 package manager나 그
상태를 관리하지 않는다.

새 기능은 stock OS capability, Arch package, 작은 reviewed upstream install 순으로
선택한다. OS 동작은 platform owner에 두고 사용자 개발 도구는 실용적인 범위에서
배포판에 독립적으로 유지한다. 갱신과 도구 정리는 사용자 명령으로만 시작한다.
개인정보 기록의 자동 정리 예외는 `DATA-001`이 소유한다. User-owned tool과 Neovim
plugin은 current upstream release를, Arch package는 Arch repository release를 따른다.

Manager가 요구하는 immutable revision과 lockfile은 재현성 자료로 보존한다. 별도의
compatibility pin에는 입증된 regression이나 constraint와 재검토 조건이 필요하며,
generated version churn과 광범위한 pinning은 피한다. 새 upstream installer, release
binary source, Flatpak remote와 integrity 검증 우회에는 명시적인 supply-chain 결정이
필요하다.

WSL container runtime은 Windows host가 소유하며 guest bootstrap은 관리하지 않는다.
개발은 source, editor, toolchain, build/test, server와 browser를 local에서 실행하는
것이 기본이다. SSH·clipboard·GUI-less fallback은 호환 경로이며 remote workstation
지원은 아니다. Remote execution을 유지 범위로 추가하려면 명시적인 결정이 필요하다.

**Change condition:** manager, package source, version/reproducibility 정책, 자동 갱신,
container runtime 또는 local/remote 개발 범위를 바꿀 때 변경한다.

## SYSTEM-001

**Name:** Native system 설치 경계

**Locators:** `config/system/`, `scripts/bootstrap.sh`, `config/system/AGENTS.md`

**Why:** system path의 파생 파일을 직접 수정하면 다음 bootstrap에 덮어쓰이고 정본과
실제 시스템이 갈라진다.

**Boundary:** `config/system/`은 Native bootstrap이 `/etc`, `/usr/local/bin`과
`/usr/local/share`에 설치하는 정본이다. WSL bootstrap은 이 경로를 설치하지 않는다.
Sway session에서 실행할 명령은 interactive shell의 `PATH`에 기대지 않아야 한다.
Source를 제거하거나 rename해도 기존 system 사본은 자동으로 사라지지 않는다. 같은
변경에서 이전 destination의 명시적 cleanup과 recovery를 bootstrap 절차에 포함해야
제거가 완료된다.

**Change condition:** 설치 대상, system ownership 또는 graphical-session executable
해결 방식을 바꿀 때만 변경한다.

## DESKTOP-001

**Name:** Sway session과 service lifecycle

**Locators:** `config/sway/`, `config/systemd/user/`, `config/power/`,
`scripts/bootstrap.sh`, `docs/sway-workflow.md`

**Why:** compositor 시작 명령과 user service가 같은 process를 동시에 소유하면 중복
실행, logout 지연과 불완전한 cleanup이 생긴다.

**Boundary:** `sway-session.target`이 session-scoped user service의 시작과 종료를
소유한다. 한 process는 한 owner만 가지며 compositor fallback은 user manager가 없는
경우에만 사용한다. logout은 target 종료와 session-state cleanup을 시도하되 실패한
cleanup이 logout 자체를 막지 않는다. Wayland가 기본이고 XWayland는 호환 경로다.
Hardware 기능은 장치가 있을 때만 활성화하며 없으면 조용히 비활성화한다. 대체한
desktop 구현은 migration 확인 후 병행 유지하지 않는다. Night color는 fixed local
time을 사용하는 opt-in service이며 geolocation이나 자동 enablement를 추가하지 않는다.

**Change condition:** process owner, session target, 종료 순서, desktop environment 또는
hardware fallback을 바꿀 때만 변경한다.

## INTERACTION-001

**Name:** Desktop interaction 경계

**Locators:** `config/sway/`, `config/waybar/`, `config/swaync/`,
`docs/sway-workflow.md`

**Why:** key와 상태 표현은 개별 파일보다 전체 interaction surface에서 충돌과 복구
가능성을 판단해야 한다.

**Boundary:** 자주 쓰는 저위험 작업은 직접 실행하고, 파괴적·광범위·상태 저장 작업은
mode, preview 또는 confirmation 뒤에 둔다. Toggle은 기본 상태, 즉시 feedback과
명확한 종료 경로를 갖는다. 일상 자동화는 local owner가 좁은 범위에서 빠르고
결정적으로 실행하며 기존 상태를 보존한다.

항상 보이는 UI에는 SSID, address, device alias와 window/document title 같은 민감한
식별자를 두지 않는다. Desktop bell과 자동 banner는 기본적으로 끄고 passive indicator와
사용자가 호출하는 상세 정보만 남긴다. 장시간 작업은 기본 lock/suspend를 약화하지
않고 해당 명령 범위의 inhibitor로 보호한다.

키는 기능과 사용 빈도, 조작 편의에 따라 묶고 전체 키맵의 충돌과 대칭성을 확인한다.
Provider, 일상 경로, 알림은 기존 역할과 중복되도록 추가하지 않는다. 목적 없는
상시 control도 추가하지 않는다.
안정적인 진입점을 유지하고 텍스트는 읽기 쉬운 크기, 높은 대비, 보통 굵기와 좁은
여백을 우선한다.

**Change condition:** key family, mode, destructive action, persistent indicator 또는
privacy-visible surface를 바꿀 때만 변경한다.

## POWER-001

**Name:** 전원과 저장장치 안전 경계

**Locators:** `config/power/`, `config/sway/`, `scripts/bootstrap.sh`

**Why:** 잘못 감지한 battery나 일괄 SSD 최적화는 작업 유실 또는 암호화 metadata
노출을 만들 수 있다.

**Boundary:** 자동 저전력 suspend, hibernate와 power-off threshold 변경에는 명시적인
사용자 결정이 필요하다. 자동 power-off는 system-scoped battery만 사용하고 grace
period 뒤에 조건을 다시 확인하며, 조건이 해제되면 취소되고 battery hardware가 없으면
아무 동작도 하지 않는다. 암호화 system volume의 dm-crypt discard pass-through는
비활성화 상태를 유지하며 입증된 필요 없이 SSD 최적화로 켜지 않는다.
Zram 외의 disk-backed swap과 resume은 두지 않고 hibernate와
`suspend-then-hibernate`를 제공하지 않는다. 이를 바꾸려면 memory persistence,
disk/boot 구성과 전원 동작을 함께 결정해야 한다.

**Change condition:** threshold, 결과 동작, hardware scope 또는 encrypted-volume
discard 정책을 바꿀 때만 변경한다.

## NETWORK-001

**Name:** Network privacy와 firewall

**Locators:** `scripts/bootstrap.sh`의 `setup_basic_firewall`,
`setup_trusted_network_profiles`, `setup_networkmanager_privacy`,
`setup_basic_network_privacy`; `config/system/NetworkManager/conf.d/99-privacy.conf`;
`config/system/systemd/resolved.conf.d/60-network-privacy.conf`;
`config/system/firefox/policies/policies.json`; `scripts/network_privacy_mode.sh`

**Why:** 연결별 DNS, VPN split DNS, firewall backend와 현재 SSH 접속은 함께 보존해야
부분적인 privacy 변경이 name resolution이나 원격 복구 경로를 끊지 않는다.

**Boundary:** 이 계약은 Native system에만 적용하고 Windows host networking은 소유하지
않는다. NetworkManager가 연결별 DNS와 routing domain을 `systemd-resolved`에 전달하며
`/etc/resolv.conf`는 local stub resolver를 사용한다. 공유 resolver는 특정 public DNS나
strict DoT를 강제하지 않아 VPN과 profile별 예외를 보존한다. NetworkManager의 주기적
HTTP connectivity check는 끄고 captive portal은 사용자가 browser에서 직접 연다.

Bootstrap 시 존재하는 모든 Ethernet/Wi-Fi profile에는 연결 이름과 무관하게 다음
`trusted` 기본값을 적용한다.

- random cloned MAC address
- Cloudflare `1.1.1.1`, `1.0.0.1`과 인증 이름 `one.one.one.one`을 쓰는 strict DoT
- DHCP DNS 무시
- IPv6 비활성화

실행 중인 profile은 재활성화하지 않으므로 다음 연결 또는 재부팅부터 적용된다. 새
profile은 bootstrap을 다시 실행해야 하며 VPN profile은 변경하지 않는다. Hotspot,
connection sharing, 고정 MAC이나 DHCP DNS가 필요한 profile은 자동 예외가 아니다.
resolver 선행 조건이 없으면 profile을 건드리지 않으며, 개별 실패 뒤에도 나머지를
시도한 후 작업 전체를 실패로 보고한다. `ipv6.ip6-privacy=2`는 사용자가 IPv6를
활성화한 profile의 fallback이고, DHCP hostname 억제와 동시 연결의 negative DNS
priority는 이 계약에 포함하지 않는다.

`network_privacy_mode.sh`는 local user가 profile을 명시해 실행하는 예외 전환 경로다.
`managed`는 읽기만 한다. `portal`은 portal 인증 동안 pseudonymous MAC을 안정적으로
유지하고 automatic DNS와 IPv6 privacy를 사용하며, `public`은 같은 MAC을 유지한 채
strict DoT와 IPv6 disabled 상태로 돌아간다. `vpn`은 현재 MAC을 유지하고 DNS를 VPN
application에 넘긴다. 변경 mode는 연결을 재활성화하므로 SSH에서 거부한다.

firewalld가 기본 backend다. Fresh local bootstrap은 사용자 override가 없을 때 Arch
`public` zone의 packaged SSH allow rule만 제거한다. 기존 zone과 rule은 보존하고 SSH
session 중에는 현재 접속을 위해 SSH를 허용한다. firewalld가 없고 UFW가 이미 active
또는 enabled일 때만 UFW를 유지한다. 두 backend 모두 unsolicited inbound를 막지만
outbound traffic은 허용한다.

Strict DoT는 TCP 853이 차단되면 평문으로 downgrade하지 않아 name resolution도
실패한다. 별도 system-wide DoH service를 추가하지 않는다. Firefox는 자체 DoH를 끄고
OS resolver를 사용하여 VPN과 내부망 split DNS를 보존한다. 이 구성은 DNS transport를
보호할 뿐 resolver 운영자, 접속 대상 IP나 application traffic을 숨기지 않는다.

**Change condition:** 관련 source는 주석과 formatting을 포함해 path 또는 구체적인
security behavior를 명시한 사용자 요청 없이는 바꾸지 않는다.

## DATA-001

**Name:** 개인정보와 기록 수명

**Locators:** `config/system/firefox/policies/policies.json`, `config/cliphist/`,
`config/systemd/user/`, `config/system/systemd/journald.conf.d/60-privacy-retention.conf`,
`config/bash/`, `config/nvim/init.lua`, `scripts/bootstrap.sh`

**Why:** 활동 기록은 사용자 metadata다. 보존·삭제의 owner와 수명을 명시해야 편의를
위한 기능이 새로운 기록을 쌓거나 복구할 data를 지우지 않는다.

**Boundary:** 반복적 외부 통신, telemetry, analytics, crash upload, 자동 update 확인,
geolocation과 cloud sync는 명시적 결정 없이 추가하지 않는다. 편의만을 위한 persistent
history나 index도 추가하지 않으며 사용자 호출 또는 session 범위 상태를 우선한다.
사용자 data, trash, browser state, credential과 광범위한 development cache는 아래의
명시된 예외 외에 자동 삭제하지 않는다.

- 민감한 graphical-session 상태는 `XDG_RUNTIME_DIR`에 두고 login/logout 양쪽에서
  수명을 제한한다. Cliphist는 `0700`인 `$XDG_RUNTIME_DIR/cliphist/`에 session 동안만
  저장하며 SwayNC history도 session을 넘기지 않는다.
- Native desktop은 GTK recent-file 생성을 막고 우회 생성된 기록도 정리한다. File
  chooser는 현재 directory에서 시작하고 thumbnail preview는 끈다. 기존 thumbnail cache는 매일
  24시간 초과 항목만 정리한다.
- Bootstrap/deployment log는 `$XDG_STATE_HOME/dotfiles/logs/`에 directory `0700`,
  file `0600`으로 저장한다. `pclean`의 log 정리는 1일 초과 파일만 대상으로 한다.
- Bash history는 `$XDG_STATE_HOME/bash/`에 directory `0700`, file `0600`으로 저장하며
  history directory나 file이 symlink, 비정규 file 또는 다른 owner이면 persistent
  history를 쓰지 않는다.
- Deployment manifest는 `$XDG_STATE_HOME/dotfiles/deployment-manifest`에 `0600`으로
  저장하고 parent directory는 `0700`으로 유지한다.
- Journal은 장기 감사보다 metadata 최소화를 우선해 `MaxRetentionSec=1day`와
  `MaxFileSec=1day`를 유지한다. Bootstrap은 journald를 재시작하고 기존 1일 초과
  journal을 rotate/vacuum한다. ReGreet와 Sway 진단도 같은 수명을 따르며 ReGreet는
  별도 파일 log를 만들지 않는다.
- Firefox는 telemetry, studies, account backup, 기본 AI, home content, suggestion과
  새 민감 권한 요청을 제한한다. Translation은 유지하되 자동 popup은 끈다. 종료 시
  cache, form data와 history만 지우고 cookie, session과 site setting은 보존한다.
  Site permission 예외는 사용자가 GUI에서 허용한다.

`pclean`은 사용자 확인 후 실행하며 browser data, network/firewall policy와 Windows
host data를 건드리지 않는다. Neovim Lua Language Server telemetry는 끄고 plugin
update는 사용자 명령으로만 시작한다. 편집·terminal 복구 상태의 예외는 `STATE-001`이
소유한다.

**Change condition:** persistent state, background request, 저장 위치·수명·삭제 범위와
journal vacuum을 바꾸려면 명시적인 사용자 결정이 필요하다.

## AUTH-001

**Name:** 인증 경로

**Locators:** `config/system/security/faillock.conf`, `config/system/pam.d/greetd`,
`config/system/greetd/`, `scripts/bootstrap.sh`

**Why:** login UI의 존재만으로 PAM enforcement와 credential store 연결을 보장할 수
없으므로 실제 인증 경로의 책임을 명시한다.

**Boundary:** `config/system/security/faillock.conf`의 `fail_interval = 900`, `deny = 10`,
`unlock_time = 300`이 PAM stack의 15분 동안 10회 실패 후 5분 잠금을 소유한다.
Graphical login의 PAM path는 `gnome-keyring` Secret Service도 unlock하여 session
application이 같은 credential store를 사용하게 한다. 진단 기록의 보존과 정리는
`DATA-001`이 소유한다.

**Change condition:** login/authentication 경로 또는 faillock 값을 바꾸려면 명시적인
사용자 결정이 필요하다.

## STATE-001

**Name:** Interactive state와 persistence 예외

**Locators:** `config/tmux/tmux.conf`, `docs/tmux-workflow.md`,
`config/nvim/init.lua`

**Why:** 편집·terminal 편의를 위한 상태도 저장 위치와 수명을 모르면 privacy와 recovery
동작을 예측할 수 없다.

**Boundary:** tmux scrollback, mark와 buffer는 server memory에만 두며 session persistence
plugin이나 disk history를 추가하지 않는다. Bash 진입점과 관리 명령은 `main`이라는
하나의 tmux server를 공유하며 user-assigned window name을 자동으로 바꾸지 않는다.
Neovim은 일반 file history를 최소화하되 ShaDa, undo와 view는 명시적으로 유지하는 작업
복구 예외다.

**Change condition:** state를 disk에 기록하거나 lifetime 또는 recovery 범위를 바꿀 때
변경한다.

## NVIM-001

**Name:** Neovim 범위와 구성 구조

**Locators:** `config/nvim/init.lua`, `config/nvim/AGENTS.md`

**Why:** 개인 편집기의 단일 탐색 지점과 제한된 plugin 범위를 유지해야 작은 keymap이나
option 변경이 module·문서 전반으로 번지지 않는다.

**Boundary:** Neovim 설정은 `config/nvim/init.lua` 한 파일에 유지하고 기존 fold와
의도적으로 비활성화한 rollback option을 보존한다. Inline `Workflow reference`가
사용자 interface를 소유한다. 범위는 빠른 local edit/review, 단일-file 문제, 인접 파일
관리, Git change review와 정확한 file reference다. Project build, test, dependency,
debugging과 광범위한 automation은 terminal 또는 project가 소유한다. Plugin은 대체할
수 없는 기능에만 사용하며 Treesitter와 새 LSP/completion 범위는 명시적 요청 없이
추가하지 않는다.

**Change condition:** 설정 분할, workflow 위치, editor/project 소유권, plugin 또는 LSP
범위를 바꿀 때만 변경한다.

## COLOR-001

**Name:** Paper color system

**Locators:** `docs/color_system.md`

**Why:** 색상 literal을 개별 UI에서 독립적으로 바꾸면 같은 semantic state가 서로 다른
의미로 보인다.

**Boundary:** `docs/color_system.md`가 token과 semantic role의 상세 specification이다.
Consumer 추가·교체는 palette 변경 권한이 아니며 token 또는 의미 변경에는 명시적인
사용자 결정이 필요하다. 유지하는 desktop UI는 white card보다 border를 우선하고 solid
accent는 의미 있는 state에만 사용한다. Desktop consumer는 설정 값을 쓰는 것뿐 아니라
실제 owning application/toolkit/compositor가 해당 semantic mapping을 소비하는지
확인해야 한다.

**Change condition:** token, palette, semantic role 또는 명시된 예외를 바꿀 때만
변경한다.
