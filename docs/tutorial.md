# 📚 Tutorial: Understudy — One AI, Every Role

> Guía completa para desplegar y usar agentes IA especializados.
> Un solo asistente que se pone la gorra del rol que necesitas.
> Compatible con GitHub Copilot CLI, VS Code, Claude Code y Cursor.

---

## Capítulo 1: Los conceptos fundamentales

### 1.1 ¿Qué es un agente en Copilot CLI?

Un agente es una **personalidad especializada** que Copilot adopta.
En lugar de hablar con un "asistente genérico", hablas con un
Arquitecto de Soluciones, un Desarrollador Backend, o un Experto en Seguridad.

Cada agente tiene:
- **Conocimiento de dominio**: Sabe de su área específica
- **Reglas de comportamiento**: Sigue estándares definidos
- **Forma de comunicar**: Produce output estructurado para su rol
- **Interacción con el equipo**: Sabe cuándo consultar a otro agente

### 1.2 ¿Dónde se definen?

#### En GitHub Copilot CLI / VS Code

| Archivo | Alcance | Carga | Propósito |
|---|---|---|---|
| `AGENTS.md` | Raíz del repo / cwd | Automática, seleccionable con `/agent` | Definir agentes del equipo |
| `.github/copilot-instructions.md` | Proyecto | Automática, siempre activo | Contexto global del proyecto + guardrails críticos |
| `.github/instructions/*.instructions.md` | Proyecto | Automática, toggleable con `/instructions` | Instrucciones detalladas por rol |
| `.github/instructions/guardrails.instructions.md` | Proyecto | Automática (applyTo: `**`) | Guardrails completos para todos los agentes |
| `~/.copilot/copilot-instructions.md` | Usuario | Automática, siempre activo | Preferencias personales globales |

#### En Claude Code

| Archivo | Alcance | Carga | Propósito |
|---|---|---|---|
| `CLAUDE.md` | Raíz del proyecto | Automática, siempre activo | Contexto global + guardrails críticos |
| `.claude/agents/*.md` | Proyecto | Invocables por nombre | Agentes por rol (con modelo y tools en frontmatter) |
| `.claude/commands/*.md` | Proyecto | Invocables con `/project:nombre` | Comandos reutilizables (start-session, etc.) |
| `.claude/settings.json` | Proyecto | Automática | Permisos (deny) y hooks |
| `.claude/hooks/*.sh` | Proyecto | Automática (via settings.json) | Scripts para guardrails |

#### En Cursor

| Archivo | Alcance | Carga | Propósito |
|---|---|---|---|
| `.cursor/rules/understudy-global.mdc` | Proyecto | Automática (`alwaysApply: true`) | Reglas globales del proyecto |
| `.cursor/rules/guardrails.mdc` | Proyecto | Automática (`alwaysApply: true`) | Guardrails de seguridad |
| `.cursor/agents/*.md` | Proyecto | Invocables desde Agent panel | Agentes por rol (con modelo en frontmatter) |

### 1.3 Multi-agentes y sub-agentes

**Multi-agentes** = Tener varios agentes definidos y cambiar entre ellos con `/agent`.
**Sub-agentes** = Copilot puede lanzar agentes internos (via el task tool) que trabajan
en paralelo en subtareas independientes.

Ejemplo de flujo multi-agente:
```
Tú: /agent Architect → "Diseña la API de clientes"
Architect: [produce diseño con ADR + OpenAPI spec]

Tú: /agent Backend → "Implementa la API según el diseño del Architect"
Backend: [lee docs/decisions.md, implementa siguiendo el contrato]

Tú: /agent Security → "Revisa la implementación"
Security: [analiza código, reporta findings]
```

Ejemplo de sub-agentes paralelos:
```
Tú: "Implementa el frontend y backend de la feature de login simultáneamente"
Copilot: [lanza sub-agente Backend y sub-agente Frontend en paralelo]
         [cada uno trabaja independientemente siguiendo los contratos del Architect]
```

---

## Capítulo 2: Spec-Driven Development

### 2.1 ¿Por qué spec-first?

Sin una especificación clara:
- Cada agente interpreta los requisitos a su manera
- Se pierde tiempo re-haciendo trabajo
- Las decisiones no tienen fundamento documentado

Con spec-first:
- Todos los agentes leen la misma fuente de verdad (`docs/spec.md`)
- El Architect diseña contra requisitos concretos
- Backend y Frontend implementan contra contratos definidos
- Security sabe qué activos proteger

