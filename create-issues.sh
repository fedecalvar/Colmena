#!/usr/bin/env bash
# Crea en GitHub los labels, hitos (milestones) e issues del roadmap de Colmena.
#
# Uso:
#   ./create-issues.sh             # crea todo en el repo del directorio actual
#   DRY_RUN=1 ./create-issues.sh   # muestra qué crearía, sin tocar GitHub
#
# Requisitos: gh instalado y autenticado (gh auth login), y el repo con remoto en GitHub.
# Es idempotente: si un label, hito o issue (por título) ya existe, lo saltea.
# Así se puede correr de nuevo sin duplicar nada.

set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"

if [[ "$DRY_RUN" == "1" ]]; then
  echo "== DRY RUN: no se crea nada en GitHub =="
  REPO="(dry-run)"
  TITULOS_EXISTENTES=""
  HITOS_EXISTENTES=""
else
  command -v gh >/dev/null || { echo "Falta gh: https://cli.github.com" >&2; exit 1; }
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
  echo "Repo: $REPO"
  TITULOS_EXISTENTES="$(gh issue list --repo "$REPO" --state all --limit 500 --json title -q '.[].title')"
  HITOS_EXISTENTES="$(gh api "repos/$REPO/milestones?state=all&per_page=100" -q '.[].title')"
fi

# ---------- helpers ----------

crear_label() { # nombre color descripcion
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[label] $1"
  else
    gh label create "$1" --repo "$REPO" --color "$2" --description "$3" --force >/dev/null
    echo "[label] $1"
  fi
}

crear_hito() { # titulo descripcion
  if grep -Fxq -- "$1" <<<"$HITOS_EXISTENTES"; then
    echo "[hito]  $1 (ya existe)"
  elif [[ "$DRY_RUN" == "1" ]]; then
    echo "[hito]  $1"
  else
    gh api "repos/$REPO/milestones" -f title="$1" -f description="$2" >/dev/null
    echo "[hito]  $1"
  fi
}

# crear_issue titulo hito labels  (el cuerpo se lee de stdin)
crear_issue() {
  local cuerpo
  cuerpo="$(cat)"
  if grep -Fxq -- "$1" <<<"$TITULOS_EXISTENTES"; then
    echo "  [issue] $1 (ya existe)"
  elif [[ "$DRY_RUN" == "1" ]]; then
    echo "  [issue] $1  <$3>"
  else
    gh issue create --repo "$REPO" --title "$1" --milestone "$2" --label "$3" --body "$cuerpo" >/dev/null
    echo "  [issue] $1"
  fi
}

# ---------- labels ----------

crear_label "owner:federico" "1d76db" "Lo escribe Federico; Claude guía con preguntas, no da la solución"
crear_label "owner:claude"   "8250df" "Lo escribe Claude y explica qué hizo y por qué"
crear_label "feat"           "0e8a16" "Funcionalidad nueva"
crear_label "docs"           "0075ca" "Documentación"
crear_label "chore"          "c5def5" "Infraestructura, configuración, mantenimiento"
crear_label "test"           "fbca04" "Tests"
crear_label "extra"          "ededed" "Opcional, después de v1.0.0"

# ---------- hitos ----------

M0="M0 Fundamentos"
M1="M1 Núcleo"
M2="M2 Confiabilidad"
M3="M3 Operación"
M4="M4 Panel y demo"
M5="M5 Cierre"
MX="Extras"

crear_hito "$M0" "Esqueleto del repo, entorno local, CI y primeras decisiones de diseño."
crear_hito "$M1" "Encolar, tomar y ejecutar tareas sin duplicados. Ya es presentable en el portfolio."
crear_hito "$M2" "Reintentos, dead-letter queue, recuperación de workers caídos y tareas programadas."
crear_hito "$M3" "Logs, métricas, apagado ordenado y despliegue."
crear_hito "$M4" "Panel web y demo grabada."
crear_hito "$M5" "Documentación final, difusión y release v1.0.0."
crear_hito "$MX" "Mejoras opcionales."

# ---------- M0 Fundamentos ----------
echo "$M0"

crear_issue "Esqueleto del monorepo con pnpm workspaces" "$M0" "owner:claude,chore" <<'EOF'
## Objetivo
Dejar la estructura base del monorepo descrita en CLAUDE.md.

## Criterios de aceptación
- [ ] pnpm workspaces con `apps/api`, `apps/worker` y `packages/core`
- [ ] TypeScript estricto con un `tsconfig` base compartido
- [ ] Lint y formato configurados, con scripts `lint`, `typecheck` y `test` en la raíz
- [ ] `.gitattributes` que normalice finales de línea (LF), `.gitignore` y `.nvmrc` con Node LTS
- [ ] Explicación a Federico de cada archivo de configuración
EOF

