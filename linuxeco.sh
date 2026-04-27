#!/usr/bin/env bash
# ==============================================================================
#  Linuxeco — Ecosystem Installer for Creators
# ==============================================================================
#  Instala um ecossistema Linux completo para criativos, desenvolvedores e
#  quem busca o melhor software. Prioriza FOSS, usa Flatpak para GUI e
#  apt para CLI.
#
#  Suporte: ZorinOS 18+ / Linux Mint 22.x / Ubuntu 24.04+ (derivados)
#
#  Uso:  chmod +x linuxeco.sh && ./linuxeco.sh
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

if [[ "${TERM:-}" == "dumb" ]] || ! command -v locale &>/dev/null; then
    E_OK="✓" E_SKIP="○" E_INFO="→" E_WARN="⚠" E_ERR="✗" E_PKG="◆"
else
    E_OK="✅" E_SKIP="⏭️" E_INFO="🔍" E_WARN="⚠️" E_ERR="❌" E_PKG="📦"
fi

LOG_FILE="/tmp/linuxeco-install-$(date +%Y%m%d_%H%M%S).log"

log()   { echo -e "$@" | tee -a "$LOG_FILE"; }
ok()    { log "${GREEN}${E_OK} ${NC}$*"; }
skip()  { log "${DIM}${E_SKIP} ${NC}$*"; }
info()  { log "${CYAN}${E_INFO} ${NC}$*"; }
warn()  { log "${YELLOW}${E_WARN} ${NC}$*"; }
err()   { log "${RED}${E_ERR} ${NC}$*"; }
header(){ log "\n${BOLD}${MAGENTA}$*${NC}"; }
section(){ log "\n${BLUE}${BOLD}▸ $*${NC}"; }

COUNT_INSTALLED=0
COUNT_SKIPPED=0
COUNT_FAILED=0

# ══════════════════════════════════════════════════════════════════════════════
#  FUNCOES UTILITARIAS
# ══════════════════════════════════════════════════════════════════════════════

cmd_exists() {
    command -v "$1" &>/dev/null
}

deb_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

flatpak_installed() {
    flatpak list --app --columns=application 2>/dev/null | grep -qFx "$1"
}

apt_available() {
    apt-cache show "$1" &>/dev/null 2>&1
}