### 2.2 Flujo spec-driven

```
1. PM escribe docs/spec.md (requisitos de negocio)
       ↓
2. /agent Architect refina la spec (preguntas técnicas)
       ↓
3. PM aprueba la spec refinada
       ↓
4. Architect produce diseño + contratos de API
       ↓
5. Security valida threat model
       ↓
6. Backend + Frontend implementan en paralelo
       ↓
7. QA diseña test plan y escribe tests
       ↓
8. DevOps prepara infra + CI/CD
       ↓
9. Security hace review final
```

### 2.3 La spec como contrato

La spec NO es documentación estática. Es un **contrato vivo**:
- Si el PM cambia requisitos → actualiza la spec primero
- Si el Architect descubre restricciones → actualiza la spec
- Todos los agentes la referencian constantemente

---

## Capítulo 3: Persistencia entre sesiones

### 3.1 El problema

Copilot CLI **no tiene memoria entre sesiones**. Cada vez que abres una nueva sesión,
el agente empieza de cero. Esto significa:
- Gastar tokens re-explicando contexto
- Riesgo de decisiones inconsistentes
- Pérdida de progreso

### 3.2 La solución: archivos de contexto

El Understudy usa tres archivos como "memoria persistente":

**`docs/spec.md`** — Qué hay que hacer
- Fuente de verdad de requisitos
- Se lee al inicio de cada sesión
- Se actualiza cuando cambia el alcance

**`docs/decisions.md`** — Qué se decidió y por qué
- Registro de decisiones arquitectónicas (ADR)
- Evita re-discutir decisiones ya tomadas
- Cada ADR explica contexto, alternativas y consecuencias

**`docs/session-log.md`** — Qué se hizo y qué falta
- Log cronológico de sesiones
- Se lee al inicio: "¿qué se hizo ayer?"
- Se actualiza al final: "¿qué hicimos hoy?"
- Incluye pendientes y bloqueantes

### 3.3 Protocolo de sesión

**Al INICIAR una sesión:**
```
Tú: "Lee docs/session-log.md, docs/spec.md y docs/decisions.md
     para ponerte al día del proyecto"
```

**Al FINALIZAR una sesión:**
```
Tú: "Actualiza docs/session-log.md con lo que hicimos hoy,
     qué queda pendiente y decisiones tomadas"
```

Esto cuesta unos pocos tokens y ahorra MUCHOS en la siguiente sesión.

---

## Capítulo 4: El Wizard

### 4.1 ¿Qué hace?

El wizard (`wizard.sh`) automatiza el despliegue del Understudy:

1. Te pregunta datos del proyecto (nombre, stack, PM, etc.)
2. Te pregunta el modo de guardrails (split o embedded)
3. Te pregunta qué plataformas desplegar (Copilot, Claude Code, Cursor)
4. Crea toda la estructura de directorios
5. Genera los archivos de cada plataforma con los datos del proyecto
6. Opcionalmente inicializa git
7. Te da instrucciones de cómo empezar según la plataforma

### 4.2 Uso

```bash
# Despliegue completo
./wizard.sh

# Añadir miembro (ej: Data Engineer)
./wizard.sh --add-member

# Crear rol personalizado
./wizard.sh --create-role
```

### 4.3 Integración en proyectos existentes

El wizard no solo crea proyectos nuevos — también **se integra en proyectos existentes**
sin tocar ningún archivo que ya exista:

```bash
# Ejemplo: tu proyecto React ya existe en ./mi-app
./wizard.sh
# → Nombre: mi-app
# → Directorio base: .
# → El wizard detecta que mi-app/ ya existe
# → Muestra el stack detectado y pregunta si integrar
```

El wizard opera en **3 modos**:

| Modo | Cuándo | Qué hace |
|---|---|---|
| 🆕 **Nuevo** | La carpeta no existe | Crea todo desde cero |
| 🔄 **Integración** | La carpeta tiene un proyecto | Añade Understudy sin tocar archivos existentes |
| ⚠️ **Re-despliegue** | Ya tiene Understudy (AGENTS.md / CLAUDE.md / .cursor/agents) | Solo añade archivos faltantes |

### 4.4 Detección de stack y monorepos

Al encontrar un proyecto existente, el wizard **escanea hasta 3 niveles de profundidad**
para detectar tecnologías. Reconoce:

- **.NET**: `*.csproj`, `*.sln` (con nombre del proyecto)
- **Node.js**: `package.json` en subdirectorios
- **React / Vue / Angular**: detecta el framework dentro de `package.json`
- **Python**: `requirements.txt`, `pyproject.toml`, `setup.py`, `Pipfile`
- **Terraform**: `*.tf`
- **Docker**: `Dockerfile` (cuenta cuántos hay), `docker-compose.yml`

Cuando detecta **más de 2 proyectos independientes**, lo etiqueta como **Monorepo**:

```
🔍 Proyecto existente detectado

  Stack detectado:   Monorepo: .NET(2) + Node.js + React(2) + Python + Terraform + Docker

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

El stack detectado se usa como **valor por defecto** que puedes aceptar o modificar.

### 4.5 Extensibilidad

El directorio `roles/` contiene plantillas de roles adicionales.
Puedes crear cualquier rol que necesites:

- Data Engineer → `roles/data-engineer.instructions.md`
- Technical Writer → `roles/tech-writer.instructions.md`
- ML Engineer → `roles/ml-engineer.instructions.md`
- Performance Engineer → `roles/perf-engineer.instructions.md`

El wizard tiene una opción interactiva para crear roles desde cero.

---

## Capítulo 5: Configuración y Override

### 5.1 El archivo understudy.yaml

El Understudy usa un archivo de configuración YAML para controlar:
- **Modelos por rol**: Qué modelo se recomienda para cada agente
- **Scoping (applyTo)**: En VS Code, qué archivos activan qué instrucciones
- **Comportamiento de sesión**: Auto-leer contexto, auto-actualizar log

### 5.2 Jerarquía de prioridad

```
Defaults del wizard (hardcoded)
    ↓ sobrescrito por
understudy.yaml global (junto a wizard.sh)
    ↓ sobrescrito por
understudy.yaml del proyecto (en la raíz del repo)
```

Esto permite:
- Tener defaults corporativos en el sistema global
- Overrides por proyecto (ej: "este proyecto usa Opus para Security")

### 5.3 Ejemplo de override

```yaml
# mi-proyecto-fintech/understudy.yaml
models:
  architect: "claude-opus-4.6"    # mantener default
  security: "claude-opus-4.6"     # override: más razonamiento para fintech
  backend: "claude-sonnet-4"      # override: usar Sonnet 4 en vez de 4.5
```

### 5.4 Configuración de guardrails

Los guardrails se configuran en `understudy.yaml`:

```yaml
guardrails:
  mode: "split"   # "split" o "embedded"
```

| Modo | Qué hace |
|---|---|
| `split` (recomendado) | Guardrails críticos siempre en `copilot-instructions.md` + archivo completo `guardrails.instructions.md` con detalles y ejemplos |
| `embedded` | Solo guardrails críticos incrustados en `copilot-instructions.md` (más ligero, sin archivo separado) |

El modo se selecciona durante el despliegue con el wizard y se puede cambiar editando el config.

### 5.5 Configuración de plataformas

El wizard soporta despliegue para una o varias plataformas:

```yaml
platforms:
  copilot: true    # GitHub Copilot CLI / VS Code
  claude: true     # Claude Code