crear_issue "Docker Compose con Postgres y .env.example" "$M0" "owner:claude,chore" <<'EOF'
## Objetivo
Levantar el entorno local con un comando.

## Criterios de aceptación
- [ ] `docker-compose.yml` con Postgres (versión fija) y volumen persistente
- [ ] Healthcheck de Postgres
- [ ] `.env.example` con todas las variables necesarias y comentadas
- [ ] `docker compose up -d` deja la base lista para conectarse
EOF

crear_issue "CI con GitHub Actions: lint, typecheck y tests" "$M0" "owner:claude,chore" <<'EOF'
## Objetivo
Que ningún PR entre a `main` con lint, tipos o tests en rojo.

## Criterios de aceptación
- [ ] `.github/workflows/ci.yml` corre en cada PR y push a `main`
- [ ] Servicio de Postgres en el job para los tests de integración
- [ ] Cache de pnpm
- [ ] Protección de rama en `main` que exija el check de CI
EOF

crear_issue "Plantillas de pull request e issues" "$M0" "owner:claude,chore" <<'EOF'
## Objetivo
Que cada PR e issue tenga la misma estructura.

## Criterios de aceptación
- [ ] `.github/pull_request_template.md` con: qué cambia, por qué, cómo probarlo, `Closes #N`
- [ ] Plantillas de issue para feature y bug en `.github/ISSUE_TEMPLATE/`
EOF

crear_issue "ADR-001: PostgreSQL como cola de trabajos" "$M0" "owner:federico,docs" <<'EOF'
## Objetivo
Escribir, con tus palabras, por qué Colmena usa Postgres como cola en vez de Redis, RabbitMQ o SQS.

## Preguntas guía
- ¿Qué problema resuelve `SELECT ... FOR UPDATE SKIP LOCKED`? ¿Qué pasaría sin `SKIP LOCKED`?
- ¿Qué ganás al tener la cola en la misma base que los datos de la app? ¿Qué perdés?
- ¿A partir de qué volumen dejaría de ser una buena idea?

## Criterios de aceptación
- [ ] `docs/adr/001-postgres-como-cola.md` con contexto, decisión, alternativas y consecuencias
- [ ] Lo podés explicar en 2 minutos sin leerlo
EOF

crear_issue "README inicial con diagrama de arquitectura" "$M0" "owner:federico,docs" <<'EOF'
## Objetivo
Que alguien entienda qué es Colmena en 2 minutos.

## Criterios de aceptación
- [ ] Qué es y qué problema resuelve, en un párrafo
- [ ] Diagrama: apps → API → Postgres ← workers (Mermaid o imagen)
- [ ] Quickstart en un comando (aunque todavía haga poco)
- [ ] Estado del proyecto y link al roadmap
EOF

# ---------- M1 Núcleo ----------
echo "$M1"

crear_issue "Modelo de datos y migraciones de la tabla jobs" "$M1" "owner:federico,feat" <<'EOF'
## Objetivo
Diseñar la tabla `jobs` y su primera migración.

## Antes de empezar
Elegir la herramienta de migraciones / query builder: Claude propone 2 opciones con pros y contras, vos elegís y lo registrás en un ADR.

## Preguntas guía
- ¿Qué estados puede tener una tarea y qué transiciones son válidas?
- ¿Qué consulta va a correr miles de veces por minuto? ¿Qué índice la hace rápida?
- ¿`payload` como `jsonb` o `text`? ¿Por qué?

## Criterios de aceptación
- [ ] Migración que crea `jobs` (id, tipo, payload, estado, intentos, run_at, locked_at, error, timestamps)
- [ ] Índice para tomar la próxima tarea pendiente
- [ ] ADR con la elección de la herramienta
EOF

crear_issue "Función enqueue() en packages/core" "$M1" "owner:federico,feat" <<'EOF'
## Objetivo
Encolar una tarea desde código.

## Preguntas guía
- ¿Qué valida `enqueue()` antes de insertar?
- ¿Qué devuelve? ¿Qué necesita quien la llama?

## Criterios de aceptación
- [ ] `enqueue(tipo, payload, opciones?)` inserta una tarea `pendiente` y devuelve su id
- [ ] Tests contra Postgres real
EOF

crear_issue "Tomar la próxima tarea con FOR UPDATE SKIP LOCKED" "$M1" "owner:federico,feat" <<'EOF'
## Objetivo
Que varios workers tomen tareas distintas a la vez sin pisarse.