apt_install() {
    local pkgs=()
    for pkg in "$@"; do
        if deb_installed "$pkg"; then
            skip "apt: $pkg ja instalado"
            ((COUNT_SKIPPED++)) || true
        else
            pkgs+=("$pkg")
        fi
    done
    if (( ${#pkgs[@]} > 0 )); then
        info "apt install: ${pkgs[*]}"
        if sudo apt-get install -y "${pkgs[@]}" 2>&1 | tee -a "$LOG_FILE" | tail -5; then
            for pkg in "${pkgs[@]}"; do
                if deb_installed "$pkg"; then
                    ok "apt: $pkg instalado"
                    ((COUNT_INSTALLED++)) || true
                else
                    err "apt: falha ao instalar $pkg"
                    ((COUNT_FAILED++)) || true
                fi
            done
        else
            for pkg in "${pkgs[@]}"; do err "apt: falha ao instalar $pkg"; ((COUNT_FAILED++)) || true; done
        fi
    fi
}

apt_install_silent() {
    local pkgs=()
    for pkg in "$@"; do
        if deb_installed "$pkg"; then
            skip "apt: $pkg ja instalado"
            ((COUNT_SKIPPED++)) || true
        elif apt_available "$pkg"; then
            pkgs+=("$pkg")
        fi
    done
    if (( ${#pkgs[@]} > 0 )); then
        if sudo apt-get install -y "${pkgs[@]}" 2>&1 | tee -a "$LOG_FILE" | tail -3; then
            for pkg in "${pkgs[@]}"; do
                if deb_installed "$pkg"; then
                    ok "apt: $pkg instalado"
                    ((COUNT_INSTALLED++)) || true
                else
                    ((COUNT_FAILED++)) || true
                fi
            done
        else
            for pkg in "${pkgs[@]}"; do ((COUNT_FAILED++)) || true; done
        fi
    fi
}

flatpak_install() {
    local app_id="$1"
    local friendly_name="${2:-$app_id}"
    if flatpak_installed "$app_id"; then
        skip "flatpak: $friendly_name ja instalado ($app_id)"
        ((COUNT_SKIPPED++)) || true
    else
        info "flatpak install: $friendly_name ($app_id)"
        if flatpak install -y --noninteractive flathub "$app_id" 2>&1 | tee -a "$LOG_FILE" | tail -5; then
            ok "flatpak: $friendly_name instalado"
            ((COUNT_INSTALLED++)) || true
        else
            err "flatpak: falha ao instalar $friendly_name ($app_id)"
            ((COUNT_FAILED++)) || true
        fi
    fi
}

flatpak_install_if_available() {
    local app_id="$1"
    local friendly_name="${2:-$app_id}"
    if flatpak_installed "$app_id"; then
        skip "flatpak: $friendly_name ja instalado ($app_id)"
        ((COUNT_SKIPPED++)) || true
        return
    fi
    if flatpak remote-info flathub "$app_id" &>/dev/null; then
        flatpak_install "$app_id" "$friendly_name"
    else
        warn "$friendly_name nao disponivel no Flathub"
        ((COUNT_SKIPPED++)) || true
    fi
}

deb_url_install() {
    local url="$1"
    local friendly_name="${2:-$(basename "$url")}"
    local pkg_check="${3:-}"
    local tmp_deb
    tmp_deb="$(mktemp /tmp/install-XXXXXX.deb)"
    info "deb: baixando $friendly_name..."
    if wget -q --show-progress -O "$tmp_deb" "$url" 2>&1 | tee -a "$LOG_FILE"; then
        if sudo dpkg -i "$tmp_deb" 2>&1 | tee -a "$LOG_FILE"; then
            sudo apt-get install -f -y 2>&1 | tee -a "$LOG_FILE" | tail -3
            ok "deb: $friendly_name instalado"
            ((COUNT_INSTALLED++)) || true
        else
            sudo apt-get install -f -y 2>&1 | tee -a "$LOG_FILE" | tail -3
            local check_pkg="${pkg_check:-$friendly_name}"
            if deb_installed "$check_pkg"; then
                ok "deb: $friendly_name instalado (com correcoes)"
                ((COUNT_INSTALLED++)) || true
            else
                err "deb: falha ao instalar $friendly_name"
                ((COUNT_FAILED++)) || true
            fi
        fi
    else
        err "deb: falha ao baixar $friendly_name de $url"
        ((COUNT_FAILED++)) || true
    fi
    rm -f "$tmp_deb"
}

brew_install() {
    local formula="$1"
    local friendly_name="${2:-$formula}"
    if cmd_exists "$formula"; then
        skip "brew: $friendly_name ja disponivel no sistema"
        ((COUNT_SKIPPED++)) || true
    elif cmd_exists brew && brew list "$formula" &>/dev/null 2>&1; then
        skip "brew: $friendly_name ja instalado via brew"
        ((COUNT_SKIPPED++)) || true
    elif cmd_exists brew; then
        info "brew install: $friendly_name"
        if brew install "$formula" 2>&1 | tee -a "$LOG_FILE" | tail -5; then
            ok "brew: $friendly_name instalado"
            ((COUNT_INSTALLED++)) || true
        else
            err "brew: falha ao instalar $friendly_name"
            ((COUNT_FAILED++)) || true
        fi
    else
        warn "brew nao disponivel, pulando $friendly_name"
        ((COUNT_SKIPPED++)) || true
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  DETECCAO DE DISTRIBUICAO
# ══════════════════════════════════════════════════════════════════════════════
detect_distro() {
    if [[ ! -f /etc/os-release ]]; then
        err "Nao foi possivel detectar a distribuicao (/etc/os-release ausente)"
        exit 1
    fi

    source /etc/os-release

    DISTRO_ID="${ID:-unknown}"
    DISTRO_VERSION="${VERSION_ID:-0}"
    DISTRO_NAME="${NAME:-Unknown}"

    case "$DISTRO_ID" in
        zorin)
            info "Distribuicao detectada: ${BOLD}${DISTRO_NAME} ${DISTRO_VERSION}${NC}"
            if [[ "${DISTRO_VERSION%%.*}" -lt 18 ]]; then
                warn "ZorinOS 17 ou inferior detectado. Script otimizado para ZorinOS 18+"
            fi
            ;;
        linuxmint)
            info "Distribuicao detectada: ${BOLD}${DISTRO_NAME} ${DISTRO_VERSION}${NC}"
            if [[ "${DISTRO_VERSION%%.*}" -lt 22 ]]; then
                warn "Linux Mint 21 ou inferior detectado. Script otimizado para Mint 22+"
            fi
            ;;
        ubuntu|pop)
            info "Distribuicao detectada: ${BOLD}${DISTRO_NAME} ${DISTRO_VERSION}${NC}"
            if [[ "${DISTRO_VERSION%%.*}" -lt 24 ]]; then
                warn "Ubuntu 22.04 ou inferior detectado. Recomendado Ubuntu 24.04+"
            fi
            ;;
        *)
            warn "Distribuicao nao testada: $DISTRO_NAME"
            warn "O script foi projetado para ZorinOS 18+ / Mint 22+ / Ubuntu 24.04+"
            read -rp "Continuar? [s/N] " confirm
            [[ "${confirm,,}" != "s" ]] && exit 0
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
#  PREREQUISITOS DO SISTEMA
# ══════════════════════════════════════════════════════════════════════════════
setup_prerequisites() {
    header "PREPARANDO O SISTEMA"

    info "Atualizando lista de pacotes..."
    sudo apt-get update -y 2>&1 | tee -a "$LOG_FILE" | tail -3

    section "Dependencias fundamentais"
    apt_install \
        wget curl git software-properties-common \
        apt-transport-https ca-certificates gnupg \
        lsb-release dbus-x11 unzip gnupg2 \
        pkg-config libfuse2t64

    section "Flatpak"
    if cmd_exists flatpak; then
        skip "flatpak ja esta instalado"
    else
        apt_install flatpak
    fi

    if flatpak remotes 2>/dev/null | grep -q "flathub"; then
        skip "Flathub ja esta configurado"
    else
        info "Adicionando repositorio Flathub..."
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>&1 | tee -a "$LOG_FILE"
        ok "Flathub adicionado"
    fi

    info "Atualizando apps Flatpak existentes..."
    flatpak update -y --noninteractive 2>&1 | tee -a "$LOG_FILE" | tail -3 || true

    if ! deb_installed gnome-software-plugin-flatpak 2>/dev/null; then
        if apt_available gnome-software-plugin-flatpak 2>/dev/null; then
            apt_install gnome-software-plugin-flatpak
        fi
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  HOMEBREW (LINUXBREW)
# ══════════════════════════════════════════════════════════════════════════════
setup_homebrew() {
    header "HOMEBREW"

    if cmd_exists brew; then
        skip "Homebrew ja esta instalado"
        info "Atualizando Homebrew..."
        brew update 2>&1 | tee -a "$LOG_FILE" | tail -3 || true
        return
    fi

    info "Instalando Homebrew (Linuxbrew)..."
    apt_install build-essential procps curl file zlib1g-dev

    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1 | tee -a "$LOG_FILE"

    BREW_PATH="/home/linuxbrew/.linuxbrew/bin"
    if [[ -d "$BREW_PATH" ]]; then
        if ! grep -q "linuxbrew" ~/.bashrc 2>/dev/null; then
            info "Configurando PATH do Homebrew..."
            {
                echo ''
                echo '# Homebrew'
                echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
            } >> ~/.bashrc
        fi
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true
    fi

    if cmd_exists brew; then
        ok "Homebrew instalado com sucesso!"
    else
        warn "Homebrew pode precisar de reload do terminal. Execute: source ~/.bashrc"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  NAVEGADOR PADRAO — VIVALDI
# ══════════════════════════════════════════════════════════════════════════════
setup_vivaldi() {
    header "NAVEGADOR — VIVALDI"

    if cmd_exists vivaldi-stable || cmd_exists vivaldi || deb_installed vivaldi-stable; then
        skip "Vivaldi ja esta instalado"
        return
    fi

    info "Instalando Vivaldi via repositorio oficial..."
    wget -qO- https://repo.vivaldi.com/archive/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/vivaldi-browser.gpg 2>/dev/null || true
    echo "deb [signed-by=/usr/share/keyrings/vivaldi-browser.gpg arch=$(dpkg --print-architecture)] https://repo.vivaldi.com/archive/deb/ stable main" | sudo tee /etc/apt/sources.list.d/vivaldi.list > /dev/null
    sudo apt-get update -y 2>&1 | tail -3

    if apt_available vivaldi-stable; then
        apt_install vivaldi-stable
    else
        err "Vivaldi nao disponivel apos adicionar repositorio. Instale manualmente em https://vivaldi.com/download/"
        ((COUNT_FAILED++)) || true
        return
    fi

    if cmd_exists xdg-settings && (cmd_exists vivaldi-stable || cmd_exists vivaldi); then
        local vivaldi_cmd="vivaldi-stable.desktop"
        [[ -f /usr/share/applications/vivaldi.desktop ]] && vivaldi_cmd="vivaldi.desktop"
        xdg-settings set default-web-browser "$vivaldi_cmd" 2>/dev/null && \
            ok "Vivaldi definido como navegador padrao" || \
            warn "Nao foi possivel definir Vivaldi como padrao automaticamente (faça via Configuracoes)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  EMAIL — EVOLUTION
# ══════════════════════════════════════════════════════════════════════════════
setup_evolution() {
    header "EMAIL — EVOLUTION"

    if cmd_exists evolution || deb_installed evolution; then
        skip "Evolution ja instalado (nativo)"
        return
    fi

    if apt_available evolution; then
        apt_install evolution evolution-ews
    else
        flatpak_install org.gnome.Evolution "Evolution Mail"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  COMPARTILHAMENTO LOCAL — LOCALSEND
# ══════════════════════════════════════════════════════════════════════════════
setup_localsend() {
    header "COMPARTILHAMENTO LOCAL — LOCALSEND"

    if flatpak_installed org.localsend.localsend_app || cmd_exists localsend; then
        skip "LocalSend ja instalado"
        return
    fi

    flatpak_install org.localsend.localsend_app "LocalSend"
}

# ══════════════════════════════════════════════════════════════════════════════
#  NOTAS — OBSIDIAN
# ══════════════════════════════════════════════════════════════════════════════
setup_obsidian() {
    header "NOTAS — OBSIDIAN"

    if flatpak_installed md.obsidian.Obsidian || cmd_exists obsidian; then
        skip "Obsidian ja instalado"
        return
    fi

    flatpak_install md.obsidian.Obsidian "Obsidian"
}

# ══════════════════════════════════════════════════════════════════════════════
#  DEV TOOLCHAIN — CLI
# ══════════════════════════════════════════════════════════════════════════════
setup_dev_toolchain() {
    header "DEV TOOLCHAIN (CLI)"

    section "Build essentials e compiladores"
    apt_install \
        build-essential gcc g++ make cmake \
        autoconf automake libtool

    section "Version control"
    apt_install \
        git git-lfs subversion \
        patch colordiff

    section "Linguagens e runtimes"
    apt_install python3 python3-venv python3-dev

    if ! cmd_exists pip3; then
        python3 -m ensurepip --upgrade 2>/dev/null || true
    fi

    if ! cmd_exists node; then
        info "Instalando Node.js LTS via nodesource..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - 2>&1 | tail -3
        apt_install nodejs
    else
        skip "Node.js ja instalado"
    fi

    if ! cmd_exists java; then
        apt_install default-jdk
    else
        skip "Java ja instalado"
    fi

    if ! cmd_exists go; then
        apt_install_silent golang-go
    else
        skip "Go ja instalado"
    fi

    if ! cmd_exists rustc; then
        info "Instalando Rust via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 2>&1 | tee -a "$LOG_FILE" | tail -5
        if [[ -f "$HOME/.cargo/env" ]]; then
            source "$HOME/.cargo/env"
            ok "Rust instalado via rustup"
        fi
    else
        skip "Rust ja instalado"
    fi

    apt_install_silent ruby ruby-dev

    section "Dev utilities CLI"
    apt_install \
        jq yq \
        curl wget \
        ssh rsync \
        tmux screen \
        strace ltrace \
        net-tools dnsutils iputils-ping \
        sqlite3 \
        vim neovim \
        shellcheck \
        cloc \
        tree \
        ncdu

    apt_install_silent postgresql-client
    apt_install_silent mariadb-client
    apt_install_silent redis-tools

    if cmd_exists git-lfs; then
        git lfs install 2>/dev/null || true
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  DEV GUI APPS (Flatpak)
# ══════════════════════════════════════════════════════════════════════════════
setup_dev_gui() {
    header "DEV GUI APPS"

    section "Editores de codigo"
    flatpak_install com.vscodium.codium "VSCodium"

    section "IDEs especializadas"
    flatpak_install com.jetbrains.IntelliJ-IDEA-Community "IntelliJ IDEA Community"
    flatpak_install com.jetbrains.PyCharm-Community "PyCharm Community"

    section "Containers e DevOps"
    if ! cmd_exists docker; then
        apt_install docker.io
        if id -nG "$USER" | grep -qv docker; then
            sudo usermod -aG docker "$USER" 2>/dev/null || true
            warn "Voce precisa fazer logout/login para usar docker sem sudo"
        fi
    else
        skip "Docker ja instalado"
    fi

    apt_install_silent docker-compose-v2
    flatpak_install io.podman_desktop.PodmanDesktop "Podman Desktop"

    section "Database GUI"
    flatpak_install io.dbeaver.DBeaverCommunity "DBeaver Community"
}

# ══════════════════════════════════════════════════════════════════════════════
#  BACKUP
# ══════════════════════════════════════════════════════════════════════════════
setup_backup() {
    header "BACKUP"

    if cmd_exists timeshift || deb_installed timeshift; then
        skip "Timeshift ja instalado (nativo)"
    elif apt_available timeshift; then
        apt_install timeshift
    else
        warn "Timeshift nao disponivel nos repositorios"
    fi

    flatpak_install org.gnome.DejaDup "Deja Dup (Backup pessoal)"

    if ! cmd_exists borg; then
        apt_install_silent borgbackup
    else
        skip "BorgBackup ja instalado"
    fi

    if ! cmd_exists restic; then
        brew_install restic "Restic"
    else
        skip "Restic ja instalado"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  PLAYER DE MUSICA
# ══════════════════════════════════════════════════════════════════════════════
setup_music() {
    header "MUSICA"

    flatpak_install org.strawberrymusicplayer.strawberry "Strawberry"

    if ! cmd_exists audacious; then
        apt_install_silent audacious
    else
        skip "Audacious ja instalado"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  DAWs — PRODUCAO MUSICAL
# ══════════════════════════════════════════════════════════════════════════════
setup_daws() {
    header "PRODUCAO MUSICAL E AUDIO"

    flatpak_install io.lmms.LMMS "LMMS"
    flatpak_install org.ardour.Ardour "Ardour"
    flatpak_install org.audacityteam.Audacity "Audacity"
    flatpak_install org.musescore.MuseScore "MuseScore"

    section "Infraestrutura de audio profissional"
    apt_install pipewire-pulse
}

# ══════════════════════════════════════════════════════════════════════════════
#  SOFTWARE CRIATIVO
# ══════════════════════════════════════════════════════════════════════════════
setup_creative() {
    header "SOFTWARE CRIATIVO"

    section "Edicao de imagem"
    flatpak_install org.gimp.GIMP "GIMP"
    flatpak_install org.kde.krita "Krita"
    flatpak_install com.github.PintaProject.Pinta "Pinta"

    section "Design vetorial"
    flatpak_install org.inkscape.Inkscape "Inkscape"

    section "Fotografia e RAW"
    flatpak_install org.darktable.Darktable "Darktable"
    flatpak_install com.rawtherapee.RawTherapee "RawTherapee"

    section "3D e Modelagem"
    flatpak_install org.blender.Blender "Blender"

    section "Edicao de video"
    flatpak_install org.kde.kdenlive "Kdenlive"
    flatpak_install org.shotcut.Shotcut "Shotcut"

    section "Animacao"
    flatpak_install_if_available io.github.opentoonz.OpenToonz "OpenToonz"
    flatpak_install_if_available org.pencil2d.Pencil2D "Pencil2D"
    flatpak_install_if_available org.synfig.SynfigStudio "Synfig Studio"
}

# ══════════════════════════════════════════════════════════════════════════════
#  UTILITARIOS
# ══════════════════════════════════════════════════════════════════════════════
setup_utilities() {
    header "UTILITARIOS"
    section "Captura de tela"
    flatpak_install org.flameshot.Flameshot "Flameshot"

    section "Gravacao de tela"
    flatpak_install com.obsproject.Studio "OBS Studio"

    section "Gestor de senhas"
    flatpak_install org.keepassxc.KeePassXC "KeePassXC"
    flatpak_install com.bitwarden.desktop "Bitwarden"

    section "Mensagens unificadas"
    flatpak_install org.ferdium.Ferdium "Ferdium"

    section "Torrent"
    flatpak_install com.transmissionbt.Transmission "Transmission"

    section "Analise de disco"
    flatpak_install org.gnome.baobab "Baobab"

    section "Seletor de cores"
    flatpak_install_if_available nl.hjdskes.gcolor3 "Gcolor3"
    if ! flatpak_installed nl.hjdskes.gcolor3 2>/dev/null; then
        apt_install_silent gpick
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  TERMINAL
# ══════════════════════════════════════════════════════════════════════════════
setup_terminal() {
    header "TERMINAL"

    section "Ferramentas CLI (apt)"

    if cmd_exists batcat || cmd_exists bat; then
        skip "bat ja instalado"
    else
        apt_install_silent bat
    fi

    if ! cmd_exists fd && ! cmd_exists fdfind; then
        apt_install_silent fd-find
    else
        skip "fd ja instalado"
    fi

    if ! cmd_exists rg; then
        apt_install ripgrep
    else
        skip "ripgrep ja instalado"
    fi

    if ! cmd_exists htop; then
        apt_install htop
    else
        skip "htop ja instalado"
    fi

    if ! cmd_exists fzf; then
        apt_install fzf
    else
        skip "fzf ja instalado"
    fi

    if ! cmd_exists tldr; then
        apt_install_silent tldr
    else
        skip "tldr ja instalado"
    fi

    if ! cmd_exists zoxide; then
        apt_install_silent zoxide
    fi

    if ! cmd_exists duf; then
        apt_install_silent duf
    fi

    section "Ferramentas CLI (Brew)"

    if cmd_exists brew; then
        brew_install eza "eza"
        brew_install git-delta "git-delta"
        if ! cmd_exists zoxide; then
            brew_install zoxide "zoxide"
        fi
        brew_install starship "Starship"
        brew_install fnm "fnm"
        brew_install lazygit "lazygit"
        if cmd_exists docker; then
            brew_install lazydocker "lazydocker"
        fi
        brew_install bottom "bottom"
        brew_install atuin "atuin"
        brew_install btop "btop"
        brew_install dust "dust"
        brew_install procs "procs"
        brew_install tokei "tokei"
        brew_install hyperfine "hyperfine"
    else
        warn "Brew nao disponivel, ferramentas avancadas nao serao instaladas"
    fi

    section "Configurando Starship Prompt"
    if cmd_exists starship; then
        if [[ ! -f ~/.config/starship.toml ]]; then
            mkdir -p ~/.config
            cat > ~/.config/starship.toml << 'STARSHIP'
format = """
[](#9A3483)\
 $os\
 $username\
[](bg:#DA627D fg:#9A3483)\
 $directory\
[](fg:#DA627D bg:#FCA17D)\
 $git_branch\
 $git_status\
[](fg:#FCA17D bg:#86BBD8)\
 $c\
 $rust\
 $golang\
 $nodejs\
 $python\
 $java\
[](fg:#86BBD8 bg:#06969A)\
 $docker_context\
[](fg:#06969A bg:#33658A)\
 $time\
[](fg:#33658A)\
 $line_break\
 $character"""

[os]
disabled = false
style = "bg:#9A3483 fg:#FFFFFF"

[os.symbols]
Ubuntu = " "
Linux = " "
Macos = " "
Windows = " "

[username]
show_always = true
style_user = "bg:#9A3483 fg:#FFFFFF bold"
style_root = "bg:#9A3483 fg:#FF0000 bold"
format = "[$user ]($style)"

[directory]
style = "bg:#DA627D fg:#FFFFFF bold"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = ".../"

[directory.substitutions]
"Documents" = "󰈙 "
"Downloads" = " "
"Music" = " "
"Pictures" = " "

[git_branch]
symbol = ""
style = "bg:#FCA17D fg:#000000"
format = "[ $symbol $branch ]($style)"

[git_status]
style = "bg:#FCA17D fg:#000000"
format = "[$all_status$ahead_behind ]($style)"

[c]
symbol = " "
style = "bg:#86BBD8 fg:#000000"
format = "[ $symbol ($version) ]($style)"

[rust]
symbol = ""
style = "bg:#86BBD8 fg:#000000"
format = "[ $symbol ($version) ]($style)"

[golang]
symbol = ""
style = "bg:#86BBD8 fg:#000000"
format = "[ $symbol ($version) ]($style)"

[nodejs]
symbol = ""
style = "bg:#86BBD8 fg:#000000"
format = "[ $symbol ($version) ]($style)"

[python]
symbol = ""
style = "bg:#86BBD8 fg:#000000"
format = "[ $symbol ($version) ]($style)"

[java]
symbol = " "
style = "bg:#86BBD8 fg:#000000"
format = "[ $symbol ($version) ]($style)"

[docker_context]
symbol = ""
style = "bg:#06969A fg:#FFFFFF"
format = "[ $symbol $context ]($style)"

[time]
disabled = false
time_format = "%R"
style = "bg:#33658A fg:#FFFFFF"
format = "[ 󰥔 $time ]($style)"

[line_break]
disabled = false

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
STARSHIP
            ok "Starship configurado!"
        else
            skip "Starship config ja existe"
        fi
    else
        warn "Starship nao encontrado, tentando install via curl..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y 2>&1 | tee -a "$LOG_FILE" | tail -3 || true
    fi

    section "Customizando .bashrc"

    if [[ -f ~/.bashrc && ! -f ~/.bashrc.backup.linuxeco ]]; then
        cp ~/.bashrc ~/.bashrc.backup.linuxeco
        ok "Backup do .bashrc criado em ~/.bashrc.backup.linuxeco"
    fi

    if grep -q "# Linuxeco" ~/.bashrc 2>/dev/null; then
        skip ".bashrc ja foi customizado"
    else
        info "Adicionando customizacoes ao .bashrc..."
        cat >> ~/.bashrc << 'BASHRC_CUSTOM'

# Linuxeco Terminal Customizations

# Cargo (Rust)
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi

# Homebrew
if [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Starship Prompt
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi

# fzf
if [[ -f /usr/share/doc/fzf/examples/key-bindings.bash ]]; then
    source /usr/share/doc/fzf/examples/key-bindings.bash
fi
if [[ -f /usr/share/doc/fzf/examples/completion.bash ]]; then
    source /usr/share/doc/fzf/examples/completion.bash
fi

# Zoxide
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi

# Atuin
if command -v atuin &>/dev/null; then
    eval "$(atuin init bash)"
fi

# fnm
if command -v fnm &>/dev/null; then
    eval "$(fnm env --use-on-cd
)"
fi

# Aliases modernos

# ls -> eza
if command -v eza &>/dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first --git'
    alias la='eza -la --icons --group-directories-first --git'
    alias lt='eza -T --icons --level=2'
    alias l='eza -lah --icons --group-directories-first --git'
else
    alias ll='ls -alF --color=auto'
    alias la='ls -A --color=auto'
    alias l='ls -CF --color=auto'
fi

# cat -> bat
if command -v batcat &>/dev/null; then
    alias cat='batcat --style=auto --paging=never'
    export BAT_THEME="TwoDark"
elif command -v bat &>/dev/null; then
    alias cat='bat --style=auto --paging=never'
    export BAT_THEME="TwoDark"
fi

# find -> fd
if command -v fdfind &>/dev/null; then
    alias fd='fdfind'
    alias find='fdfind'
elif command -v fd &>/dev/null; then
    alias find='fd'
fi

# grep -> ripgrep
if command -v rg &>/dev/null; then
    alias grep='rg'
fi

# df -> duf
if command -v duf &>/dev/null; then
    alias df='duf'
fi

# top -> btop/btm/htop
if command -v btop &>/dev/null; then
    alias top='btop'
elif command -v btm &>/dev/null; then
    alias top='btm'
elif command -v htop &>/dev/null; then
    alias top='htop'
fi

# Git aliases
alias gs='git status'
alias gl='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gds='git diff --staged'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit'
alias gp='git push'
alias gpl='git pull'
alias gb='git branch'
alias gco='git checkout'
alias gsw='git switch'
alias gcl='git clone'
alias gt='git tag'

# Lazy tools
if command -v lazygit &>/dev/null; then
    alias lg='lazygit'
fi
if command -v lazydocker &>/dev/null; then
    alias ld='lazydocker'
fi

# Dev aliases
alias python='python3'
alias pip='pip3'
alias v='nvim'
alias vim='nvim'
alias :q='exit'

# Navegacao rapida
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# System aliases
alias ports='ss -tulanp'
alias flush='sudo iptables -F'
alias path='echo -e ${PATH//:/\\n}'

# Funcoes uteis

mkcd() { mkdir -p "$1" && cd "$1"; }

extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *.deb)       ar x "$1"        ;;
            *)           echo "Nao sei extrair '$1'..." ;;
        esac
    else
        echo "'$1' nao e um arquivo valido!"
    fi
}

weather() { curl -s "wttr.in/${1:-Sao Paulo}?lang=pt"; }
myip() { curl -s ifconfig.me && echo; }
ghclone() { git clone "https://github.com/$1.git"; }
serve() { python3 -m http.server "${1:-8000}"; }
docker-clean() { sudo docker system prune -af --volumes; }

git-nuke() {
    git fetch origin
    git reset --hard "origin/$(git branch --show-current)"
    git clean -fd
}

# Variaveis de ambiente
export EDITOR="nvim"
export VISUAL="nvim"
if command -v vivaldi-stable &>/dev/null; then
    export BROWSER="vivaldi-stable"
elif command -v vivaldi &>/dev/null; then
    export BROWSER="vivaldi"
else
    export BROWSER="xdg-open"
fi
export PAGER="less -R"

# Historia melhorada
export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"

# Cores no less
export LESS="-R"
BASHRC_CUSTOM
        ok ".bashrc customizado!"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  FASTFETCH
# ══════════════════════════════════════════════════════════════════════════════
setup_fastfetch() {
    header "FASTFETCH"

    if ! cmd_exists fastfetch; then
        if apt_available fastfetch 2>/dev/null; then
            apt_install fastfetch
        elif cmd_exists brew; then
            brew_install fastfetch "Fastfetch"
        else
            warn "Fastfetch nao disponivel, instale manualmente"
            return
        fi
    else
        skip "Fastfetch ja instalado"
    fi

    if cmd_exists fastfetch && [[ ! -f ~/.config/fastfetch/config.jsonc ]]; then
        mkdir -p ~/.config/fastfetch
        cat > ~/.config/fastfetch/config.jsonc << 'FASTFETCH'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "type": "auto"
    },
    "display": {
        "separator": "  "
    },
    "modules": [
        "title",
        "separator",
        {
            "type": "os",
            "key": "│ OS"
        },
        {
            "type": "kernel",
            "key": "│ Kernel"
        },
        {
            "type": "packages",
            "key": "│ Packages"
        },
        {
            "type": "shell",
            "key": "│ Shell"
        },
        {
            "type": "de",
            "key": "│ DE"
        },
        {
            "type": "wm",
            "key": "│ WM"
        },
        {
            "type": "terminal",
            "key": "│ Terminal"
        },
        {
            "type": "cpu",
            "key": "│ CPU"
        },
        {
            "type": "gpu",
            "key": "│ GPU"
        },
        {
            "type": "memory",
            "key": "│ Memory"
        },
        {
            "type": "disk",
            "key": "│ Disk"
        },
        {
            "type": "uptime",
            "key": "│ Uptime"
        },
        "break",
        {
            "type": "colors",
            "symbol": "circle"
        }
    ]
}
FASTFETCH
        ok "Fastfetch configurado!"

        if ! grep -q "fastfetch" ~/.bashrc 2>/dev/null; then
            echo '' >> ~/.bashrc
            echo '# Fastfetch on terminal open' >> ~/.bashrc
            echo 'if command -v fastfetch &>/dev/null && [[ $- == *i* ]]; then fastfetch; fi' >> ~/.bashrc
        fi
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  FONTS
# ══════════════════════════════════════════════════════════════════════════════
setup_fonts() {
    header "FONTES NERD"

    local fonts_dir="$HOME/.local/share/fonts"
    mkdir -p "$fonts_dir"

    install_nerd_font() {
        local font_name="$1"
        local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font_name}.zip"
        local target_dir="$fonts_dir/${font_name}"

        if [[ -d "$target_dir" ]] && compgen -G "${target_dir}/*.ttf" &>/dev/null; then
            skip "${font_name} Nerd Font ja instalada"
            return 0
        fi

        info "Instalando ${font_name} Nerd Font..."
        local tmp_dir
        tmp_dir=$(mktemp -d)

        if wget -q --show-progress -O "${tmp_dir}/${font_name}.zip" "$url" 2>&1 | tee -a "$LOG_FILE"; then
            mkdir -p "$target_dir"
            if unzip -qo "${tmp_dir}/${font_name}.zip" -d "$target_dir" 2>/dev/null; then
                ok "${font_name} Nerd Font instalada"
            else
                warn "Falha ao extrair ${font_name} Nerd Font"
            fi
        else
            warn "Falha ao baixar ${font_name} Nerd Font"
        fi
        rm -rf "$tmp_dir"
    }

    install_nerd_font "FiraCode"
    install_nerd_font "JetBrainsMono"
    install_nerd_font "Hack"

    if command -v fc-cache &>/dev/null; then
        fc-cache -f "$fonts_dir" 2>/dev/null
        ok "Font cache atualizado"
    fi

    info "Para usar as Nerd Fonts, configure seu terminal em:"
    info "  GNOME Terminal: Preferencias -> Perfis -> Texto -> Fonte personalizada"
    info "  Tilix: Preferencias -> Perfis -> Geral -> Fonte personalizada"
    info "  Konsole: Configuracoes -> Aparencia -> Fonte"
}

# ══════════════════════════════════════════════════════════════════════════════
#  GIT CONFIG
# ══════════════════════════════════════════════════════════════════════════════
setup_git_config() {
    header "GIT CONFIG"

    if [[ -z "$(git config --global user.name 2>/dev/null)" ]]; then
        read -rp "Seu nome para o Git (Enter para pular): " git_name
        if [[ -n "$git_name" ]]; then
            git config --global user.name "$git_name"
            ok "Git user.name configurado"
        fi
    else
        skip "Git user.name ja configurado: $(git config --global user.name)"
    fi

    if [[ -z "$(git config --global user.email 2>/dev/null)" ]]; then
        read -rp "Seu email para o Git (Enter para pular): " git_email
        if [[ -n "$git_email" ]]; then
            git config --global user.email "$git_email"
            ok "Git user.email configurado"
        fi
    else
        skip "Git user.email ja configurado: $(git config --global user.email)"
    fi

    git config --global core.autocrlf input 2>/dev/null || true
    git config --global init.defaultBranch main 2>/dev/null || true
    git config --global pull.rebase false 2>/dev/null || true
    git config --global core.editor "nvim" 2>/dev/null || true

    if cmd_exists delta; then
        git config --global core.pager "delta" 2>/dev/null || true
        git config --global interactive.diffFilter "delta --color-only" 2>/dev/null || true
        git config --global delta.navigate true 2>/dev/null || true
        git config --global delta.side-by-side true 2>/dev/null || true
        git config --global merge.conflictstyle diff3 2>/dev/null || true
        ok "Git delta pager configurado"
    fi

    ok "Git configurado"
}

# ══════════════════════════════════════════════════════════════════════════════
#  RESUMO
# ══════════════════════════════════════════════════════════════════════════════
show_summary() {
    header "RESUMO DA INSTALACAO"

    echo ""
    log "${BOLD}${GREEN}  Instalados:  ${COUNT_INSTALLED}${NC}"
    log "${BOLD}${YELLOW}  Skippados:   ${COUNT_SKIPPED}${NC}"
    log "${BOLD}${RED}  Falhas:      ${COUNT_FAILED}${NC}"
    echo ""
    log "  Log completo: ${CYAN}${LOG_FILE}${NC}"
    echo ""

    if [[ "$COUNT_FAILED" -gt 0 ]]; then
        warn "Algumas instalacoes falharam. Verifique o log para detalhes."
    fi

    log "${BOLD}Para aplicar as mudancas no terminal:${NC}"
    log "    ${CYAN}source ~/.bashrc${NC}"
    log "    Ou simplesmente feche e abra o terminal novamente"
    echo ""

    log "${BOLD}Apps instalados por categoria:${NC}"
    echo ""
    log "  Navegador     Vivaldi"
    log "  Email         Evolution"
    log "  Compartilhar  LocalSend"
    log "  Notas         Obsidian"
    log "  Backup        Timeshift + Deja Dup + BorgBackup"
    log "  Musica        Strawberry + Audacious"
    log "  DAWs          LMMS + Ardour + Audacity + MuseScore"
    log "  Imagem        GIMP + Krita + Inkscape + Pinta"
    log "  Foto/RAW      Darktable + RawTherapee"
    log "  Video         Kdenlive + Shotcut"
    log "  3D            Blender"
    log "  Animacao      (verifique disponibilidade no Flathub)"
    log "  Office        LibreOffice"
    log "  Senhas        KeePassXC + Bitwarden"
    log "  Cloud         Nextcloud"
    log "  Streaming     OBS Studio"
    log "  Mensagens     Ferdium"
    log "  Dev IDE       VSCodium + IntelliJ + PyCharm"
    log "  Containers    Docker + Podman Desktop"
    log "  Database GUI  DBeaver"
    log "  Homebrew      Linuxbrew"
    log "  Terminal      Starship + eza + bat + fzf + zoxide"
    log "  Fontes        FiraCode + JetBrainsMono + Hack (Nerd Fonts)"
    echo ""

    log "${BOLD}${CYAN}Bem-vindo ao Linuxeco!${NC}"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
#  MAIN
# ══════════════════════════════════════════════════════════════════════════════
main() {
    clear

    echo -e "${BOLD}${MAGENTA}"
    cat << 'BANNER'
    Linuxeco — Ecosystem Installer for Creators

    ZorinOS 18+ · Mint 22.x · Ubuntu 24.04+
    FOSS-first · Flatpak GUI · apt CLI · Homebrew
BANNER
    echo -e "${NC}"

    if [[ "$(uname -s)" != "Linux" ]]; then
        err "Este script e para Linux apenas!"
        exit 1
    fi

    if ! ping -c 1 -W 3 archive.ubuntu.com &>/dev/null; then
        if ! ping -c 1 -W 3 google.com &>/dev/null; then
            err "Sem conexao com internet detectada!"
            exit 1
        fi
    fi

    if ! sudo -v 2>/dev/null; then
        err "Este script precisa de sudo para instalacoes de sistema."
        exit 1
    fi

    detect_distro

    echo ""
    log "${BOLD}Este script vai instalar:${NC}"
    log "  Vivaldi (navegador padrao, .deb)"
    log "  Evolution (email), LocalSend (compartilhamento), Obsidian (notas)"
    log "  Dev toolchain completa"
    log "  DAWs: LMMS, Ardour, Audacity, MuseScore"
    log "  Software criativo: GIMP, Krita, Inkscape, Blender, Kdenlive..."
    log "  Homebrew (Linuxbrew)"
    log "  Terminal customizado (Starship, eza, bat, fzf, zoxide...)"
    log "  Nerd Fonts (FiraCode, JetBrainsMono, Hack)"
    log "  E muito mais..."
    echo ""

    read -rp "Deseja continuar? [s/N] " confirm
    [[ "${confirm,,}" != "s" ]] && { info "Instalacao cancelada."; exit 0; }

    echo ""
    log "${BOLD}Escolha o modo de instalacao:${NC}"
    log "  1) Completo (instala tudo)"
    log "  2) Seletivo (escolha as categorias)"
    log "  3) Apenas terminal (customizacao do terminal + ferramentas CLI)"
    echo ""
    read -rp "Modo [1/2/3]: " mode

    case "$mode" in
        1)
            INSTALL_DEV=true
            INSTALL_CREATIVE=true
            INSTALL_DAW=true
            INSTALL_MUSIC=true
            INSTALL_UTILITIES=true
            INSTALL_TERMINAL=true
            ;;
        2)
            echo ""
            read -rp "Instalar Dev Toolchain + GUI? [s/N]: " r; [[ "${r,,}" == "s" ]] && INSTALL_DEV=true || INSTALL_DEV=false
            read -rp "Instalar Software Criativo? [s/N]: " r; [[ "${r,,}" == "s" ]] && INSTALL_CREATIVE=true || INSTALL_CREATIVE=false
            read -rp "Instalar DAWs e Audio? [s/N]: " r; [[ "${r,,}" == "s" ]] && INSTALL_DAW=true || INSTALL_DAW=false
            read -rp "Instalar Player de Musica? [s/N]: " r; [[ "${r,,}" == "s" ]] && INSTALL_MUSIC=true || INSTALL_MUSIC=false
            read -rp "Instalar Utilitarios? [s/N]: " r; [[ "${r,,}" == "s" ]] && INSTALL_UTILITIES=true || INSTALL_UTILITIES=false
            read -rp "Instalar Customizacao Terminal? [s/N]: " r; [[ "${r,,}" == "s" ]] && INSTALL_TERMINAL=true || INSTALL_TERMINAL=false
            ;;
        3)
            INSTALL_DEV=false
            INSTALL_CREATIVE=false
            INSTALL_DAW=false
            INSTALL_MUSIC=false
            INSTALL_UTILITIES=false
            INSTALL_TERMINAL=true
            ;;
        *)
            INSTALL_DEV=true
            INSTALL_CREATIVE=true
            INSTALL_DAW=true
            INSTALL_MUSIC=true
            INSTALL_UTILITIES=true
            INSTALL_TERMINAL=true
            ;;
    esac

    setup_prerequisites
    setup_homebrew

    setup_vivaldi
    setup_evolution
    setup_localsend
    setup_obsidian
    setup_backup

    if ${INSTALL_DEV:-false}; then
        setup_dev_toolchain
        setup_dev_gui
    fi

    if ${INSTALL_CREATIVE:-false}; then
        setup_creative
    fi

    if ${INSTALL_DAW:-false}; then
        setup_daws
    fi

    if ${INSTALL_MUSIC:-false}; then
        setup_music
    fi

    if ${INSTALL_UTILITIES:-false}; then
        setup_utilities
    fi

    show_summary

    info "Executando limpeza de pacotes..."
    sudo apt-get autoremove -y 2>&1 | tee -a "$LOG_FILE" | tail -3
    sudo apt-get autoclean -y 2>&1 | tee -a "$LOG_FILE" | tail -3
    flatpak cache --delete 2>/dev/null || true
    ok "Limpeza concluida!"

    echo ""
    warn "IMPORTANTE: Faca logout/login ou abra um novo terminal para que"
    warn "todas as configuracoes tenham efeito (PATH do brew, aliases, etc.)"
    echo ""
}

main "$@"



