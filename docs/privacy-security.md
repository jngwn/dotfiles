# 개인정보와 보안 운영 정책

이 문서는 Arch Linux 시스템과 유지 관리하는 애플리케이션에 공통으로 적용되는
개인정보, 보안과 데이터 보존 정책을 소유한다. 데스크톱 세션 구현은 이 공통 정책과
독립된 통합 세부사항만 자체 workflow 문서에 기록한다.

## 원칙과 한계

- 반복적인 외부 통신은 사용자가 시작하는 경로를 우선한다. telemetry, 실험, crash
  upload, 자동 update 확인, 위치 조회와 cloud 동기화는 명시적인 결정 없이 추가하지
  않는다.
- 로컬 기록은 필요한 범위와 수명을 먼저 정하고, 민감한 세션 상태는 가능하면
  `$XDG_RUNTIME_DIR`에 둔다. 사용자 데이터, 휴지통, browser state, credential이나
  광범위한 개발 cache는 자동으로 삭제하지 않는다.
- 이 구성은 unsolicited inbound 연결을 제한하지만 일반 애플리케이션의 outbound
  통신을 차단하지 않는다. 익명화 네트워크, application firewall 또는 전체 공급망을
  격리하는 hardened OS로 간주하지 않는다.
- 1일 system journal 보존은 장기 감사와 침해사고 조사 능력보다 로컬 metadata
  최소화를 우선하는 선택이다.

예약 timer나 로그인 시 자동 update는 구성하지 않는다. 공유 shell 명령의 정확한
update·cleanup 범위는 `config/bash/aliases.sh`가 소유하며, 이 문서는 그 구현을
중복해서 정의하지 않는다.

## 네트워크 개인정보와 방화벽

Bootstrap은 NetworkManager가 연결별 DNS와 routing domain을 `systemd-resolved`에
전달하도록 구성하고 `/etc/resolv.conf`를 local stub resolver에 연결한다. 공유
resolver 설정은 특정 public DNS 사업자나 strict DNS-over-TLS(DoT)를 강제하지 않아
VPN과 profile별 DNS 예외를 함께 사용할 수 있다. NetworkManager의 주기적 HTTP
연결 상태 확인은 끄며, captive portal은 연결 후 browser를 직접 열어 사용한다.

Bootstrap 실행 시점에 존재하는 유선·Wi-Fi profile에는 다음 `trusted` 정책을
저장한다.

- 무작위 MAC 주소(`cloned-mac-address=random`)
- Cloudflare `1.1.1.1`, `1.0.0.1`과 인증 이름 `one.one.one.one`을 사용하는 strict DoT
- DHCP가 제공한 자동 DNS 무시
- IPv6 비활성화

실행 중인 연결은 다시 활성화하지 않으므로 다음 profile 활성화나 재부팅부터 적용된다.
이후 새로 만든 profile은 bootstrap을 다시 실행해 적용하며 VPN profile은 변경하지
않는다. resolver 선행 조건이 충족되지 않으면 profile을 변경하지 않고 해당 작업을
실패로 기록한 뒤 나머지 bootstrap을 계속한다. profile 하나를 변경하지 못해도 나머지
profile을 모두 시도한 뒤 작업 전체를 실패로 보고한다.

`trusted`는 이름이나 용도가 아니라 NetworkManager 연결 유형만 보고 현재의 모든
유선·Wi-Fi profile에 적용한다. hotspot, connection sharing, 고정 MAC이나 DHCP DNS가
필요한 네트워크는 자동 예외가 아니다. 공유 설정의 `ipv6.ip6-privacy=2`는 IPv6를
명시적으로 활성화한 profile에서만 privacy address를 선호하는 fallback으로 동작한다.
DHCP hostname 전송 억제와 여러 동시 연결 사이의 negative DNS priority는 이 정책에
포함하지 않는다. VPN split DNS와 profile routing의 기존 소유권을 보존하기 위한
경계다.

firewalld는 기본 firewall backend다. fresh local bootstrap은 사용자 override가 없을
때 Arch `public` zone의 packaged SSH allow rule을 제거한다. 기존 zone과 rule은
보존하며 SSH 세션에서 bootstrap을 실행하면 현재 접속 유지를 위해 SSH를 허용한다.
UFW가 이미 active 또는 enabled 상태이고 firewalld가 설치되지 않은 경우에만 UFW를
계속 사용한다. 두 backend 모두 unsolicited inbound 연결은 차단하지만 outbound
연결은 허용한다.

