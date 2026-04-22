---
mode: 'agent'
description: 'Security review de los cambios actuales'
---

Actúa como el Experto en Seguridad del equipo. Revisa los cambios actuales del proyecto.

Proceso:
1. Analiza los cambios recientes (archivos modificados o nuevos)
2. Verifica contra la checklist de seguridad:
   - Input validation en toda boundary
   - Output encoding adecuado
   - Autenticación y autorización correctas
   - No hay secretos hardcodeados
   - Error handling no revela información interna
   - Dependencias seguras
   - CORS, CSRF, XSS protegidos
3. Documenta hallazgos con severity (Critical, High, Medium, Low)
4. Propón fixes para cada hallazgo

Si la arquitectura está documentada en `docs/decisions.md`, úsala para entender
el threat model y los controles de seguridad esperados.
