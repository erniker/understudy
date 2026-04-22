# 🎭 Team Roster — {{PROJECT_NAME}}

> Registro del equipo activo en este proyecto.
> El wizard genera este archivo automáticamente al desplegar el Understudy.
> Actualízalo si añades o cambias miembros del equipo.

## Equipo base

| Nombre en código | Rol | Archivo de instrucciones | Estado |
|---|---|---|---|
| **Architect** | Arquitecto de Soluciones | `.github/instructions/architect.instructions.md` | ✅ Activo |
| **Backend** | Desarrollador Backend | `.github/instructions/backend.instructions.md` | ✅ Activo |
| **Frontend** | Desarrollador Frontend | `.github/instructions/frontend.instructions.md` | ✅ Activo |
| **DevOps** | Ingeniero DevOps | `.github/instructions/devops.instructions.md` | ✅ Activo |
| **Security** | Experto en Seguridad | `.github/instructions/security.instructions.md` | ✅ Activo |
| **QA** | QA Engineer | `.github/instructions/qa-engineer.instructions.md` | ✅ Activo |

## Equipo extendido (añadidos via wizard)

<!-- El wizard añade filas aquí al invocar "Add team member" -->

| Nombre en código | Rol | Archivo de instrucciones | Estado |
|---|---|---|---|
| <!-- nuevos miembros aquí --> | | | |

## Cómo activar un agente

### En Copilot CLI
1. Abre Copilot CLI en el directorio del proyecto
2. Usa `/agent` para seleccionar un miembro del equipo
3. O activa sus instrucciones con `/instructions`
4. Usa `/model` para seleccionar el modelo recomendado (ver `understudy.yaml`)

### En VS Code
1. Las instrucciones se aplican automáticamente según el archivo que editas
   (configurado via frontmatter `applyTo` en cada `.instructions.md`)
2. Los prompts reutilizables están en `.github/prompts/` — invócalos desde Copilot Chat
3. Usa el model picker para seleccionar el modelo recomendado para la tarea

## Configuración de modelos

Los modelos recomendados por agente están en `understudy.yaml` en la raíz del proyecto.
Edita ese archivo para cambiar modelos sin tocar las instrucciones.

```yaml
models:
  architect: "claude-opus-4.6"    # razonamiento profundo
  backend: "claude-sonnet-4.5"    # balance calidad/velocidad
  devops: "claude-haiku-4.5"      # económico para infra
  qa-engineer: "claude-sonnet-4.5" # test plans y tests
```

## Cómo añadir un miembro

Ejecuta el wizard con la opción de añadir miembro:
```bash
./wizard.sh --add-member
```
O copia un template de `roles/` a `.github/instructions/` y regístralo aquí.