현재 profile과 DNS 설정은 다음 명령으로 확인한다.

```sh
nmcli -f NAME,UUID,TYPE,DEVICE connection show --active
nmcli -f connection.id,connection.dns-over-tls,ipv4.dns,ipv4.ignore-auto-dns,ipv6.method,ipv6.dns,ipv6.ignore-auto-dns connection show "<CONNECTION_NAME>"
```

DNS 주소만 설정하고 strict DoT와 인증 이름을 생략하면 암호화가 활성화되지 않는다.
IPv4 resolver도 A와 AAAA 질의를 모두 처리하므로 IPv6 DNS 주소가 필수는 아니다.
적용 후에는 다음 명령으로 resolver 상태를 확인한다.

```sh
readlink -f /etc/resolv.conf
resolvectl status
resolvectl query example.com
```

`/etc/resolv.conf`는 `/run/systemd/resolve/stub-resolv.conf`를 가리켜야 한다.
`resolvectl status`의 해당 link에 `+DNSOverTLS`와 지정한 DNS 서버가 보여야 strict
DoT가 적용된 상태다. strict DoT는 TLS 연결에 실패하면 평문 DNS로 downgrade하지
않으므로 공공망이 TCP 853을 차단하면 이름 해석도 실패하는 것이 정상이다.

DoT는 장비와 선택한 resolver 사이의 DNS 질의만 보호한다. resolver 운영자는 질의를
처리할 수 있고 접속 대상 IP나 애플리케이션 자체 통신까지 숨기지는 않는다. 별도
package나 proxy가 필요한 system-wide DoH service는 추가하지 않는다.

## Firefox

Firefox system policy는 desktop session과 독립적으로 bootstrap이
`/etc/firefox/policies/policies.json`에 설치한다. 주요 의도는 다음과 같다.

- telemetry, studies, remote improvements, Firefox account와 browser data backup 비활성화
- 기본 AI 기능 차단, 번역 기능만 사용 가능, 자동 번역 popup 비활성화
- strict tracking protection, HTTPS-only mode와 Global Privacy Control 사용
- Firefox Home content, search suggestion, sponsored suggestion과 recommendation 비활성화
- 새 camera, microphone, location, notification, screen-share와 VR 권한 요청 기본 차단
- 종료할 때 cache, form data와 history를 지우되 cookie, session과 site setting은 보존
- 주소·신용카드 autofill과 새 login 저장 제안 비활성화

권한이 필요한 site는 사용자가 Firefox GUI에서 직접 예외를 허용한다. 전체 정책과
적용 상태는 Firefox의 `about:policies`에서 확인한다.

### DNS 경로

Firefox policy는 Secure DNS/DoH를 끈다. DNS 암호화를 끄는 설정이 아니라 browser가
독자적인 DoH endpoint로 질의하지 않고 OS resolver에 전달하게 하는 설정이다.

```text
Firefox·일반 앱 → systemd-resolved → connection profile의 upstream DNS
```

DoH와 DoT는 모두 TLS로 DNS 질의를 암호화한다. 이 구성에서 DoH를 끄는 이유는 DoT보다
약해서가 아니라 browser만 별도 resolver를 사용하지 않게 하려는 것이다. 회사·VPN·
내부망의 split DNS는 OS resolver가 올바른 DNS 서버로 보내지만 browser에 Cloudflare
DoH를 고정하면 그 경로를 건너뛸 수 있다. 유선·Wi-Fi의 `trusted` 기본값에서는 OS가
이미 Cloudflare strict DoT를 사용하므로 별도의 browser DoH는 필요하지 않다.

## 그 밖의 애플리케이션 telemetry

애플리케이션별 설정 파일은 각 애플리케이션의 정본 위치를 유지한다. 이 문서는 공통
privacy 관점에서 현재의 outbound·background 동작만 모아 기록한다.

- VS Code는 `config/Code/User/settings.json`에서 telemetry, application update,
  extension update 확인과 Git auto-fetch를 끈다. update와 synchronization은 사용자가
  명시적으로 시작한다.
- Neovim은 `config/nvim/init.lua`에서 Lua Language Server telemetry를 끈다. plugin
  update는 유지관리 명령을 사용자가 실행할 때만 시작한다.

## 데스크톱 세션 기록과 수명

