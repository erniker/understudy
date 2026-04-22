# 🎭 Understudy — One AI, Every Role

> Un sistema que configura agentes IA especializados en cualquier proyecto.
> Un solo asistente, múltiples roles: Architect, Backend, Frontend, DevOps, Security, QA.
> Compatible con **GitHub Copilot CLI**, **VS Code**, **Claude Code** y **Cursor**.

## Inicio rápido

```bash
# 1. Navega al directorio del sistema
cd "IA team"

# 2. Da permisos de ejecución al wizard
chmod +x wizard.sh

# 3. Despliega el Understudy en tu proyecto
./wizard.sh
# → Elige plataformas: Copilot, Claude Code, Cursor

# 4. Abre tu herramienta de IA en el proyecto
cd /ruta/a/tu/proyecto
copilot           # GitHub Copilot CLI
# o
claude            # Claude Code
# o
cursor .          # Cursor
```

## ¿Qué es esto?

Un sistema que genera automáticamente toda la configuración necesaria para que
**GitHub Copilot CLI**, **VS Code**, **Claude Code** y **Cursor** funcionen como un equipo completo de desarrollo:

| Miembro | Rol | Expertise |
|---|---|---|
| 🏛️ **Architect** | Arquitecto de Soluciones | Diseño de sistemas, APIs, bases de datos, cloud |
| ⚙️ **Backend** | Desarrollador Backend | .NET, Node.js, C#, TypeScript, Python, Bash |
| 🎨 **Frontend** | Desarrollador Frontend | React, TypeScript, UX/UI, accesibilidad |
| 🚀 **DevOps** | Ingeniero DevOps | Azure, AWS, Docker, K8s, Terraform, CI/CD |
| 🔒 **Security** | Experto en Seguridad | OWASP, threat modeling, compliance, IAM |
| 🧪 **QA** | QA Engineer | Testing .NET, Node.js, Python, E2E, contract testing |

## Conceptos clave

### 1. AGENTS.md — "Quién es el equipo"
Archivo en la raíz del proyecto que define agentes seleccionables con `/agent` en Copilot CLI.
Cada agente tiene un nombre, rol, expertise y reglas de comportamiento.

### 2. .github/copilot-instructions.md — "Reglas del proyecto"
Instrucciones globales que Copilot carga **automáticamente** en cada sesión.
Define el contexto del proyecto, convenciones y flujo de trabajo.

### 3. .github/instructions/*.instructions.md — "Cómo trabaja cada uno"
Archivos modulares de instrucciones por rol. Se activan con `/instructions`
o se cargan junto con el agente correspondiente. Contienen la personalidad
detallada, estándares de código y checklists de cada miembro.

### 4. Sub-agentes paralelos — "Divide y vencerás"
Copilot CLI puede lanzar sub-agentes (task tool) que trabajan en paralelo.
Ideal para que Backend y Frontend implementen simultáneamente mientras
DevOps prepara la infraestructura.

### 5. Archivos de contexto — "Memoria entre sesiones"
Los archivos `docs/session-log.md`, `docs/spec.md` y `docs/decisions.md`
actúan como memoria persistente. Al inicio de cada sesión el agente los lee;
al final, los actualiza. Esto ahorra tokens y evita repetir información.

### 6. 🛡️ Guardrails — "Lo que NUNCA se hace"
Límites de seguridad y comportamiento que todos los agentes respetan.
Cubren 8 categorías: seguridad, scope, proceso, operaciones destructivas,
datos/PII, calidad, entornos y documentación. Son **no negociables** y
se despliegan automáticamente con el wizard.

## Guardrails

Los guardrails protegen al equipo de:
- Fugas de secretos o datos sensibles
- Operaciones destructivas sin confirmación
- Cambios en producción sin control de cambio
- Código sin spec, sin tests, o sin review
- Violaciones de scope entre agentes

### Modos de despliegue

| Modo | Descripción |
|---|---|
| 🔀 **split** (recomendado) | Guardrails críticos siempre activos en `copilot-instructions.md` + archivo completo con detalles en `guardrails.instructions.md` |
| 📦 **embedded** | Solo guardrails críticos incrustados en `copilot-instructions.md` (más ligero, sin archivo separado) |

El modo se selecciona durante el wizard y se puede cambiar editando `understudy.yaml`:

```yaml
guardrails:
  mode: "split"   # "split" o "embedded"
```

