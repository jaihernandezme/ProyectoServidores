# Plataforma VOD Serverless

Este repositorio contiene el código para una plataforma de Video On Demand (VOD) construida con servicios serverless de AWS.

## Estructura del Repositorio

- `analytics/`: Consultas SQL o Dashboards JSON.
- `backend/`: Código de las funciones Lambda (Node.js/Python).
  - `upload-service/`: Lambda para Presigned URLs.
  - `video-processing/`: Trigger de MediaConvert.
  - `metadata-service/`: Extracción de información y guardado en la base de datos.
  - `ai-service/`: Lambdas para Rekognition y Transcribe.
  - `search-service/`: Sincronización con OpenSearch.
- `frontend/`: Aplicación web (React/Next.js).
- `infrastructure/`: Código de Terraform o CDK para crear los recursos de AWS.
  - `modules/`: Módulos de Terraform reutilizables.
- `scripts/`: Scripts de deploy o seeding de datos.
- `tests/`: Pruebas de integración.