데스크톱의 로컬 기록은 필요한 기능 범위 안에서만 유지한다.

- GTK 최근 파일 기록은 생성하지 않는다. 이를 따르지 않는 client가
  `recently-used.xbel`을 만들면 path unit이 감지하고 cleanup service가 삭제한다.
- Thunar의 thumbnail과 image preview는 비활성화하고, 기존 thumbnail cache에서는
  24시간이 지난 항목만 매일 정리한다.
- Cliphist는 복사한 text와 image를 권한이 `0700`인 `$XDG_RUNTIME_DIR/cliphist/`에만
  저장한다. Sway 로그인 시작에 DB를 비우고 로그아웃할 때 runtime directory를 제거한다.
- SwayNC의 알림 기록은 현재 세션에만 남고, ReGreet는 별도 파일 로그를 만들지 않으며
  경고 이상의 진단만 system journal에 보낸다.

batsignal은 로컬 전원 정보만 읽고 별도 기록이나 외부 통신을 만들지 않는다. 현재 Sway
세션 서비스별 외부 통신, 종료 동작과 hardware fallback은
[Sway 프로세스 수명주기](sway-workflow.md#어떤-프로세스가-언제-실행되는가)가 기록한다.

`pclean`의 정확한 정리 범위는 `config/bash/aliases.sh`가 소유한다. 이 명령은 browser
data, network 설정과 firewall policy를 건드리지 않으며, 그 범위를 자동으로 넓히지
않는다.

## 인증 실패와 system journal

Bootstrap은 `/etc/security/faillock.conf`에 15분 동안 10회 실패하면 5분 동안 잠그는
정책을 설치한다. 실제 적용 범위는 `pam_faillock`을 포함하는 PAM stack이며 다음 인증
시도부터 적용된다.

systemd-journald는 `MaxRetentionSec=1day`와 `MaxFileSec=1day`를 사용한다. Bootstrap은
설정을 설치하고 journald를 다시 시작한 뒤 기존 1일 초과 journal을 rotate·vacuum한다.
ReGreet와 Sway가 system journal에 보내는 진단도 같은 보존 한계를 따른다.

## 정본과 적용 시점

| 대상 | 저장소 정본 | 적용 시점 |
|---|---|---|
| Firewall 기본 정책 | `scripts/bootstrap.sh` | bootstrap이 backend를 enable하고 rule을 적용한 직후 |
| NetworkManager privacy | `config/system/NetworkManager/conf.d/99-privacy.conf` | bootstrap 설치와 NetworkManager reload 후 |
| System resolver | `config/system/systemd/resolved.conf.d/60-network-privacy.conf` | bootstrap 설치와 `systemd-resolved` 시작 후 |
| 유선·Wi-Fi `trusted` profile | `scripts/bootstrap.sh` | bootstrap 저장 후 다음 profile 활성화; 이후 만든 profile은 bootstrap 재실행 필요 |
| Firefox policy | `config/system/firefox/policies/policies.json` | bootstrap 설치 후 Firefox를 완전히 다시 실행할 때 |
| VS Code privacy | `config/Code/User/settings.json` | dotfile 배포 후 VS Code를 완전히 다시 실행할 때 |
| Neovim LSP telemetry | `config/nvim/init.lua` | dotfile 배포 후 다음 Neovim 실행부터 |
| GTK 최근 파일과 thumbnail 보존 | GTK·Thunar 설정과 `config/systemd/user/desktop-data-cleanup.*` | dotfile 배포 후 애플리케이션을 다시 실행하고 user daemon reload 후 path·timer를 다시 시작할 때 |
| 세션 clipboard 보존 | `config/cliphist/`와 `config/systemd/user/cliphist-*.service` | dotfile 배포 후 `sway-session.target`을 다시 시작할 때 |
| 인증 실패 policy | `config/system/security/faillock.conf` | bootstrap 설치 후 다음 PAM 인증부터 |
| System journal 보존 | `config/system/systemd/journald.conf.d/60-privacy-retention.conf` | bootstrap 설치와 journald 재시작 직후 |

저장소 파일 변경만으로 실행 중인 시스템에는 반영되지 않는다. 시스템 정책은
`scripts/bootstrap.sh`가 설치·적용하고 사용자 설정은 `scripts/deploy_dotfiles.sh`가
배포한다. Repository-only 검증에서는 어느 workflow도 실행하지 않는다.