### Categorías

| # | Categoría | Qué protege |
|---|---|---|
| 1 | 🛡️ Seguridad | No secretos, no bypass, input validation obligatoria |
| 2 | 🎯 Scope | Ownership de archivos por agente, justificación para cruzar boundaries |
| 3 | 📋 Proceso | Spec-first (con excepciones para bugfixes/emergencias), decisiones documentadas |
| 4 | 💥 Destructivas | Confirmación del PM antes de borrar, purgar o revocar |
| 5 | 🔒 Datos/PII | No datos reales, datos sintéticos en tests, GDPR |
| 6 | 🏗️ Calidad | Self-review, tests apropiados, naming, error handling |
| 7 | ⚠️ Entornos | Orden de promoción dev→prd, IaC obligatorio, no cambios manuales |
| 8 | 📝 Documentación | ADRs, session-log, spec actualizada |

## Estructura del sistema

```
IA team/
├── wizard.sh                    # 🧙 El wizard — despliega el Understudy
├── README.md                    # 📖 Este archivo
├── understudy.yaml            # ⚙️ Configuración global
├── templates/                   # 📋 Plantillas base
│   ├── AGENTS.md                # Copilot: definición del equipo
│   ├── CLAUDE.md                # Claude: instrucciones globales
│   ├── .github/                 # Copilot / VS Code
│   │   ├── copilot-instructions.md
│   │   ├── instructions/
│   │   │   ├── architect.instructions.md
│   │   │   ├── backend.instructions.md
│   │   │   ├── frontend.instructions.md
│   │   │   ├── devops.instructions.md
│   │   │   ├── security.instructions.md
│   │   │   ├── qa-engineer.instructions.md
│   │   │   └── guardrails.instructions.md
│   │   └── prompts/
│   │       ├── start-session.prompt.md
│   │       ├── end-session.prompt.md
│   │       ├── design-feature.prompt.md
│   │       └── security-review.prompt.md
│   ├── .claude/                 # Claude Code
│   │   ├── agents/
│   │   │   ├── architect.md, backend.md, frontend.md
│   │   │   ├── devops.md, security.md, qa.md
│   │   ├── commands/
│   │   │   ├── start-session.md, end-session.md
│   │   │   ├── design-feature.md, security-review.md
│   │   ├── hooks/
│   │   │   └── guardrails-check.sh
│   │   └── settings.json
│   ├── .cursor/                 # Cursor
│   │   ├── agents/
│   │   │   ├── architect.md, backend.md, frontend.md
│   │   │   ├── devops.md, security.md, qa-engineer.md
│   │   └── rules/
│   │       ├── understudy-global.mdc
│   │       └── guardrails.mdc
│   └── docs/
│       ├── spec.md
│       ├── decisions.md
│       ├── session-log.md
│       └── team-roster.md
├── roles/                       # 🎭 Catálogo de roles opcionales
│   ├── data-engineer.instructions.md
│   ├── mobile-engineer.instructions.md
│   ├── ml-engineer.instructions.md
│   ├── tech-writer.instructions.md
│   └── sre.instructions.md
└── docs/                        # 📚 Tutorial y documentación
    └── tutorial.md
```

## Comandos del wizard

| Comando | Descripción |
|---|---|
| `./wizard.sh` | Despliegue interactivo completo |
| `./wizard.sh --add-member` | Añadir un miembro (data engineer, QA, etc.) |
| `./wizard.sh --create-role` | Crear un rol personalizado desde cero |
| `./wizard.sh --help` | Mostrar ayuda |

## Integración en proyectos existentes y monorepos

El wizard detecta automáticamente proyectos existentes y se adapta:

| Escenario | Comportamiento |
|---|---|
| 🆕 Carpeta no existe | Crea proyecto nuevo con toda la estructura |
| 🔄 Proyecto existente | Integra Understudy sin tocar archivos existentes |
| ⚠️ Ya tiene Understudy | Re-despliegue: solo añade archivos faltantes |

### Detección de stack automática

El wizard escanea hasta 3 niveles de profundidad para detectar tecnologías:

