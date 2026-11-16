# Colmena

Cola de trabajos distribuida en TypeScript sobre PostgreSQL. Otras apps encolan tareas por una API y un grupo de workers las ejecuta sin duplicarlas ni perderlas, con reintentos, dead-letter queue y tareas programadas.

Es el proyecto principal del portfolio, analista de sistemas por recibirse, sin experiencia laboral, que busca su primer trabajo IT. Idioma de trabajo: español (código, commits y nombres técnicos en español).

## Regla de trabajo (la más importante)

El objetivo no es solo tener el código: Federico tiene que **entenderlo y poder defenderlo en una entrevista**.

- Los issues con label `owner:federico` (marcados "yo" en el roadmap) los escribe Federico. En esos casos NO des la solución directa. Primero preguntale cómo lo resolvería, guialo con preguntas y pistas, y revisá lo que escriba. Solo mostrá código si lo pide explícitamente después de intentarlo.
- Los issues con label `owner:claude` (marcados "claude" en el roadmap) los escribís vos (infra, boilerplate, tests, CI, borradores de docs). Al terminar, explicá qué hiciste y por qué.
- Todo módulo que escribas pasa por 4 controles antes de darse por bueno:
  1. Federico lo explica en voz alta, línea por línea.
  2. Lo rompe a propósito (mata un worker, corta la conexión) y predice qué pasa antes de correrlo.
  3. Hace un cambio chico sin ayuda (nuevo tipo de tarea, otra política de reintentos).
  4. Reescribe desde cero una función clave y la compara con la tuya.
     Si no pasa alguno, se repite ese módulo.
- Un issue por vez. No avances al siguiente sin que el anterior esté entendido y mergeado.

## Stack y decisiones por defecto

- TypeScript estricto, Node LTS, monorepo con pnpm workspaces.
- PostgreSQL como cola con `SELECT ... FOR UPDATE SKIP LOCKED` (ver ADR-001).
- Tests con una base real en Docker (no mocks para la lógica de concurrencia).
- Docker Compose para desarrollo local; GitHub Actions para CI.
- Logs estructurados en JSON; métricas con Prometheus y Grafana.
- Si hay que elegir una librería (framework HTTP, ORM o query builder, test runner), proponé 2 opciones con pros y contras y dejá que Federico elija. Registrá la decisión en un ADR.

## Estructura del repo

```
colmena/
├── README.md              # qué es, diagrama, quickstart en un comando
├── CLAUDE.md
├── docs/
│   ├── architecture.md
│   ├── adr/               # decisiones de diseño, en palabras de Federico
│   └── openapi.yaml
├── apps/
│   ├── api/               # API HTTP: encolar y consultar tareas
│   ├── worker/            # procesos que toman y ejecutan tareas
│   └── panel/             # panel web (al final, M4)
├── packages/
│   └── core/              # lógica de negocio sin dependencias de framework
├── tests/                 # unitarios + integración con Postgres real
├── .github/
│   ├── workflows/ci.yml
│   └── pull_request_template.md
├── docker-compose.yml
├── .env.example
└── CHANGELOG.md
```

## Flujo de trabajo

- Cada issue se trabaja en su rama (`feat/...`, `fix/...`, `docs/...`, `chore/...`) y entra por pull request. Nunca se commitea directo a `main`.
- Commits convencionales: `feat:`, `fix:`, `docs:`, `test:`, `chore:`. Commits chicos y con sentido.
- Un PR cierra un issue (`Closes #N`) e incluye tests y documentación si corresponde.
- Antes de mergear: lint, typecheck y tests en verde en CI.
- Versiones con tags (semver). CHANGELOG actualizado en cada release.

## Roadmap (hitos e issues)

Los issues se crean con `create-issues.sh`. Resumen:

- **M0 Fundamentos**: esqueleto del monorepo, Docker Compose + Postgres + `.env.example`, CI, plantillas de PR e issues, ADR-001 (Postgres como cola, owner:federico), README inicial con diagrama (owner:federico).
- **M1 Núcleo**: modelo de datos y migraciones (yo), `enqueue()` (yo), claim con `SKIP LOCKED` (yo), loop del worker (yo), registro de handlers (claude), API `POST /jobs` y `GET /jobs/:id` (claude), test de integración de workers en paralelo sin duplicados (claude).
- **M2 Confiabilidad**: reintentos con backoff exponencial (yo), dead-letter queue (yo), recuperación de tareas de workers caídos con heartbeat o visibility timeout (yo), tareas programadas con `run_at` (yo), idempotency keys (claude), tests de fallas y caos (claude).
- **M3 Operación**: logs estructurados (claude), métricas Prometheus/Grafana (claude), apagado ordenado y health checks (yo), despliegue en VPS con CI/CD (yo).
- **M4 Panel y demo**: boceto de 3 pantallas (yo), panel con resumen, lista y detalle (claude), app de ejemplo y GIF de demo (yo).
- **M5 Cierre**: OpenAPI (claude), post técnico (yo), actualizar portfolio y CV con versión en inglés (yo), release v1.0.0 (yo).
- **Extras** (opcional): API keys, límite de tasa por cliente, SDK cliente.

Orden: M0 → M1 → M2 → M3 → M4 → M5. El núcleo (M0 y M1) ya es presentable en el portfolio.

## Modelo de datos inicial (referencia, lo diseña Federico)

Tabla `jobs`: id, tipo, payload, estado (pendiente, en curso, completada, fallida), intentos, run_at, locked_at, error. Índices pensados para tomar la próxima tarea pendiente rápido.

## Criterios de calidad

- Un worker nunca procesa dos veces la misma tarea con workers concurrentes, y ninguna tarea se pierde si un worker muere.
- Todo comportamiento de falla (reintento, dead-letter, recuperación) tiene un test que lo reproduce.
- El README permite correr todo con un comando y entender el proyecto en 2 minutos.
- Cada decisión de diseño importante tiene un ADR corto.

## Contexto de Federico

- Último semestre de Analista de Sistemas; aporta código en su tesis (repo privado de la organización proyecto-tesis-dosing).
- Portfolio: https://fedecalvar.github.io/portfolio/ (Platita: React, TypeScript, Node, Express, Prisma, PostgreSQL; Docker y Git conocidos).
- Usa Git Bash en Windows.
