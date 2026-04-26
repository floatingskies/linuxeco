# 🐧 Linuxeco — Ecosystem Installer for Creators

> Instala um ecossistema Linux completo para criativos, desenvolvedores e quem quer o melhor software. FOSS-first, Flatpak para GUI, `apt` para CLI.

**Suporte:** ZorinOS 18+ · Linux Mint 22.x · Ubuntu 24.04+ (e derivados)

---

## O que é o Linuxeco?

O **Linuxeco** é um script bash interativo que transforma uma instalação limpa de Linux em um ambiente completo e produtivo com um único comando. Ele instala, configura e personaliza centenas de ferramentas — do terminal ao software criativo — tomando decisões inteligentes sobre o que já está instalado, o que está disponível e como instalar cada coisa da melhor forma.

Filosofia do projeto:
- **FOSS sempre que possível** — sem software proprietário desnecessário
- **Flatpak para apps GUI** — versões atualizadas, isoladas e seguras
- **`apt` para ferramentas CLI** — integração nativa com o sistema
- **Homebrew para o que falta** — ferramentas modernas não disponíveis no `apt`
- **Idempotente** — pode rodar várias vezes sem quebrar nada

---

## Como usar

```bash
# 1. Baixe o script
wget https://github.com/floatingskies/linuxeco/linuxeco.sh

# 2. Dê permissão de execução
chmod +x linuxeco.sh

# 3. Execute
./linuxeco.sh
```

O script vai perguntar seu modo de instalação preferido:

| Modo | O que faz |
|------|-----------|
| `1` Completo | Instala absolutamente tudo |
| `2` Seletivo | Você escolhe categoria por categoria |
| `3` Apenas Terminal | Só as ferramentas de terminal e CLI |

---

## O que é instalado

### 🌐 Navegador & Comunicação
| App | Método | Descrição |
|-----|--------|-----------|
| **Vivaldi** | `.deb` (repositório oficial) | Navegador padrão, rico em recursos |
| **Evolution** | `apt` / Flatpak | Cliente de email completo com suporte a Exchange |
| **LocalSend** | Flatpak | Compartilhamento de arquivos na rede local (como AirDrop) |
| **Ferdium** | Flatpak | Todos os seus mensageiros em um só lugar |

### 📝 Produtividade & Notas
| App | Método | Descrição |
|-----|--------|-----------|
| **Obsidian** | Flatpak | Notas em Markdown com links bidirecionais |

### 💻 Dev Toolchain (CLI)
Linguagens e runtimes instalados:
- **Python 3** (com `venv` e `pip`)
- **Node.js LTS** (via nodesource)
- **Java** (JDK padrão)
- **Go**
- **Rust** (via `rustup`)
- **Ruby**

Utilitários CLI essenciais:
```
git · git-lfs · jq · yq · curl · wget · ssh · rsync
tmux · screen · vim · neovim · sqlite3 · shellcheck
cloc · tree · ncdu · strace · net-tools · dnsutils
```

Clientes de banco de dados:
```
postgresql-client · mariadb-client · redis-tools
```

### 🖥️ Dev GUI (Flatpak)
| App | Descrição |
|-----|-----------|
| **VSCodium** | VS Code sem telemetria da Microsoft |
| **IntelliJ IDEA Community** | IDE para Java/Kotlin |
| **PyCharm Community** | IDE para Python |
| **DBeaver Community** | GUI universal para bancos de dados |
| **Podman Desktop** | Gestão de containers sem Docker daemon |

Containers:
- **Docker** (`apt`) com seu usuário adicionado ao grupo `docker`
- **docker-compose** (plugin v2)

### 🎨 Software Criativo (Flatpak)
| Categoria | Apps |
|-----------|------|
| Edição de imagem | GIMP · Krita · Pinta |
| Design vetorial | Inkscape |
| Fotografia / RAW | Darktable · RawTherapee |
| 3D e Modelagem | Blender |
| Edição de vídeo | Kdenlive · Shotcut |
| Animação | OpenToonz · Pencil2D · Synfig Studio |

### 🎵 Áudio & Música (Flatpak)
| App | Descrição |
|-----|-----------|
| **LMMS** | DAW completa para produção musical |
| **Ardour** | DAW profissional (gravação, mixagem, mastering) |
| **Audacity** | Edição de áudio simples e poderosa |
| **MuseScore** | Notação musical |
| **Strawberry** | Player de música com foco em qualidade de áudio |
| **Audacious** | Player leve e rápido |

Infraestrutura: `pipewire-pulse` para áudio profissional de baixa latência.

### 🛡️ Backup
| App | Descrição |
|-----|-----------|
| **Timeshift** | Snapshots do sistema (como o Time Machine do macOS) |
| **Deja Dup** | Backup pessoal simples com suporte a cloud |
| **BorgBackup** | Backup incremental e deduplicado (CLI) |
| **Restic** | Backup moderno e criptografado (via Homebrew) |

