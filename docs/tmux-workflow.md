# tmux 사용법

key와 tmux option은 [`tmux.conf`](../config/tmux/tmux.conf)를 기준으로 한다.
shell 진입점과 관리 alias는 [`aliases.sh`](../config/bash/aliases.sh)가 소유하며
설정이 바뀌면 이 문서보다 `tmux list-keys`와 해당 구현 파일을 우선한다.

prefix:

    `

아래의 "prefix d"는 backtick을 한 번 누른 뒤 d를 누른다는 뜻이다.
기본 prefix인 Ctrl-b는 해제되어 있다.


---

## 1. 기본 개념

    session : tmux의 가장 큰 작업 단위. 여러 window를 가진다.
    window  : session 안의 탭에 해당한다.
    pane    : window 안에서 분할된 terminal 영역이다.

detach는 session과 process를 종료하지 않고 현재 terminal에서만 빠져나온다.
shell에서 exit하면 현재 pane의 shell이 종료되며, 마지막 pane이면 window나
session도 함께 끝날 수 있다.


---

## 2. session

이 저장소의 shell 진입점과 관리 alias는 `main`이라는 named tmux server를
공유한다. tmux 밖에서 원래 명령을 직접 사용할 때도 `tmux -L main`으로 같은
server를 지정한다. 새 server를 직접 시작할 때는 배포된 설정도 함께 지정한다.

    ajrtm
    ajrtm1 ... ajrtm5
        main, main1 ... main5 session을 생성하거나 이어받아 attach

    tmux -L main -f ~/.config/tmux/tmux.conf new-session -s <session-name>
        임의 이름의 session 생성

    tmux -L main -f ~/.config/tmux/tmux.conf new-session -s <session-name> -n <window-name>
        session과 첫 window 이름을 함께 지정

    tmux -L main list-sessions
    tmls
        session 목록

    tmux -L main attach-session -t <session-name>
    tmat <session-name>
        기존 client를 유지하면서 지정한 session에 attach

`ajrtm*`의 `-AD` 동작은 같은 session에 붙어 있던 기존 client를 detach하고 현재
terminal이 이어받게 한다. 평소 하나의 foreground terminal에서 작업을 계속하는
진입점이다. 여러 terminal이 같은 session을 동시에 봐야 할 때는 기존 client를
detach하지 않는 `tmat <session-name>`을 명시적으로 사용한다.

    tmux -L main detach-client
    tmdt
        현재 client를 detach

    tmux -L main kill-session -t <session-name>
    tmkl -t <session-name>
        지정한 session 종료

    prefix d
        현재 session에서 detach

    prefix s
        session 선택

    prefix (
        이전 session

    prefix )
        다음 session

    prefix $
        session 이름 변경


---

## 3. window

    prefix c
        현재 pane의 working directory에서 새 window 생성

    prefix <number>
        번호로 window 전환

    prefix n
        다음 window

    prefix p
        이전 window

    prefix `
        직전에 사용한 window로 전환

    prefix w
        window 목록

    prefix ,
        현재 window 이름 변경

    prefix m
        현재 window의 임시 mark를 toggle

    prefix &
        현재 window 종료

    Ctrl-Shift-Left
        prefix 없이 현재 window를 앞 번호로 이동하고 선택

    Ctrl-Shift-Right
        prefix 없이 현재 window를 뒤 번호로 이동하고 선택

window 이름은 병렬 작업을 구분하는 사용자 소유 label이다. foreground command나
application이 자동으로 바꾸지 않으므로 `prefix ,`로 직접 지정한다. `prefix m`으로
mark한 window 이름은 underline으로 표시되며, mark는 tmux server memory에만
유지되고 server가 종료되면 사라진다.

### foreground TUI와 `Ctrl-Z`

