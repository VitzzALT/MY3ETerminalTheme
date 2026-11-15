# MY3E Powershell Theme

Tema **Material You (Material 3 Expressive)** para o **PowerShell 7**, com **Oh-My-Posh** e **Windows Terminal**.
Ele segue a **cor de destaque do Windows**, que no modo *Automático* vem do papel de parede, e usa a mesma paleta tonal do [MY3E Firefox Theme](https://github.com/VitzzALT/MY3EFirefoxTheme).

## O que vem nele

- Prompt em **pílulas arredondadas** (sistema, pasta, git, node/python, tempo de execução e código de erro), com seta que fica vermelha quando o comando falha
- **Cores dinâmicas**: trocou o papel de parede, o prompt acompanha na próxima vez que abrir o terminal
- Cores do **autocomplete** (PSReadLine) na mesma paleta
- Esquema de cores **"Material You"** para o Windows Terminal, criado como fragmento (não mexe no seu `settings.json`)
- **Abertura rápida**: Terminal-Icons e Chocolatey carregam só quando precisam, e nada é instalado ou varrido a cada abertura
- Funções do dia a dia: `uall` (atualiza tudo), `go`, `desk`/`docs`/`down`, `sysinfo`, `ff` (fastfetch), `helpme`

## Requisitos

- Windows 10/11 com **PowerShell 7** (`winget install Microsoft.PowerShell`)
- Uma **Nerd Font** no terminal (por exemplo `oh-my-posh font install`)
- Oh-My-Posh (o instalador cuida disso pelo winget)
- Windows Terminal (opcional, para o esquema de cores)

## Instalação

Baixe o repositório (Code → Download ZIP) ou clone, abra um terminal na pasta e rode:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Depois abra um terminal novo.
Se você já tinha um perfil, ele ganha um backup (`Microsoft.PowerShell_profile.ps1.bak-data-hora`) antes de ser substituído.

Opções:

| Opção | O que faz |
| --- | --- |
| `-SkipProfile` | instala o tema e a paleta, mas não mexe no seu perfil |
| `-Uninstall` | remove o tema e restaura o perfil anterior, se houver backup |

### Esquema de cores do Windows Terminal (opcional)

Windows Terminal → Configurações → Padrões → Aparência → Esquema de cores → **Material You**.
O fundo usa um tom escuro da sua cor de destaque; os efeitos de transparência e acrílico continuam como você configurou.

## Comandos

| Comando | O que faz |
| --- | --- |
| `mytheme` | recalcula o tema pela cor de destaque atual |
| `helpme` | lista os comandos do perfil |
| `uall` | atualiza Winget, Chocolatey, Scoop, módulos e Oh-My-Posh |
| `ff` | mostra o fastfetch (`$ShowFetch = $true` no perfil faz mostrar ao abrir) |
| `Get-OMPThemes`, `Set-OMPTheme` | lista e troca temas do Oh-My-Posh |

## Como funciona

1. `MaterialYou.ps1` lê a cor de destaque no registro do Windows.
2. Converte para OKLCH e gera a paleta tonal (mesmos valores de luminosidade e croma do tema do Firefox).
3. Grava a paleta no bloco `palette` do `material-you.omp.json` e o esquema do Terminal em um fragmento.
4. Guarda um cache e só recalcula quando a cor muda.

## Problemas comuns

- **"O arquivo não está assinado digitalmente"**: o Windows bloqueou o arquivo baixado. Rode `Unblock-File` nele, ou use o `install.ps1`, que já faz isso.
- **Ícones quebrados (quadradinhos)**: falta uma Nerd Font selecionada no terminal.
- **Prompt roxo, sem seguir o papel de parede**: confira se *Cor em destaque* está em *Automático* nas configurações do Windows e rode `mytheme`.
- **Quer saber quanto tempo o perfil leva**: `$env:PROFILE_TIMING = 1` e abra um terminal novo.

## Licença

MIT