## Preguntas guía
- ¿Por qué el `SELECT` y el `UPDATE` tienen que estar en la misma transacción?
- ¿Qué pasa si dos workers ejecutan la consulta en el mismo milisegundo?
- ¿Qué orden usás para elegir la próxima tarea?

## Criterios de aceptación
- [ ] `claim()` marca la tarea `en curso`, setea `locked_at` y la devuelve (o nada si no hay)
- [ ] Tests con dos conexiones concurrentes
EOF

crear_issue "Loop del worker" "$M1" "owner:federico,feat" <<'EOF'
## Objetivo
Proceso que toma tareas, las ejecuta y registra el resultado.

## Preguntas guía
- ¿Qué hace el worker cuando no hay tareas? ¿Cada cuánto vuelve a mirar?
- Si el handler tira una excepción, ¿qué estado queda en la base?

## Criterios de aceptación
- [ ] Loop claim → ejecutar → marcar `completada` o `fallida` con el error
- [ ] Espera configurable cuando la cola está vacía
EOF

crear_issue "Registro de handlers por tipo de tarea" "$M1" "owner:claude,feat" <<'EOF'
## Objetivo
Asociar cada `tipo` de tarea con la función que la ejecuta.

## Criterios de aceptación
- [ ] API para registrar handlers tipados por payload
- [ ] Error claro si llega una tarea sin handler registrado
- [ ] Tests y explicación a Federico
EOF

crear_issue "API HTTP: POST /jobs y GET /jobs/:id" "$M1" "owner:claude,feat" <<'EOF'
## Objetivo
Que otras apps encolen y consulten tareas por HTTP.

## Antes de empezar
Elegir framework HTTP: Claude propone 2 opciones, Federico elige y queda en un ADR.

## Criterios de aceptación
- [ ] `POST /jobs` valida el body y devuelve `201` con el id
- [ ] `GET /jobs/:id` devuelve estado, intentos y error; `404` si no existe
- [ ] Tests de integración
EOF

crear_issue "Test de integración: workers en paralelo sin duplicados" "$M1" "owner:claude,test" <<'EOF'
## Objetivo
Probar la garantía central de Colmena.

## Criterios de aceptación
- [ ] Encola N tareas, corre varios workers en paralelo y verifica que cada tarea se ejecutó exactamente una vez
- [ ] Corre en CI contra Postgres real
EOF

# ---------- M2 Confiabilidad ----------
echo "$M2"

crear_issue "Reintentos con backoff exponencial" "$M2" "owner:federico,feat" <<'EOF'
## Preguntas guía
- ¿Por qué exponencial y no un intervalo fijo? ¿Para qué sirve agregar jitter?
- ¿Dónde guardás cuándo toca el próximo intento?

## Criterios de aceptación
- [ ] Máximo de intentos configurable por tipo de tarea
- [ ] El próximo intento se agenda con backoff exponencial
- [ ] Test que reproduce fallas sucesivas
EOF

crear_issue "Dead-letter queue" "$M2" "owner:federico,feat" <<'EOF'
## Preguntas guía
- ¿Tabla aparte o un estado más en `jobs`? ¿Qué implica cada opción?
- ¿Cómo se reencola manualmente una tarea muerta?

## Criterios de aceptación
- [ ] Al agotar los intentos, la tarea pasa a la DLQ con su último error
- [ ] Forma de reencolarla
- [ ] Test
EOF

crear_issue "Recuperar tareas de workers caídos (heartbeat o visibility timeout)" "$M2" "owner:federico,feat" <<'EOF'
## Preguntas guía
- Si un worker muere a mitad de una tarea, ¿cómo se entera el sistema?
- Heartbeat vs visibility timeout: ¿qué cuesta cada uno?
- ¿Qué pasa si el worker no estaba muerto, solo lento?

## Criterios de aceptación
- [ ] Una tarea `en curso` de un worker muerto vuelve a estar disponible
- [ ] Test que mata un worker a mitad de una tarea
- [ ] ADR con la estrategia elegida
EOF

crear_issue "Tareas programadas con run_at" "$M2" "owner:federico,feat" <<'EOF'
## Criterios de aceptación
- [ ] `enqueue()` acepta `run_at`; la tarea no se toma antes de esa fecha
- [ ] El índice sigue sirviendo para la consulta de claim
- [ ] Test
EOF

crear_issue "Idempotency keys al encolar" "$M2" "owner:claude,feat" <<'EOF'
## Objetivo
Que encolar dos veces la misma operación no cree dos tareas.