| Tecnología | Marcador | Ejemplo |
|---|---|---|
| .NET | `*.csproj`, `*.sln` | `.NET: services/api-customers (ApiCustomers)` |
| Node.js | `package.json` (sin React/Vue/Angular) | `Node.js: services/api-notifications` |
| React | `package.json` con `"react"` | `React: frontend/web-app` |
| Vue | `package.json` con `"vue"` | `Vue: frontend/admin` |
| Angular | `package.json` con `"@angular/core"` | `Angular: frontend/portal` |
| Python | `requirements.txt`, `pyproject.toml`, `setup.py`, `Pipfile` | `Python: services/ml-scoring` |
| Terraform | `*.tf` | `Terraform: infra/terraform` |
| Docker | `Dockerfile`, `docker-compose.yml` | `Docker: 4 Dockerfiles` |

### Soporte monorepo

Cuando se detectan más de 2 proyectos independientes, el stack se etiqueta como **Monorepo**:

```
Monorepo: .NET(2) + Node.js + React(2) + Python + Terraform + Docker

Componentes encontrados:
  • .NET: services/api-customers (ApiCustomers)
  • .NET: services/api-policies (ApiPolicies)
  • React: frontend/web-app
  • Node.js: services/api-notifications
  • Python: services/ml-scoring
  • Terraform: infra/terraform
  • Docker: 4 Dockerfiles
  • Docker Compose: ./
```

El stack detectado se pre-rellena como valor por defecto, ahorrandote tiempo al configurar.

## Flujo de trabajo recomendado

```
PM escribe spec.md
        │
        ▼
   /agent Architect ──── diseña solución ──── docs/decisions.md
        │
        ▼
   /agent Security ───── threat model
        │
        ├──────────────────────┐
        ▼                      ▼
   /agent Backend         /agent Frontend
   (implementa APIs)      (implementa UI)
        │                      │
        └──────────┬───────────┘
                   ▼
             /agent QA
        (test plan + tests)
                   │
                   ▼
            /agent DevOps
        (infra + CI/CD + deploy)
                   │
                   ▼
            /agent Security
          (review final)
                   │
                   ▼
        session-log.md actualizado
```

## Cómo añadir nuevos roles

La carpeta `roles/` es el **catálogo oficial de roles opcionales** del sistema. Los 6 roles core (Architect, Backend, Frontend, DevOps, Security, QA) se despliegan siempre desde `templates/`; los roles de `roles/` son adicionales y los eliges tú.

**Roles opcionales incluidos:**

| Rol | Cuándo usarlo |
|---|---|
| 📊 **data-engineer** | Pipelines ETL/ELT, data warehouses, streaming, data governance |
| 📱 **mobile-engineer** | Apps iOS/Android, React Native, Flutter |
| 🤖 **ml-engineer** | Modelos ML, MLOps, LLMs, RAG, responsible AI |
| 📝 **tech-writer** | Documentación técnica, API docs, tutorials, Diátaxis |
| 🧭 **sre** | SLOs, observabilidad, incident response, chaos engineering |

**Cómo añadirlos:**

1. **Desde el catálogo existente**: `./wizard.sh --add-member` → elige del menú
2. **Crear uno nuevo**: `./wizard.sh --create-role` → se guarda en `roles/` para reutilizar
3. **Manual**: crea un archivo `nombre.instructions.md` en `roles/` siguiendo el formato existente

> Los roles que creas con `--create-role` quedan almacenados en `roles/` y estarán disponibles para **todos tus futuros despliegues** de Understudy, no solo para el proyecto actual.

## Tips para Project Managers

- Usa **Claude Opus** (`/model`) para el Architect — razona mejor en diseño
- Usa **Claude Sonnet** para Backend/Frontend — buen balance velocidad/calidad
- Usa **Claude Haiku** para tareas rápidas de DevOps — económico y eficiente
- Siempre pide actualizar `session-log.md` al final de cada sesión
- La spec es sagrada: si cambia el alcance, actualiza la spec primero

> Estos defaults están en `understudy.yaml`. Edítalo en tu proyecto para personalizar.

## Configuración y override

El sistema usa un archivo de configuración `understudy.yaml` con jerarquía de prioridad:

```
1. Defaults del wizard (hardcoded en wizard.sh)     ← menor prioridad
2. understudy.yaml junto a wizard.sh              ← defaults globales
3. understudy.yaml en el proyecto                  ← override por proyecto
```

