# Política de seguridad

## Versiones con soporte

| Versión | Soporte activo |
|---|---|
| `0.1.x` | ✅ Sí |

Mientras el proyecto esté en `0.x.y`, solo la versión más reciente recibe parches de seguridad.
A partir de `1.0.0` mantendremos una tabla de versiones soportadas más detallada.

## Reportar una vulnerabilidad

**No abras una issue pública para reportar vulnerabilidades de seguridad.**

Si encuentras un problema de seguridad (por ejemplo: un hook que permite inyección de
comandos, una validación de rutas insuficiente en el wizard, o una plantilla que expone
secretos accidentalmente), repórtalo de forma privada:

### Opción 1: GitHub Private Security Advisory (recomendado)

Usa la función
[**Report a vulnerability**](https://github.com/erniker/understudy/security/advisories/new)
de GitHub. Permite discutir el problema de forma confidencial antes de la divulgación pública.

### Opción 2: Correo electrónico

📧 **josepablomedinagrande@hotmail.com**

Incluye en tu reporte:

- Descripción del problema y el impacto potencial
- Pasos para reproducirlo
- Versión afectada (`git describe --tags`)
- Cualquier mitigación temporal que hayas identificado

## Proceso de respuesta

| Plazo | Acción |
|---|---|
| 48 h | Acuse de recibo del reporte |
| 7 días | Evaluación inicial y confirmación o descarte |
| 30 días | Parche publicado (si se confirma la vulnerabilidad) |

Una vez publicado el parche, coordinaremos contigo el momento y el contenido de la
divulgación pública si así lo deseas.

## Scope

Este proyecto es un **generador de archivos de configuración** para herramientas de IA.
No procesa datos de usuario en producción, no tiene backend ni servicios expuestos.

Las vulnerabilidades más relevantes en este contexto son:

- Inyección de comandos en `wizard.sh` a través de inputs del usuario o del proyecto
- Templates que incluyan patrones inseguros que se propaguen a proyectos de los usuarios
- Hooks de Claude Code que permitan ejecución arbitraria no intencionada
- Exposición accidental de secretos en archivos generados

## Divulgación responsable

Seguimos una política de **divulgación coordinada**. Pedimos un mínimo de **30 días** antes
de cualquier publicación pública para tener tiempo de preparar y distribuir el parche.

Agradecemos a quienes contribuyen a la seguridad del proyecto de forma responsable.