다른 tmux window를 확인하려는 목적이라면 foreground TUI에서 `Ctrl-Z`를 누르지
않고 `prefix <number>`, `` prefix ` ``, `prefix n`, `prefix p`, `prefix w`로 window를
전환한다. tmux window 전환이나 detach는 해당 pane의 foreground process를 그대로
실행해 두지만, `Ctrl-Z`는 shell job control을 통해 process를 종료하지 않고
일시 정지한다. 일시 정지된 process도 자신이 보유한 session, lock, socket 같은
외부 자원의 owner로 남을 수 있다.

Codex TUI를 `Ctrl-Z`로 일시 정지한 뒤 같은 session에 `codex resume`을 새로
실행하면, 기존 process가 thread writer를 계속 보유하므로 `already has an active
writer` 오류가 발생할 수 있다. 이 경우 새 process를 만들거나 기존 process를
강제 종료하는 대신, 원래 shell job으로 돌아간다.

    jobs -l
    fg

중지된 job이 여러 개라면 `jobs -l`에서 번호를 확인한 뒤 `fg %<job-number>`를
사용한다. 나중에 `codex resume`으로 다시 열어야 한다면 먼저 기존 Codex TUI를
정상 종료하여 shell prompt로 돌아왔는지 확인한다. session JSONL 삭제나 btop
같은 외부 도구를 이용한 강제 종료는 일반적인 복구 절차로 사용하지 않는다.


---

## 4. pane 생성과 이동

    prefix |
        현재 pane의 working directory에서 좌우 분할

    prefix -
        현재 pane의 working directory에서 위아래 분할

    prefix h
        왼쪽 pane으로 이동

    prefix j
        아래 pane으로 이동

    prefix k
        위 pane으로 이동

    prefix l
        오른쪽 pane으로 이동

    prefix q
        pane 번호 표시

    prefix o
        다음 pane으로 이동

    prefix z
        현재 pane 확대 또는 원래 layout으로 복원

    prefix x
        현재 pane 종료 확인

    prefix !
        현재 pane을 새 window로 분리

    prefix Space
        predefined pane layout 전환


---

## 5. pane 크기와 동기화

    prefix Shift-Left
        왼쪽으로 2칸 조절

    prefix Shift-Right
        오른쪽으로 2칸 조절

    prefix Shift-Up
        위로 2칸 조절

    prefix Shift-Down
        아래로 2칸 조절

resize key는 repeat가 활성화되어 있어 prefix를 다시 누르지 않고 연속 입력할 수
있다.

정확한 크기를 지정하려면 command prompt를 사용한다.

    prefix :
    resize-pane -L 10

    prefix :
    resize-pane -R 10

    prefix :
    resize-pane -U 5

    prefix :
    resize-pane -D 5

    prefix y
        현재 window의 synchronize-panes를 toggle

synchronize-panes가 켜지면 한 pane의 키 입력이 모든 pane에 전달된다. 여러 pane에서
같은 명령을 실행할 때 유용하지만, 삭제·종료·암호 입력 전에는 현재 값을 확인한다.

```sh
tmux show-window-options -v synchronize-panes
```

`on`이면 다시 prefix y를 눌러 끈다. 현재 status line에는 이 상태를 계속 표시하지
않으므로 transient toggle message만으로 상태를 추측하지 않는다.

### background 작업 완료 표시

background window의 프로그램이 명시적인 BEL을 보내면 해당 window가 `!`와
차분한 파란 배경으로 표시된다. window를 선택하면 표시가 사라진다. 이 동작은 tmux
status의 해당 window 항목에만 남는 수동 완료 신호이며 소리, 화면 flash, popup을
만들지 않고 일반 출력도 감시하지 않는다.

BEL을 지원하지 않는 일회성 명령은 필요할 때만 다음처럼 실행한다.

```sh
long-running-command; printf '\a'
```


---

## 6. copy mode와 clipboard

현재 copy mode는 vi key를 사용한다.

    prefix [
        copy mode 진입

    h j k l
        vi 방식으로 이동

    v
        문자 단위 선택 시작

    V
        줄 단위 선택 시작

    r
        rectangle selection toggle

    y
        선택을 복사하고 copy mode 종료

    q
        copy mode 종료

    prefix ]
        tmux paste buffer 붙여넣기

기본 copy-mode-vi의 Enter 복사는 해제되어 있으므로 선택 후 y를 사용한다.

clipboard 연동은 실행 환경에 따라 자동으로 선택된다.

    Linux Wayland    wl-copy

해당 명령이나 display 환경이 없으면 tmux 자체 buffer를 사용한다. 시스템
clipboard를 사용할 수 없는 session에서도 y로 tmux buffer에는
복사할 수 있고 prefix ]로 붙여넣을 수 있다.

마우스 drag selection도 같은 clipboard 정책을 사용한다.

### scrollback과 copy buffer의 수명

각 pane의 scrollback은 최대 10,000줄이며 tmux server memory에만 유지된다.
tmux copy buffer도 같은 server의 memory에 남는다. 둘 다 detach 후에는 유지되지만
tmux 자체는 repository나 별도 disk history에 저장하지 않는다. pane을 닫으면 해당
scrollback이 사라지고 마지막 session과 server가 종료되면 남아 있던 tmux state도
사라진다.

현재 pane의 과거 scrollback이나 tmux copy buffer를 먼저 지워야 할 때는 다음처럼
명시적으로 처리한다.

    tmux clear-history
    tmux list-buffers
    tmux delete-buffer -b <buffer-name>

`clear-history`는 현재 화면이 아니라 현재 pane의 과거 scrollback을 지운다. tmux
copy buffer를 지워도 이미 전달된 desktop clipboard 내용은 별도 owner의 state라서
함께 지워지지 않는다.


---

## 7. nested tmux와 prefix 전달

tmux 안에서 또 다른 tmux를 명시적으로 실행하면 두 session의 prefix가 중첩될 수
있다.

    prefix e
        현재 tmux의 prefix 입력을 안쪽 application에 전달

예를 들어 안쪽 tmux에서 새 window를 만들려면 바깥 tmux에서 다음 순서로
입력한다.

    prefix e c

`prefix + backtick`은 send-prefix가 아니라 last-window에 할당되어 있으므로
nested tmux prefix 전달에는 e를 사용한다.


---

## 8. 설정 확인과 reload

    prefix ?
        현재 key binding 목록

    tmux list-keys
        전체 binding 출력

    tmux show-options -g
        global session option 확인

    tmux show-options -gw
        global window option 확인

설정 reload:

    tmux source-file ~/.config/tmux/tmux.conf

배포된 설정이 canonical repository 파일을 가리키는지 확인한다.

    readlink -f ~/.config/tmux/tmux.conf

색상이 이상하면 tmux 안팎의 terminal 정보를 비교한다.

    printf '%s\n' "$TERM" "$COLORTERM" "$TERM_PROGRAM"
    tmux display-message -p '#{client_termname}'

현재 설정은 tmux 안에서 tmux-256color를 사용하고, 적합한 desktop terminal에만
COLORTERM=truecolor를 전달한다.


---

## 9. 입력이나 Enter가 동작하지 않을 때

증상:

    ssh-add, sudo password, REPL, shell prompt 등에서 입력 후 Enter가
    반응하지 않거나 terminal 상태가 꼬인 것처럼 보인다.

먼저 현재 modal state를 빠져나온다.

    Esc
    Ctrl-g
    q

    Esc    : application의 불완전한 입력 상태 취소
    Ctrl-g : readline, tmux command prompt, prefix 대기 취소
    q      : tmux copy mode 종료

그래도 이상하면 현재 pane에서 실행한다.

    stty sane
    reset

Enter가 동작하지 않으면 Ctrl-j를 Enter 대신 사용할 수 있다.

    stty sane
    Ctrl-j
    reset
    Ctrl-j

실행 중인 foreground process를 중단해도 될 때:

    Ctrl-c
    stty sane
    reset

pane의 process를 모두 버려도 될 때만 다음을 사용한다.

    tmux respawn-pane -k

`respawn-pane -k`는 window와 layout은 유지하지만 해당 pane에서 실행 중이던
process를 종료한다.


---

## 10. 빠른 요약

    prefix                 `
    이전 window            prefix `
    새 window              prefix c
    window 이름 변경       prefix ,
    window mark toggle     prefix m
    좌우 분할              prefix |
    위아래 분할            prefix -
    pane 이동              prefix h/j/k/l
    pane 크기              prefix Shift-arrow
    pane 동기화 toggle     prefix y
    copy mode              prefix [
    선택/복사              v 또는 V, y
    paste                  prefix ]
    detach                 prefix d
    nested prefix 전달     prefix e
