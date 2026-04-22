# {{PROJECT_NAME}} — Instrucciones del Proyecto

## Proyecto

- **Nombre**: {{PROJECT_NAME}}
- **Descripción**: {{PROJECT_DESCRIPTION}}
- **Stack principal**: {{TECH_STACK}}
- **Repositorio**: {{REPOSITORY_URL}}
- **Project Manager**: {{TEAM_LEAD}}

## Contexto del equipo

Este proyecto utiliza el sistema **Understudy**: un equipo de agentes IA especializados.
Cada agente tiene un rol definido en `.claude/agents/` con instrucciones detalladas.

Los roles disponibles son:
- **architect** — Diseño de soluciones y decisiones arquitectónicas
- **backend** — Implementación de APIs, servicios y lógica de negocio
- **frontend** — Interfaces de usuario y experiencia
- **devops** — Infraestructura, CI/CD y operaciones
- **security** — Seguridad integrada en todo el ciclo
- **qa** — Testing y calidad del software

Para activar un agente, invócalo por nombre en Claude Code.

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
├── .claude/
│   ├── agents/                    ← agentes por rol
│   ├── commands/                  ← comandos reutilizables
│   ├── hooks/                     ← hooks de guardrails
│   └── settings.json              ← permisos y configuración
├── CLAUDE.md                      ← este archivo
├── understudy.yaml              ← configuración de modelos y scoping
├── docs/                          ← documentación del proyecto
│   ├── spec.md
│   ├── decisions.md
│   ├── session-log.md
│   └── team-roster.md
├── src/                           ← código fuente
├── tests/                         ← tests
└── scripts/                       ← scripts de automatización
```

## Configuración y modelos

Los modelos recomendados por rol están definidos en `understudy.yaml` en la raíz del proyecto.
Cada agente en `.claude/agents/` tiene su modelo configurado en el frontmatter.

```yaml
models:
  architect: "claude-opus-4.6"       # razonamiento profundo para diseño
  backend: "claude-sonnet-4.5"       # balance calidad/velocidad
  frontend: "claude-sonnet-4.5"
  devops: "claude-haiku-4.5"         # económico para tareas estructuradas
  security: "claude-sonnet-4.5"
  qa-engineer: "claude-sonnet-4.5"   # test plans y código de tests
```

## Comandos disponibles

Usa `/project:nombre-del-comando` para ejecutar comandos predefinidos:
- `/project:start-session` — Cargar contexto del proyecto al iniciar
- `/project:end-session` — Cerrar sesión y actualizar logs
- `/project:design-feature` — Diseñar una nueva feature con el Architect
- `/project:security-review` — Security review de los cambios actuales

<!-- GUARDRAILS_START -->
{{GUARDRAILS_SECTION}}
<!-- GUARDRAILS_END -->
