# tmux 사용법

이 구성의 prefix는 backtick(`` ` ``)이다. `prefix d`는 backtick을 누른 뒤 `d`를
누른다는 뜻이며 기본 `Ctrl-b`는 해제되어 있다. 실제 키와 옵션은
[`tmux.conf`](../config/tmux/tmux.conf), shell 진입점은
[`aliases.sh`](../config/bash/aliases.sh)에서 확인한다.

## Session 시작과 복귀

Session은 여러 window를, window는 여러 pane을 담는다. Detach는 terminal 연결만
끊고 process를 계속 실행한다. Pane의 shell에서 `exit`하면 해당 shell이 종료되며,
마지막 pane이면 window나 session도 종료될 수 있다.

Shell 진입점과 관리 alias는 `main`이라는 named server를 공유한다. tmux 밖에서
직접 명령을 실행할 때도 `-L main`으로 같은 server를 지정한다.

| 명령 | 동작 |
| --- | --- |
| `ajrtm` | `main` session 생성 또는 복귀 |
| `ajrtm1` … `ajrtm5` | `main1` … `main5` session 생성 또는 복귀 |
| `tmls` | Session 목록 |
| `tmat <session-name>` | 기존 client를 유지하며 attach |
| `tmdt` | 현재 client detach |
| `tmkl -t <session-name>` | 지정 session 종료 |

`ajrtm*`는 기존 client를 detach하고 현재 terminal이 session을 이어받는다. 여러
terminal이 같은 session을 동시에 보려면 `tmat`을 사용한다. 임의 이름으로 새
session을 만들 때는 설정 파일을 지정한다. 첫 window 이름은 `-n <window-name>`으로
추가할 수 있다.

```sh
tmux -L main -f ~/.config/tmux/tmux.conf new-session -s <session-name>
```

| Session 키 | 동작 |
| --- | --- |
| `prefix d` | Detach |
| `prefix s` | Session 선택 |
| `prefix (` / `prefix )` | 이전 / 다음 session |
| `prefix $` | Session 이름 변경 |

## Window와 Pane

전체 binding은 `prefix ?` 또는 `tmux list-keys`로 확인한다.

| Window 키 | 동작 |
| --- | --- |
| `prefix c` | 새 window |
| `prefix <number>` | 번호로 전환 |
| `prefix n` / `prefix p` | 다음 / 이전 window |
| `` prefix ` `` | 직전에 사용한 window |
| `prefix w` | Window 목록 |
| `prefix ,` | 이름 변경 |
| `prefix m` | 임시 mark 전환 |
| `prefix &` | 현재 window 종료 |
| `Ctrl+Shift+Left/Right` | Prefix 없이 앞/뒤 번호의 window와 자리를 바꾸고 선택 |

Window 이름은 자동으로 바뀌지 않으므로 작업 이름을 직접 붙인다. Mark한 이름은
밑줄로 표시되며 server가 종료되면 사라진다.

| Pane 키 | 동작 |
| --- | --- |
| `prefix \|` / `prefix -` | 현재 pane의 directory에서 좌우 / 위아래 분할 |
| `prefix h/j/k/l` | 왼쪽 / 아래 / 위 / 오른쪽 pane |
| `prefix q` / `prefix o` | 번호 표시 / 다음 pane |
| `prefix z` | 현재 pane 확대 또는 복원 |
| `prefix x` | Pane 종료 확인 |
| `prefix !` | Pane을 새 window로 분리 |
| `prefix Space` | 미리 정의된 layout 전환 |
| `prefix Shift+방향키` | 경계를 해당 방향으로 2칸 조절 |
| `prefix y` | 현재 window의 입력 동기화 전환 |

크기 조절은 repeat가 켜져 있어 prefix 없이 연속 입력할 수 있다. 정확한 크기가
필요하면 `prefix :`에서 `resize-pane -L 10`처럼 방향(`-L/-R/-U/-D`)과 칸 수를
지정한다.

입력 동기화가 켜지면 한 pane의 키가 모든 pane에 전달된다. 삭제·종료·암호 입력
전에는 아래 값이 `off`인지 확인한다. `on`이면 `prefix y`로 끈다. 상태를 상시
표시하지 않으므로 toggle message만으로 추측하지 않는다.

```sh
tmux show-window-options -v synchronize-panes
```

### Foreground 작업과 일시 정지

다른 작업을 보려면 window 전환이나 detach를 사용한다. `Ctrl-Z`는 foreground
process를 일시 정지하므로 작업이 진행되지 않으며, process가 보유한 lock이나 socket도
남을 수 있다. 중지한 작업을 다시 실행하기보다 원래 shell에서 복귀한다.

```sh
jobs -l
fg
```

중지된 job이 여러 개라면 `fg %<job-number>`를 사용한다. 나중에 application의
resume 기능으로 다시 열려면 기존 process를 정상 종료하고 shell prompt로 돌아왔는지
먼저 확인한다. Session 파일 삭제나 외부 도구로 강제 종료하는 방식은 일반 복구
절차로 사용하지 않는다.

### Background 작업 완료 표시

Background window의 프로그램이 BEL을 보내면 해당 window에 `!`와 차분한 파란 배경이
표시된다. Window를 선택하면 사라진다. 소리·flash·popup이나 일반 출력 감시는 없으며,
BEL을 보내지 않는 일회성 명령에는 필요할 때 다음처럼 완료 신호를 붙인다.

```sh
long-running-command; printf '\a'
```

## 복사와 Clipboard

Copy mode는 vi 키를 사용한다.

| 키 | 동작 |
| --- | --- |
| `prefix [` | Copy mode 진입 |
| `h/j/k/l` | 선택 위치 이동 |
| `v` / `V` | 문자 / 줄 선택 시작 |
| `r` | 사각형 선택 전환 |
| `y` | 복사하고 copy mode 종료 |
| `q` | Copy mode 종료 |
| `prefix ]` | tmux paste buffer 붙여넣기 |

Copy mode의 Enter 복사는 해제되어 있다. `y`와 마우스 선택은 tmux buffer를 갱신하고,
가능하면 local clipboard나 terminal integration에도 전달한다. System clipboard가
없어도 `prefix ]`로 붙여넣을 수 있다. 전달 경계는
[`CLIPBOARD-001`](contracts.md#clipboard-001)을 따른다.

Scrollback과 copy buffer는 server 종료 시 사라진다. 먼저 지우려면 아래 명령을 쓴다.
`clear-history`는 현재 pane의 과거 scrollback만 지우며, 이미 전달한 desktop clipboard는
별도로 지워야 한다. 저장 수명과 예외는 [`STATE-001`](contracts.md#state-001)이 소유한다.

```sh
tmux clear-history
tmux list-buffers
tmux delete-buffer -b <buffer-name>
```

## Nested tmux

안쪽 application에 현재 prefix를 전달하려면 `prefix e`를 사용한다. 안쪽 tmux가
같은 prefix를 쓴다면 새 window는 `prefix e c`로 만든다. Backtick을 두 번 누르는
조합은 prefix 전달이 아니라 직전 window 전환이다.

## 설정 적용과 복구

저장소 변경의 배포 절차는 [README](../README.md#bootstrap-dotfile-deployment-and-recovery)를
따른다. 배포 후 기존 server에서 설정을 다시 읽는다.

```sh
tmux -L main source-file ~/.config/tmux/tmux.conf
```

현재 binding은 `tmux list-keys`, session 옵션은 `tmux show-options -g`, window 옵션은
`tmux show-options -gw`로 확인한다. 색상이 이상하면 tmux 안팎의 terminal 정보를
비교한다.

```sh
printf '%s\n' "$TERM" "$COLORTERM" "$TERM_PROGRAM"
tmux display-message -p '#{client_termname}'
```

설정은 `tmux-256color` terminfo가 없으면 `screen-256color`로 대체한다. 바깥 `TERM`이
`screen`, `tmux`, `linux`가 아닌 경우 `COLORTERM=truecolor`를 전달한다.

### 입력이나 Enter가 동작하지 않을 때

먼저 현재 application이나 tmux의 입력 상태를 확인한다. `Esc`는 application의
불완전한 입력, `Ctrl-g`는 readline이나 command prompt의 입력을 취소할 때 사용하고,
copy mode에서는 `q`로 나온다. 키를 무작정 연속 입력하지 않는다.

Shell prompt로 돌아왔는데도 terminal 상태가 이상하면 다음을 실행한다.

```sh
stty sane
reset
```

Enter가 동작하지 않으면 각 명령을 입력한 뒤 `Ctrl-j`로 실행한다. Foreground
process를 중단해도 되는 경우에만 `Ctrl-c`로 prompt로 돌아온다. Pane의 process를
모두 버려도 될 때만 아래 명령을 사용한다. Window와 layout은 유지하지만 해당 pane의
process는 종료된다.

```sh
tmux respawn-pane -k
```