Ejemplo de override: tu proyecto necesita Opus para Security porque es fintech:
```yaml
# mi-proyecto/understudy.yaml
models:
  security: "claude-opus-4.6"   # override: más razonamiento para fintech
platforms:
  copilot: true
  claude: true                  # o false si solo usas una plataforma
  cursor: true
guardrails:
  mode: "embedded"              # override: solo críticos para proyecto ligero
```

## Compatibilidad: Copilot CLI + VS Code + Claude Code + Cursor

El Understudy funciona en **las cuatro plataformas** — elige una o todas durante el despliegue:

| Feature | Copilot CLI | VS Code | Claude Code | Cursor |
|---|---|---|---|---|
| Instrucciones globales | ✅ Auto-cargadas | ✅ Auto-cargadas | ✅ CLAUDE.md | ✅ `.cursor/rules/` |
| Instrucciones por rol | ✅ `/instructions` | ✅ Auto-aplica por `applyTo` | ✅ `.claude/agents/` | ✅ `.cursor/agents/` |
| Guardrails | ✅ Auto + `/instructions` | ✅ Auto-aplica (`**`) | ✅ CLAUDE.md + hooks | ✅ `guardrails.mdc` |
| Selección de agente | `/agent` | Chat con contexto | Invocar por nombre | Agent panel |
| Prompt reutilizables | N/A | ✅ `.github/prompts/` | ✅ `/project:comando` | N/A |
| Definición del equipo | ✅ AGENTS.md | ✅ AGENTS.md | ✅ `.claude/agents/` | ✅ `.cursor/agents/` |
| Protección de archivos | N/A | N/A | ✅ `settings.json` deny | N/A |
| Hooks de seguridad | N/A | N/A | ✅ `.claude/hooks/` | N/A |

### En VS Code
- Las instrucciones se aplican **automáticamente** según el archivo que editas
  (gracias al frontmatter `applyTo` en cada `.instructions.md`)
- Los prompts de `.github/prompts/` están disponibles como prompts reutilizables
- Usa "Start Session" y "End Session" prompts para el flujo de contexto

### En Claude Code
- `CLAUDE.md` se carga automáticamente al abrir el proyecto
- Los agentes están en `.claude/agents/` — invócalos por nombre
- Los comandos están en `.claude/commands/` — úsalos con `/project:nombre`
- El hook de guardrails bloquea operaciones destructivas automáticamente
- `settings.json` protege archivos sensibles (.env, claves, secretos)

### En Cursor
- Las reglas globales (`.cursor/rules/`) se aplican **automáticamente** en cada sesión
- Los agentes están en `.cursor/agents/` — invócalos desde el Agent panel
- Los guardrails están en `.cursor/rules/guardrails.mdc` — siempre activos
- Cada agente tiene su modelo configurado en el frontmatter (`auto`, `fast`, o modelo específico)

### Archivos por plataforma

**Copilot / VS Code:**
```
.github/copilot-instructions.md        → Siempre activo (incluye guardrails críticos)
.github/instructions/*.instructions.md → Por tipo de archivo (applyTo)
.github/instructions/guardrails.instructions.md → Siempre activo (applyTo: "**")
.github/prompts/*.prompt.md            → Invocables desde Copilot Chat
AGENTS.md                              → Leído como contexto
```

**Claude Code:**
```
CLAUDE.md                              → Siempre activo (incluye guardrails críticos)
.claude/agents/*.md                    → Agentes por rol (con frontmatter)
.claude/commands/*.md                  → Comandos (/project:nombre)
.claude/settings.json                  → Permisos y hooks
.claude/hooks/guardrails-check.sh      → Hook PreToolUse
```

**Cursor:**
```
.cursor/agents/*.md                    → Agentes por rol (con frontmatter)
.cursor/rules/understudy-global.mdc        → Reglas globales (siempre activas)
.cursor/rules/guardrails.mdc          → Guardrails (siempre activos)
```

## Contribuir

Las contribuciones son bienvenidas. Lee la [guía de contribución](CONTRIBUTING.md) antes
de abrir una PR — incluye convenciones de commits, versionado, mantenimiento del
CHANGELOG y el proceso de review.

Para reportar bugs o proponer mejoras usa las [issue templates](https://github.com/erniker/understudy/issues/new/choose).
Para reportar vulnerabilidades de seguridad, consulta la [política de seguridad](SECURITY.md).

Este proyecto sigue el [Contributor Covenant](CODE_OF_CONDUCT.md) como código de conducta.
