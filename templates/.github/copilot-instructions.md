# Copilot Project Instructions — {{PROJECT_NAME}}
#
# ┌─────────────────────────────────────────────────────────────┐
# │  TUTORIAL: ¿Qué es .github/copilot-instructions.md?        │
# │                                                             │
# │  Este archivo es CARGADO AUTOMÁTICAMENTE por Copilot CLI    │
# │  cada vez que abres una sesión en este repositorio.         │
# │  No necesitas hacer /agent ni /instructions para que        │
# │  se aplique — siempre está activo.                          │
# │                                                             │
# │  Úsalo para:                                                │
# │  - Dar contexto general del proyecto a TODOS los agentes    │
# │  - Definir reglas globales que aplican sin importar el rol  │
# │  - Establecer convenciones del proyecto                     │
# │  - Indicar dónde encontrar documentación clave              │
# │                                                             │
# │  Diferencia con AGENTS.md:                                  │
# │  - copilot-instructions.md = contexto global, siempre on   │
# │  - AGENTS.md = roles seleccionables vía /agent              │
# │                                                             │
# │  Diferencia con .github/instructions/*.instructions.md:     │
# │  - copilot-instructions.md = aplica a TODOS                 │
# │  - *.instructions.md = instrucciones modulares, toggleables │
# │    vía /instructions                                        │
# └─────────────────────────────────────────────────────────────┘

## Proyecto

- **Nombre**: {{PROJECT_NAME}}
- **Descripción**: {{PROJECT_DESCRIPTION}}
- **Stack principal**: {{TECH_STACK}}
- **Repositorio**: {{REPOSITORY_URL}}
- **Project Manager**: {{TEAM_LEAD}}

## Contexto del equipo

Este proyecto utiliza el sistema **Understudy**: un equipo de agentes IA especializados.
Cada agente tiene un rol definido en `AGENTS.md` y instrucciones detalladas en
`.github/instructions/<rol>.instructions.md`.

Los roles disponibles son:
- **Architect** — Diseño de soluciones y decisiones arquitectónicas
- **Backend** — Implementación de APIs, servicios y lógica de negocio
- **Frontend** — Interfaces de usuario y experiencia
- **DevOps** — Infraestructura, CI/CD y operaciones
- **Security** — Seguridad integrada en todo el ciclo
- **QA** — Testing y calidad del software (.NET, Node.js, Python)

## Spec-Driven Development

Este proyecto sigue **Spec-Driven Development**:
1. Antes de escribir código, se documenta la especificación en `docs/spec.md`
2. La spec debe ser aprobada por el PM antes de comenzar
3. Cualquier cambio de alcance se refleja primero en la spec

## Archivos de contexto obligatorios

| Archivo | Propósito |
|---|---|
| `docs/spec.md` | Especificación del proyecto — la fuente de verdad |
| `docs/decisions.md` | Registro de decisiones arquitectónicas (ADR) |
| `docs/session-log.md` | Log de sesiones — leer al inicio de cada sesión |
| `docs/team-roster.md` | Roster del equipo activo y sus capacidades |

## Reglas globales

### Al iniciar una sesión
1. **Siempre** lee `docs/session-log.md` para saber qué se hizo antes
2. **Siempre** lee `docs/spec.md` para contexto del proyecto
3. **Siempre** lee `docs/decisions.md` para decisiones ya tomadas
4. Antes de trabajar, confirma tu entendimiento del estado actual

### Al finalizar una sesión
1. Actualiza `docs/session-log.md` con:
   - Qué se hizo en esta sesión
   - Qué queda pendiente
   - Decisiones tomadas
   - Bloqueantes identificados
2. Esto asegura que la siguiente sesión (otro día, otro momento) tenga contexto completo

### Estándares de código
- Código legible y mantenible por cualquier miembro del equipo
- Funciones de responsabilidad única
- Nombres de dominio de negocio, no nombres genéricos
- Error handling explícito con contexto en los mensajes
- Sin secretos hardcodeados — usar vault/env vars
- Sin código muerto o comentarios TODO en commits

### Estructura del proyecto
```
{{PROJECT_NAME}}/
├── .github/
│   ├── copilot-instructions.md     ← este archivo
│   ├── instructions/               ← instrucciones por rol
│   └── prompts/                    ← prompts reutilizables (VS Code)
│       ├── start-session.prompt.md
│       ├── end-session.prompt.md
│       ├── design-feature.prompt.md
│       └── security-review.prompt.md
├── AGENTS.md                       ← definición del equipo
├── understudy.yaml               ← configuración de modelos y scoping
├── docs/                           ← documentación del proyecto
│   ├── spec.md
│   ├── decisions.md
│   ├── session-log.md
│   └── team-roster.md
├── src/                            ← código fuente
├── tests/                          ← tests
└── scripts/                        ← scripts de automatización
```

## Configuración y modelos

Los modelos recomendados por rol están definidos en `understudy.yaml` en la raíz del proyecto.
Para cambiar el modelo de un rol, edita ese archivo:

```yaml
models:
  architect: "claude-opus-4.6"       # razonamiento profundo para diseño
  backend: "claude-sonnet-4.5"       # balance calidad/velocidad
  frontend: "claude-sonnet-4.5"
  devops: "claude-haiku-4.5"         # económico para tareas estructuradas
  security: "claude-sonnet-4.5"
  qa-engineer: "claude-sonnet-4.5"   # test plans y código de tests
```

En **Copilot CLI**: usa `/model` para seleccionar el modelo recomendado para el rol activo.
En **VS Code**: usa el model picker en el panel de Copilot Chat.

<!-- GUARDRAILS_START -->
{{GUARDRAILS_SECTION}}
<!-- GUARDRAILS_END -->

## Compatibilidad CLI y VS Code

Este proyecto funciona tanto con Copilot CLI como con VS Code sin cambios.

**En VS Code:**
- Las instrucciones de `.github/instructions/*.instructions.md` se aplican
  automáticamente según el tipo de archivo que estés editando (frontmatter `applyTo`)
- Los prompts de `.github/prompts/` están disponibles como flujos reutilizables
- `copilot-instructions.md` (este archivo) se carga automáticamente

**En Copilot CLI:**
- Usa `/agent` para seleccionar un miembro del equipo
- Usa `/instructions` para activar/desactivar instrucciones por rol
- Usa `/model` para cambiar el modelo según la tarea