### 🔧 Utilitários (Flatpak)
| App | Descrição |
|-----|-----------|
| **Flameshot** | Captura de tela avançada com anotações |
| **OBS Studio** | Gravação e streaming de tela |
| **KeePassXC** | Gerenciador de senhas local |
| **Bitwarden** | Gerenciador de senhas com sincronização cloud |
| **Transmission** | Cliente BitTorrent |
| **Baobab** | Análise visual de uso de disco |

---

## 🖥️ O Novo Terminal — Guia Completo

O Linuxeco transforma completamente sua experiência no terminal. Veja o que muda.

### Starship Prompt

O prompt padrão é substituído pelo **Starship**, um prompt bonito e informativo que mostra:
- 🐧 Usuário e SO
- 📁 Diretório atual (com ícones)
- 🌿 Branch e status do Git
- ⚙️ Versão da linguagem do projeto atual (Python, Node, Rust, Go, Java, C)
- 🐳 Contexto Docker
- 🕐 Hora atual

O prompt muda de cor verde para vermelho quando um comando falha.

---

### Aliases de Navegação

```bash
..          # cd ..
...         # cd ../..
....        # cd ../../..
-           # cd - (volta pro diretório anterior)
```

---

### Aliases de Listagem (`eza` substitui `ls`)

```bash
ls          # listagem com ícones, diretórios primeiro
ll          # listagem longa com ícones e status Git
la          # listagem longa com arquivos ocultos
lt          # árvore de diretórios (2 níveis)
l           # listagem completa com tudo
```

**Exemplo de saída do `ll`:**

```
drwxr-xr-x  📁 src/           main  ✓
-rw-r--r--  📄 README.md      main  ✓
-rw-r--r--  🐍 main.py        main  M  ← arquivo modificado no Git
```

---

### Aliases de Visualização (`bat` substitui `cat`)

```bash
cat arquivo.py      # exibe com syntax highlighting e numeração de linhas
```

O `bat` detecta automaticamente a linguagem e aplica highlight. Use `cat -p` para output sem decoração.

---

### Aliases de Busca

```bash
# fd (substitui find) — muito mais rápido e intuitivo
fd nome_arquivo             # busca por nome
fd -e py                    # busca por extensão .py
fd -t d pasta               # busca só diretórios

# rg (ripgrep, substitui grep) — busca dentro de arquivos
rg "palavra"                # busca recursiva no diretório atual
rg "função" --type py       # só em arquivos Python
rg -i "texto"               # case-insensitive
```

---

### Navegação com Zoxide (substitui `cd`)

O **zoxide** aprende seus diretórios mais usados e permite navegar com abreviações:

```bash
z projetos          # vai para ~/Documentos/Trabalho/projetos sem digitar o caminho completo
z down              # vai para ~/Downloads
zi                  # abre seletor interativo com fzf
```

Após usá-lo algumas vezes, você nunca mais vai digitar caminhos completos.

---

### FZF — Busca Interativa Fuzzy

O **fzf** habilita busca fuzzy em tudo. Atalhos no terminal:

| Atalho | Ação |
|--------|------|
| `Ctrl+R` | Busca no histórico de comandos (fuzzy) |
| `Ctrl+T` | Busca arquivos no diretório atual |
| `Alt+C` | Navega para subdiretório |

---

### Git Aliases

```bash
gs      # git status
gl      # git log --oneline --graph --decorate --all (visual)
gd      # git diff
gds     # git diff --staged
ga      # git add
gaa     # git add . (tudo)
gc      # git commit
gp      # git push
gpl     # git pull
gb      # git branch
gco     # git checkout
gsw     # git switch
gcl     # git clone
lg      # lazygit (interface visual para Git)
```

---

### Aliases de Sistema

```bash
df          # duf — visualização bonita do espaço em disco
top         # btop/htop — monitor de recursos visual
ports       # ss -tulanp — lista todas as portas em uso
path        # mostra o PATH linha por linha
```

---

### Ferramentas Modernas (via Homebrew)

| Ferramenta | O que faz |
|------------|-----------|
| `eza` | `ls` moderno com ícones e Git |
| `bat` | `cat` com syntax highlighting |
| `fd` | `find` mais rápido e amigável |
| `rg` (ripgrep) | `grep` ultrarrápido |
| `zoxide` | `cd` inteligente com aprendizado |
| `fzf` | Busca fuzzy interativa |
| `starship` | Prompt bonito e informativo |
| `lazygit` | Interface visual para Git no terminal |
| `lazydocker` | Interface visual para Docker |
| `btop` | Monitor de recursos visual e moderno |
| `bottom` (`btm`) | Monitor de sistema alternativo |
| `dust` | `du` visual — uso de disco por diretório |
| `procs` | `ps` moderno com busca |
| `tokei` | Conta linhas de código por linguagem |
| `hyperfine` | Benchmark de comandos |
| `atuin` | Histórico de shell sincronizado e pesquisável |
| `delta` | Diff bonito para Git |
| `fnm` | Gerenciador de versões do Node.js |