## Criterios de aceptación
- [ ] `POST /jobs` y `enqueue()` aceptan una clave de idempotencia
- [ ] Si la clave ya existe, se devuelve la tarea original
- [ ] Tests, incluyendo dos requests concurrentes con la misma clave
EOF

crear_issue "Tests de fallas y caos" "$M2" "owner:claude,test" <<'EOF'
## Criterios de aceptación
- [ ] Matar workers en medio de tareas: ninguna se pierde ni se duplica
- [ ] Cortar la conexión a Postgres y verificar que el worker se recupera
- [ ] Cada escenario documentado: qué se rompe y qué se espera
EOF

# ---------- M3 Operación ----------
echo "$M3"

crear_issue "Logs estructurados en JSON" "$M3" "owner:claude,feat" <<'EOF'
## Criterios de aceptación
- [ ] Logs JSON en API y worker, con id y tipo de tarea en cada línea relevante
- [ ] Nivel de log configurable por variable de entorno
EOF

crear_issue "Métricas con Prometheus y Grafana" "$M3" "owner:claude,feat" <<'EOF'
## Criterios de aceptación
- [ ] Endpoint `/metrics`: tareas por estado, duración, reintentos, tamaño de la cola
- [ ] Prometheus y Grafana en Docker Compose con un dashboard versionado
EOF

crear_issue "Apagado ordenado y health checks" "$M3" "owner:federico,feat" <<'EOF'
## Preguntas guía
- Al recibir SIGTERM, ¿qué hace el worker con la tarea que está ejecutando?
- ¿Qué diferencia hay entre liveness y readiness?

## Criterios de aceptación
- [ ] El worker termina la tarea en curso (con un límite de tiempo) y no toma nuevas
- [ ] Endpoints de health en la API
EOF

crear_issue "Despliegue en VPS con CI/CD" "$M3" "owner:federico,chore" <<'EOF'
## Criterios de aceptación
- [ ] Colmena corriendo en un VPS, accesible por HTTPS
- [ ] Deploy automático al crear un tag de versión
- [ ] Secretos fuera del repo
EOF

# ---------- M4 Panel y demo ----------
echo "$M4"

crear_issue "Boceto de las 3 pantallas del panel" "$M4" "owner:federico,docs" <<'EOF'
## Criterios de aceptación
- [ ] Boceto de resumen, lista de tareas y detalle de una tarea
- [ ] Qué datos muestra cada pantalla y de qué endpoint salen
EOF

crear_issue "Panel web: resumen, lista y detalle" "$M4" "owner:claude,feat" <<'EOF'
## Criterios de aceptación
- [ ] `apps/panel` implementa los bocetos
- [ ] Filtros por estado y tipo; reencolar desde la DLQ
EOF

crear_issue "App de ejemplo y GIF de demo" "$M4" "owner:federico,docs" <<'EOF'
## Criterios de aceptación
- [ ] App chica que usa Colmena para un caso real (por ejemplo, envío de emails)
- [ ] GIF en el README: encolar, ver workers procesando, matar uno, ver la recuperación
EOF

# ---------- M5 Cierre ----------
echo "$M5"

crear_issue "Documentación OpenAPI" "$M5" "owner:claude,docs" <<'EOF'
## Criterios de aceptación
- [ ] `docs/openapi.yaml` completo y validado
- [ ] Revisado por Federico contra la API real
EOF

crear_issue "Post técnico sobre Colmena" "$M5" "owner:federico,docs" <<'EOF'
## Criterios de aceptación
- [ ] Post sobre el problema, las decisiones (con links a los ADR) y lo que aprendiste
- [ ] Publicado y enlazado desde el README
EOF

crear_issue "Actualizar portfolio y CV (con versión en inglés)" "$M5" "owner:federico,docs" <<'EOF'
## Criterios de aceptación
- [ ] Colmena en el portfolio con descripción, stack y links
- [ ] CV actualizado en español e inglés
EOF

crear_issue "Release v1.0.0" "$M5" "owner:federico,chore" <<'EOF'
## Criterios de aceptación
- [ ] CHANGELOG completo
- [ ] Tag `v1.0.0` y release en GitHub con notas
EOF

# ---------- Extras ----------
echo "$MX"

crear_issue "API keys por cliente" "$MX" "extra,feat" <<'EOF'
Autenticación de las apps que encolan tareas.
EOF

crear_issue "Límite de tasa por cliente" "$MX" "extra,feat" <<'EOF'
Evitar que un cliente sature la cola.
EOF

crear_issue "SDK cliente en TypeScript" "$MX" "extra,feat" <<'EOF'
Paquete para encolar y consultar tareas sin armar requests HTTP a mano.
EOF

echo "Listo."
