# Guía de contribución — Understudy

Gracias por querer contribuir a Understudy. Este documento explica cómo trabajamos:
convenciones de código, commits, versionado, changelogs y proceso de pull requests.

---

## Índice

1. [Cómo empezar](#1-cómo-empezar)
2. [Reportar bugs y proponer features](#2-reportar-bugs-y-proponer-features)
3. [Flujo de trabajo con Git](#3-flujo-de-trabajo-con-git)
4. [Convenciones de commits](#4-convenciones-de-commits)
5. [Versionado y tags](#5-versionado-y-tags)
6. [Mantenimiento del CHANGELOG](#6-mantenimiento-del-changelog)
7. [Proceso de pull request](#7-proceso-de-pull-request)
8. [CI local antes de abrir una PR](#8-ci-local-antes-de-abrir-una-pr)
9. [Añadir o modificar roles](#9-añadir-o-modificar-roles)
10. [Código de conducta](#10-código-de-conducta)

---

## 1. Cómo empezar

```bash
# 1. Haz fork del repositorio en GitHub

# 2. Clona tu fork
git clone https://github.com/<tu-usuario>/understudy.git
cd understudy

# 3. Añade el repo original como upstream
git remote add upstream https://github.com/erniker/understudy.git

# 4. Mantén tu fork sincronizado antes de cada contribución
git fetch upstream
git rebase upstream/main
```

No hay dependencias de build. El único requisito para ejecutar el wizard es bash ≥ 4.
En macOS instala bash actualizado con `brew install bash`.

---

## 2. Reportar bugs y proponer features

Usa las **issue templates** de GitHub:

- 🐛 **Bug report** — para comportamientos incorrectos o errores
- ✨ **Feature request** — para proponer nuevas funcionalidades

Antes de abrir una issue, busca si ya existe una similar en
[Issues](https://github.com/erniker/understudy/issues).

---

## 3. Flujo de trabajo con Git

### Ramas

| Patrón | Para qué |
|---|---|
| `feat/<descripcion>` | Nueva funcionalidad |
| `fix/<descripcion>` | Corrección de bug |
| `docs/<descripcion>` | Solo documentación |
| `refactor/<descripcion>` | Refactoring sin cambio de comportamiento |
| `chore/<descripcion>` | Tareas de mantenimiento (deps, CI, etc.) |
| `release/v<X.Y.Z>` | Rama de preparación de release |

```bash
# Crear rama de trabajo
git checkout -b feat/add-platform-engineer-role

# ... trabajas ...

# Sincroniza antes de abrir PR
git fetch upstream
git rebase upstream/main
```

### Política de merge

- Las PRs se integran con **squash merge** en `main`.
- Cada commit en `main` representa un cambio lógico completo.
- No se hace merge directo a `main` sin PR (excepto maintainers en fixes críticos).

---

## 4. Convenciones de commits

Usamos **Conventional Commits** ([spec](https://www.conventionalcommits.org/es/v1.0.0/)).

### Formato

```
<tipo>[alcance opcional]: <descripción corta en imperativo>

[cuerpo opcional — explica el QUÉ y el POR QUÉ, no el cómo]

[footer opcional — refs a issues, breaking changes]
```

### Tipos válidos

| Tipo | Cuándo usarlo |
|---|---|
| `feat` | Nueva funcionalidad visible para el usuario |
| `fix` | Corrección de bug |
| `docs` | Cambios solo en documentación |
| `refactor` | Refactoring sin cambio de comportamiento externo |
| `test` | Añadir o corregir tests |
| `ci` | Cambios en CI/CD o scripts de automatización |
| `chore` | Cambios de mantenimiento (sin impacto en código de producción) |
| `perf` | Mejoras de rendimiento |

### Breaking changes

Si el cambio rompe compatibilidad hacia atrás, añade `!` tras el tipo o un footer `BREAKING CHANGE:`:

```
feat!: cambiar estructura de roles/ — directorio ahora requiere frontmatter

BREAKING CHANGE: Los archivos en roles/ sin frontmatter YAML ya no son válidos.
Ejecuta `./wizard.sh --migrate` para actualizar roles existentes.
```

### Ejemplos

```
feat(wizard): add --upgrade flag to update existing deployments
fix(wizard): detect monorepo when package.json is in subdirectory
docs(tutorial): add chapter on Windows/WSL usage
ci: add bats integration tests
chore: bump markdownlint-cli2-action to v17
```

---

## 5. Versionado y tags

Seguimos **Semantic Versioning** ([semver.org](https://semver.org/lang/es/)):
`MAJOR.MINOR.PATCH`

| Componente | Cuándo se incrementa |
|---|---|
| `MAJOR` | Cambio incompatible con versiones anteriores (breaking change) |
| `MINOR` | Nueva funcionalidad compatible con versiones anteriores |
| `PATCH` | Corrección de bug compatible con versiones anteriores |

Mientras el proyecto está en versión `0.x.y`, el MINOR puede contener breaking changes
(es la convención pre-1.0 de SemVer).

### Cómo crear un tag de release

Solo los maintainers crean tags. El proceso es:

```bash
# 1. Asegúrate de estar en main y sincronizado
git checkout main
git pull upstream main

# 2. Actualiza la versión en CHANGELOG.md (ver sección 6)

# 3. Haz commit del CHANGELOG
git add CHANGELOG.md
git commit -m "chore: release v0.2.0"

# 4. Crea un tag anotado (no lightweight)
git tag -a v0.2.0 -m "Release v0.2.0

Resumen de los cambios principales:
- feat: nueva funcionalidad X
- fix: corrección de Y"

# 5. Push del commit y el tag
git push upstream main
git push upstream v0.2.0
```

### Reglas de los tags

- **Siempre anotados** (`-a`), nunca lightweight — incluyen fecha, autor y mensaje.
- Formato: `v` + número semver → `v0.1.0`, `v1.0.0`, `v1.2.3`.
- El mensaje del tag resume los cambios principales (no es un CHANGELOG completo).
- Un tag apunta siempre al commit de `chore: release vX.Y.Z`.
- **No se borra ni se mueve un tag publicado** — si hay error, se crea un nuevo patch.

---

## 6. Mantenimiento del CHANGELOG

El `CHANGELOG.md` sigue el formato [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

### Estructura

```markdown
## [No publicado]

### Added
- Descripción de nueva funcionalidad.

### Changed
- Descripción de cambio en funcionalidad existente.

### Deprecated
- Funcionalidad que se eliminará en el próximo major.

### Removed
- Funcionalidad eliminada.

### Fixed
- Bug corregido.

### Security
- Vulnerabilidad corregida.
```

### Reglas

1. **Mantén siempre una sección `[No publicado]`** al principio para acumular los cambios
   del trabajo en curso. Nunca la dejes vacía — si no hay cambios, no existe la sección.

2. **Al hacer release**, renombra `[No publicado]` a `[X.Y.Z] - YYYY-MM-DD` y añade
   una nueva sección `[No publicado]` vacía encima.

3. **Una entrada = un cambio lógico**. No agregues múltiples cambios en una línea.

4. **Escribe para el usuario**, no para el desarrollador. Explica el impacto,
   no los detalles de implementación.

5. **No pongas hashes de commit** — el CHANGELOG es para humanos, no para máquinas.

### Quién actualiza el CHANGELOG

- El autor de la PR actualiza `[No publicado]` con su cambio antes de solicitar review.
- El maintainer actualiza la sección al hacer el release.

### Ejemplo de ciclo completo

```markdown
# Estado durante desarrollo (antes de release)
## [No publicado]

### Added
- Flag `--upgrade` para actualizar despliegues existentes.

### Fixed
- Detección incorrecta de monorepo cuando package.json está en subdirectorio.

# Estado después de release v0.2.0
## [No publicado]

## [0.2.0] - 2026-05-15

### Added
- Flag `--upgrade` para actualizar despliegues existentes.

### Fixed
- Detección incorrecta de monorepo cuando package.json está en subdirectorio.
```

---

## 7. Proceso de pull request

### Antes de abrir la PR

- [ ] El branch está sincronizado con `upstream/main` (rebase, no merge).
- [ ] `CHANGELOG.md` tiene una entrada en `[No publicado]`.
- [ ] El CI local pasa (ver sección 8).
- [ ] Los commits siguen Conventional Commits.

### Al abrir la PR

- Rellena el template completo — no borres secciones.
- Referencia la issue relacionada con `Closes #NNN` o `Fixes #NNN`.
- Si la PR es un **draft**, márcala explícitamente como Draft.

### Review

- Al menos **1 aprobación** de un maintainer para hacer merge.
- Los comentarios de review se resuelven con un nuevo commit o respuesta, no silenciosamente.
- El autor hace squash/rebase para limpiar commits de "fix review" antes del merge final.

### Merge

- Los maintainers hacen el merge con **Squash and merge**.
- El mensaje del commit final en main sigue Conventional Commits.

---

## 8. CI local antes de abrir una PR

El CI ejecuta tres checks. Puedes correrlos localmente para no esperar el workflow:

```bash
# ShellCheck (instala con: brew install shellcheck / apt install shellcheck)
shellcheck -e SC2155 -e SC1091 -e SC2034 -e SC2154 wizard.sh
find templates -name "*.sh" -exec shellcheck -e SC2155 -e SC1091 {} \;

# Validación de sintaxis bash
bash -n wizard.sh
find templates -name "*.sh" -exec bash -n {} \;

# Markdown lint (instala con: npm install -g markdownlint-cli2)
markdownlint-cli2 "README.md" "docs/**/*.md"
```

---

## 9. Añadir o modificar roles

Los roles opcionales viven en `roles/`. Sigue la estructura de los roles existentes:

```
roles/
  mi-rol.instructions.md   ← instrucciones del rol para Copilot/VS Code
```

Cada archivo tiene frontmatter YAML con `applyTo` y el cuerpo en Markdown.
Mira `roles/data-engineer.instructions.md` como referencia.

Si el nuevo rol tiene sentido para la comunidad en general, abre una PR.
Si es muy específico de tu dominio, mantenlo en tu fork o en `roles/` local.

---

## 10. Código de conducta

Este proyecto se rige por el [Código de Conducta](CODE_OF_CONDUCT.md).
Al participar, aceptas sus términos.

---

¿Dudas? Abre una [Discussion](https://github.com/erniker/understudy/discussions) en GitHub.