```

Si solo usas una plataforma, pon `false` en la otra. El wizard también
permite seleccionar la plataforma durante el despliegue interactivo.

---

## Capítulo 6: Guardrails — Protección del equipo

### 6.1 ¿Qué son los guardrails?

Los guardrails son **límites de seguridad y comportamiento no negociables** que todos
los agentes del Understudy deben respetar. No son sugerencias — son restricciones duras.

Protegen contra:
- Fugas de secretos o datos sensibles en código o logs
- Operaciones destructivas sin confirmación del PM
- Cambios en producción sin control de cambio
- Código sin spec, sin tests, o sin review
- Violaciones de scope entre agentes

### 6.2 Las 8 categorías

| # | Categoría | Qué protege | Ejemplo |
|---|---|---|---|
| 1 | 🛡️ **Seguridad** | No secretos, input validation | "NUNCA hardcodear API keys" |
| 2 | 🎯 **Scope** | Ownership de archivos por agente | "Backend no modifica componentes React sin justificación" |
| 3 | 📋 **Proceso** | Spec-first, decisiones documentadas | "No codificar sin spec aprobada (excepto bugfixes)" |
| 4 | 💥 **Destructivas** | Confirmación antes de borrar | "Antes de `terraform destroy`: explica qué, por qué, impacto" |
| 5 | 🔒 **Datos/PII** | No datos reales en código/tests | "Usar datos sintéticos, nunca PII real" |
| 6 | 🏗️ **Calidad** | Self-review, tests, naming | "Self-review antes de presentar, error handling explícito" |
| 7 | ⚠️ **Entornos** | Orden de promoción, IaC | "dev → test → acc → eng → prd, nunca saltar" |
| 8 | 📝 **Documentación** | ADRs, session-log, spec | "Actualizar session-log al final de cada sesión" |

### 6.3 Cómo se aplican

Los guardrails se aplican en **dos capas**:

1. **Guardrails críticos** — Incrustados en `copilot-instructions.md` (siempre activos).
   Versión compacta con las reglas más importantes: seguridad, destructivas, datos, entornos.

2. **Guardrails completos** — Archivo `.github/instructions/guardrails.instructions.md`
   con las 8 categorías detalladas, ejemplos, tablas de ownership y sección de enforcement.
   En VS Code se auto-aplica a todos los archivos (`applyTo: "**"`).

### 6.4 Excepciones válidas

Los guardrails son estrictos pero no dogmáticos. Hay excepciones legítimas:

| Regla | Excepción válida |
|---|---|
| Spec-first | Bugfixes, emergencias, CVE de dependencias, cambios de config |
| Scope/ownership | Cambio cross-cutting con justificación (ej: security fix) |
| Tests obligatorios | Documentación, config, metadata — validación apropiada en vez de unit tests |

### 6.5 Enforcement

Si una instrucción del usuario o del proyecto contradice los guardrails:
1. El agente prioriza los guardrails
2. Explica al PM qué regla se violaría
3. Propone una alternativa segura
4. Documenta el incidente en session-log

La única forma de desactivar un guardrail es que el PM lo haga explícitamente
en `understudy.yaml`.

---

## Capítulo 7: Uso en Claude Code

### 7.1 Archivos generados

Cuando despliegas para Claude Code, el wizard genera:

| Archivo | Función |
|---|---|
| `CLAUDE.md` | Instrucciones globales (siempre cargado, equivale a `copilot-instructions.md`) |
| `.claude/agents/*.md` | Un agente por rol con frontmatter (name, model, tools) |
| `.claude/commands/*.md` | Comandos invocables con `/project:nombre` |
| `.claude/settings.json` | Permisos deny (protege .env, claves) + wiring de hooks |
| `.claude/hooks/guardrails-check.sh` | Hook PreToolUse que bloquea operaciones destructivas |

### 7.2 Diferencias con Copilot

| Concepto | Copilot | Claude Code |
|---|---|---|
| Agentes separados | AGENTS.md + .instructions.md | `.claude/agents/` (todo-en-uno) |
| Instrucciones globales | `copilot-instructions.md` | `CLAUDE.md` |
| Prompts reutilizables | `.github/prompts/` | `.claude/commands/` |
| Guardrails enforcement | Solo por instrucciones | Instrucciones + hooks + settings.json deny |
| Modelo por agente | Recomendación en texto | Frontmatter `model:` en cada agente |

### 7.3 Comandos disponibles

| Comando | Para qué |
|---|---|
| `/project:start-session` | Cargar contexto al iniciar sesión |
| `/project:end-session` | Actualizar session-log al cerrar |
| `/project:design-feature` | Diseñar una feature con el Architect |
| `/project:security-review` | Security review de cambios actuales |

### 7.4 Guardrails en Claude Code

Los guardrails funcionan en **3 capas** en Claude Code:

1. **CLAUDE.md**: Guardrails críticos incrustados (siempre cargados)
2. **settings.json deny**: Protege archivos sensibles (.env, claves, secretos)
3. **hooks/guardrails-check.sh**: Hook PreToolUse que bloquea comandos destructivos
   (rm -rf, terraform destroy, kubectl delete, DROP TABLE, etc.)

### 7.5 Uso dual Copilot + Claude

Si despliegas ambas plataformas, cada una tiene sus propios archivos pero
comparten la documentación (`docs/`), el config (`understudy.yaml`) y los
estándares del equipo. Puedes usar ambas simultáneamente en el mismo proyecto.

---

## Capítulo 8: Uso en VS Code

### 8.1 ¿Qué funciona igual?

| Archivo | CLI | VS Code |
|---|---|---|
| `.github/copilot-instructions.md` | ✅ Auto-cargado | ✅ Auto-cargado |
| `.github/instructions/*.instructions.md` | ✅ Toggleable | ✅ Auto-aplica por applyTo |
| `.github/instructions/guardrails.instructions.md` | ✅ Toggleable | ✅ Auto-aplica a todos (`**`) |
| `AGENTS.md` | ✅ `/agent` | ✅ Leído como contexto |
| `docs/*.md` | ✅ Leídos por agentes | ✅ Leídos por agentes |

### 8.2 ¿Qué es diferente?

**Frontmatter `applyTo`**: En VS Code, cada `.instructions.md` tiene un frontmatter YAML:
```yaml
---
applyTo: "src/components/**,**/*.tsx"
---
```
Cuando editas un archivo `.tsx`, VS Code aplica automáticamente las instrucciones
del Frontend. No necesitas hacer `/instructions` manualmente.

**Prompt files**: VS Code soporta `.github/prompts/*.prompt.md` — prompts reutilizables
que puedes invocar desde Copilot Chat. El wizard despliega 4 prompts:

| Prompt | Para qué |
|---|---|
| `start-session.prompt.md` | Cargar contexto al iniciar |
| `end-session.prompt.md` | Actualizar session-log al cerrar |
| `design-feature.prompt.md` | Diseñar una feature con el Architect |
| `security-review.prompt.md` | Security review de cambios |

### 8.3 Selección de modelo en VS Code

En VS Code, cambias de modelo desde el model picker en la UI de Copilot Chat
(dropdown en la esquina del panel de chat). El `understudy.yaml` y las
instrucciones incluyen la recomendación de modelo — pero la selección es manual.

---

## Capítulo 9: Uso en Cursor

### 9.1 Configuración

Cursor usa dos sistemas complementarios:

| Componente | Ubicación | Carga | Propósito |
|---|---|---|---|
| **Agents** | `.cursor/agents/*.md` | Agent panel | Agentes especializados por rol |
| **Rules** | `.cursor/rules/*.mdc` | Automática | Reglas globales y guardrails |

### 9.2 ¿Cómo funcionan las rules?

Las rules usan formato MDC (Markdown + frontmatter YAML):

```yaml
---
description: "Descripción de la rule"
alwaysApply: true
---
# Contenido de la rule en Markdown
```

Tipos de rules:
- **Always** (`alwaysApply: true`): Se cargan en cada sesión, como las instrucciones globales
- **Auto Attached** (con `globs`): Se cargan cuando editas archivos que coinciden con el patrón
- **Agent Requested** (solo `description`): El agente decide si cargarlas según contexto
- **Manual**: Solo se cargan si las invocas explícitamente

El Understudy despliega dos rules "Always":
- `understudy-global.mdc` — Instrucciones globales del proyecto
- `guardrails.mdc` — Guardrails de seguridad

### 9.3 ¿Cómo funcionan los agents?

Los agents tienen frontmatter con `name`, `description` y `model`:

```yaml
---
name: architect
description: "Arquitecto de Soluciones del Understudy"
model: auto
---
# Instrucciones del agente
```

Se invocan desde el **Agent panel** de Cursor. Cada agente tiene su propio modelo
recomendado configurado en el frontmatter.

### 9.4 Diferencias con otras plataformas

| Aspecto | Copilot | Claude Code | Cursor |
|---|---|---|---|
| Invocación de agentes | `/agent` | Por nombre | Agent panel |
| Instrucciones globales | `copilot-instructions.md` | `CLAUDE.md` | `.cursor/rules/*.mdc` |
| Guardrails | `.instructions.md` + embedded | `CLAUDE.md` + hooks | `guardrails.mdc` |
| Comandos/Prompts | `.github/prompts/` | `.claude/commands/` | N/A |
| Protección de archivos | N/A | `settings.json` deny | N/A |

---

## Capítulo 10: Optimización de costes (tokens)

### 5.1 Selección de modelo por tarea

| Tarea | Modelo recomendado | Por qué |
|---|---|---|
| Diseño arquitectónico | Claude Opus | Razonamiento profundo, decisiones complejas |
| Implementación backend | Claude Sonnet | Buen balance calidad/velocidad/coste |
| Implementación frontend | Claude Sonnet | Idem |
| Testing / QA | Claude Sonnet | Test plans y código de tests |
| Scripts DevOps | Claude Haiku | Tareas estructuradas, más económico |
| Security review | Claude Sonnet/Opus | Depende de la complejidad |
| Preguntas rápidas | Claude Haiku | Mínimo coste |

Cambia de modelo en cualquier momento con `/model`.

### 5.2 Reducir tokens con contexto persistente

- Usa `docs/session-log.md` en lugar de re-explicar
- Usa `/compact` si la conversación se alarga mucho
- Pide al agente que lea archivos específicos, no "todo el proyecto"

### 5.3 Sub-agentes vs sesiones secuenciales

- **Sub-agentes**: Copilot lanza internamente agentes que trabajan en paralelo.
  Útil cuando Backend y Frontend pueden avanzar independientemente.
- **Sesiones secuenciales**: Cambias de agente con `/agent` y trabajas uno a uno.
  Útil cuando necesitas supervisión estrecha de cada paso.

---

## Capítulo 11: Cheat Sheet

### Comandos Copilot CLI esenciales

| Comando | Qué hace |
|---|---|
| `/agent` | Seleccionar un agente del equipo |
| `/instructions` | Activar/desactivar instrucciones modulares |
| `/model` | Cambiar modelo (Opus, Sonnet, Haiku) |
| `/compact` | Comprimir historial para ahorrar tokens |
| `/diff` | Revisar cambios hechos |
| `/context` | Ver uso de tokens de la sesión |

### Comandos Claude Code

| Comando | Qué hace |
|---|---|
| `/project:start-session` | Cargar contexto del proyecto |
| `/project:end-session` | Cerrar sesión y actualizar logs |
| `/project:design-feature` | Diseñar una feature con el Architect |
| `/project:security-review` | Security review de cambios |

### Cursor

En Cursor no hay comandos de texto como en Copilot CLI o Claude Code.
La interacción se hace a través de la UI:

| Acción | Cómo |
|---|---|
| Invocar un agente | Agent panel → seleccionar agente (architect, backend, etc.) |
| Rules globales | Se cargan automáticamente — no requiere acción |
| Guardrails | Se cargan automáticamente desde `.cursor/rules/guardrails.mdc` |

### Comandos del Wizard

| Comando | Qué hace |
|---|---|
| `./wizard.sh` | Despliegue interactivo (nuevo o integración) |
| `./wizard.sh --add-member` | Añadir un miembro extra (Data Engineer, etc.) |
| `./wizard.sh --create-role` | Crear un rol personalizado desde cero |
| `./wizard.sh --help` | Mostrar ayuda |

> El wizard detecta automáticamente si el directorio ya contiene un proyecto
> (Node.js, .NET, Python, monorepo, etc.) y ofrece **modo integración**.

### Frases útiles para el PM

```
"Lee docs/session-log.md y ponte al día"
"Diseña la solución para [requisito] siguiendo la spec"
"Implementa [feature] según el contrato del Architect"
"Revisa el código de Backend desde perspectiva de seguridad"
"Actualiza session-log.md con lo que hicimos hoy"
"¿Qué riesgos ves en esta arquitectura?"
"Razona paso a paso antes de diseñar la solución"
```

### Flujo típico de una sesión

**Con Copilot CLI:**
```bash
# 1. Abrir Copilot CLI en el proyecto
cd mi-proyecto && copilot

# 2. Ponerse al día
"Lee session-log.md, spec.md y decisions.md para contexto"

# 3. Trabajar con el agente apropiado
/agent Architect   # para diseñar
/agent Backend     # para implementar APIs
/agent Frontend    # para implementar UI
/agent QA          # para tests y calidad
/agent DevOps      # para infra y CI/CD
/agent Security    # para review de seguridad

# 4. Al terminar
"Actualiza session-log.md con resumen de esta sesión"
```

**Con Claude Code:**
```bash
# 1. Abrir Claude Code en el proyecto
cd mi-proyecto && claude

# 2. Ponerse al día
/project:start-session

# 3. Trabajar — invocar agentes por nombre o usar comandos
/project:design-feature    # para diseñar
/project:security-review   # para review de seguridad

# 4. Al terminar
/project:end-session
```

**Con Cursor:**
```bash
# 1. Abrir Cursor en el proyecto
cd mi-proyecto && cursor .

# 2. Las rules se cargan automáticamente — revisa session-log.md
"Lee docs/session-log.md y ponte al día"

# 3. Invocar agentes desde el Agent panel
# → architect, backend, frontend, devops, security, qa-engineer

# 4. Al terminar
"Actualiza docs/session-log.md con lo que hicimos hoy"
```
