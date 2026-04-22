# Changelog

Todos los cambios notables de este proyecto se documentan aquí.

El formato se basa en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/)
y este proyecto sigue [Semantic Versioning](https://semver.org/lang/es/).

## [0.1.0] - 2026-04-22

### Added
- Primer release público del sistema Understudy.
- `wizard.sh`: wizard interactivo con detección automática de stack y soporte
  monorepo (hasta 3 niveles de profundidad).
- `understudy.yaml`: configuración global con jerarquía de overrides
  (sistema → proyecto).
- 6 roles core desplegables: Architect, Backend, Frontend, DevOps, Security, QA.
- Catálogo de roles opcionales: data-engineer, mobile-engineer, ml-engineer,
  tech-writer, sre.
- Compatibilidad con 3 plataformas: GitHub Copilot CLI / VS Code,
  Claude Code, Cursor.
- Guardrails en modos `split` (recomendado) o `embedded`.
- 8 categorías de guardrails: seguridad, scope, proceso, destructivas,
  datos/PII, calidad, entornos, documentación.
- Banner ASCII art (font ANSI Shadow) con gradiente cyan→violeta.
- CI con ShellCheck, validación de sintaxis bash y markdown lint.
- Licencia MIT.