---

### Funções Utilitárias

```bash
# Cria diretório e entra nele
mkcd meu-projeto

# Extrai qualquer arquivo comprimido
extract arquivo.tar.gz
extract arquivo.zip
extract arquivo.7z
# (detecta o formato automaticamente)

# Verifica o tempo atual
weather                 # São Paulo (padrão)
weather "Curitiba"      # outra cidade

# Seu IP público
myip

# Clona repo do GitHub pela shorthand
ghclone usuario/repositorio

# Servidor HTTP local
serve                   # porta 8000
serve 3000              # porta customizada

# Docker: limpa tudo (containers, imagens, volumes)
docker-clean

# Git: reset hard para o estado do remote
git-nuke
```

---

### Variáveis de Ambiente Configuradas

```bash
EDITOR="nvim"           # editor padrão do sistema
VISUAL="nvim"           # editor visual
BROWSER="vivaldi-stable" # navegador padrão
PAGER="less -R"         # paginador com cores
HISTSIZE=100000          # histórico grande
BAT_THEME="TwoDark"     # tema do bat
```

---

## 🔤 Fontes Nerd

O Linuxeco instala as seguintes **Nerd Fonts** em `~/.local/share/fonts`:

| Fonte | Uso recomendado |
|-------|----------------|
| **FiraCode Nerd Font** | Coding com ligaduras |
| **JetBrainsMono Nerd Font** | IDEs e editores |
| **Hack Nerd Font** | Terminal geral |

### Como configurar no terminal

Após a instalação, configure a fonte no seu emulador de terminal:

- **GNOME Terminal:** Preferências → Perfis → Texto → Fonte personalizada
- **Tilix:** Preferências → Perfis → Geral → Fonte personalizada
- **Konsole:** Configurações → Aparência → Fonte
- **VSCode/VSCodium:** `"terminal.integrated.fontFamily": "JetBrainsMono Nerd Font"`

> ⚠️ Sem uma Nerd Font configurada no terminal, os ícones do Starship e do `eza` aparecerão como quadrados ou pontos de interrogação.

---

## 📊 Fastfetch

O **fastfetch** é executado automaticamente toda vez que você abre um novo terminal, exibindo informações do sistema:

```
user@hostname
─────────────
│ OS       ZorinOS 18
│ Kernel   6.5.0-generic
│ Shell    bash 5.2.21
│ DE       GNOME 45
│ CPU      Intel Core i7-12700
│ GPU      NVIDIA RTX 3060
│ Memory   8.2 GiB / 32 GiB
│ Disk     120 GiB / 512 GiB
│ Uptime   2 days, 4 hours
```

---

## ⚙️ Após a instalação

```bash
# Aplica todas as mudanças no terminal atual
source ~/.bashrc

# Ou simplesmente feche e abra o terminal
```

> ⚠️ **Importante:** Algumas mudanças (PATH do Homebrew, grupo `docker`) exigem **logout completo e login** para ter efeito total.

---

## 📁 Arquivos criados/modificados

| Arquivo | O que muda |
|---------|-----------|
| `~/.bashrc` | Aliases, funções, variáveis, integrações |
| `~/.bashrc.backup.linuxeco` | Backup do `.bashrc` original |
| `~/.config/starship.toml` | Configuração do prompt Starship |
| `~/.config/fastfetch/config.jsonc` | Layout do fastfetch |
| `~/.local/share/fonts/` | Nerd Fonts instaladas |
| `/tmp/linuxeco-install-*.log` | Log completo da instalação |

---

## 🐛 Solução de problemas

**Ícones aparecem como quadrados:**
→ Configure uma Nerd Font no seu emulador de terminal (veja seção acima).

**`brew` não encontrado após instalação:**
```bash
source ~/.bashrc
# ou
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

**`docker` requer `sudo`:**
→ Faça logout e login. O script adiciona seu usuário ao grupo `docker`, mas isso só tem efeito na próxima sessão.

**Verificar o log de instalação:**
```bash
cat /tmp/linuxeco-install-*.log | grep "❌"
```

**Reinstalar apenas uma categoria:**
O script é idempotente — pode rodar novamente. Apps já instalados são detectados e pulados automaticamente.

---

## 📄 Licença

FOSS. Modifique, distribua e use à vontade.

---

*Feito com 🐧 para quem leva o Linux a sério.*
