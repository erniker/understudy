# 📋 Especificación del Proyecto — {{PROJECT_NAME}}
#
# ┌───────────────────────────────────────────────────────────┐
# │  TUTORIAL: Spec-Driven Development                       │
# │                                                           │
# │  Este archivo es LA FUENTE DE VERDAD del proyecto.        │
# │  Ningún agente escribe código sin leer este archivo       │
# │  primero. Esto garantiza que:                             │
# │                                                           │
# │  1. Todos los agentes trabajan con los mismos requisitos  │
# │  2. Se reducen malentendidos y re-trabajo                 │
# │  3. Los cambios de alcance se documentan aquí primero     │
# │  4. En sesiones futuras, cualquier agente puede           │
# │     re-leer esta spec y retomar el contexto               │
# │                                                           │
# │  El PM (tú) escribe la versión inicial. El Architect      │
# │  la refina con preguntas técnicas. El resto del equipo    │
# │  la usa como referencia.                                  │
# └───────────────────────────────────────────────────────────┘

## 1. Resumen ejecutivo

**Nombre del proyecto**: {{PROJECT_NAME}}
**Descripción**: {{PROJECT_DESCRIPTION}}
**Objetivo de negocio**: (¿Qué problema resuelve? ¿Para quién?)

## 2. Stakeholders

| Rol | Nombre | Responsabilidad |
|---|---|---|
| Project Manager | {{TEAM_LEAD}} | Definición de requisitos y priorización |
| Product Owner | (por definir) | Validación de negocio |
| Usuarios finales | (describir) | Uso del sistema |

## 3. Requisitos funcionales

### RF-001: (nombre del requisito)
- **Descripción**: ...
- **Actor**: ¿Quién usa esta funcionalidad?
- **Flujo principal**: Paso a paso del happy path
- **Flujos alternativos**: Qué pasa si algo falla
- **Criterios de aceptación**:
  - [ ] Criterio 1
  - [ ] Criterio 2
- **Prioridad**: Alta / Media / Baja

### RF-002: ...
(repetir para cada requisito funcional)

## 4. Requisitos no funcionales

| ID | Categoría | Requisito | Métrica |
|---|---|---|---|
| NFR-001 | Performance | Tiempo de respuesta API | < 200ms p95 |
| NFR-002 | Disponibilidad | Uptime | 99.9% |
| NFR-003 | Escalabilidad | Usuarios concurrentes | (definir) |
| NFR-004 | Seguridad | Autenticación | (definir método) |
| NFR-005 | Accesibilidad | Estándar | WCAG 2.1 AA |

## 5. Integraciones

| Sistema externo | Tipo | Propósito | Protocolo |
|---|---|---|---|
| (sistema) | API / DB / Mensajería | (para qué) | REST / gRPC / etc. |

## 6. Restricciones

- **Tecnológicas**: (stack obligatorio, regulaciones, etc.)
- **Temporales**: (deadline, milestones)
- **Presupuestarias**: (límites de cloud spend, licencias)
- **Organizacionales**: (equipo disponible, procesos obligatorios)

## 7. Fuera de alcance

Explícitamente NO se incluye en esta versión:
- (funcionalidad excluida 1)
- (funcionalidad excluida 2)

## 8. Glosario

| Término | Definición |
|---|---|
| (término de dominio) | (su significado en este contexto) |

---

> **Estado de la spec**: BORRADOR | EN REVISIÓN | APROBADA
> **Última actualización**: {{DATE}}
> **Aprobada por**: (pendiente)
