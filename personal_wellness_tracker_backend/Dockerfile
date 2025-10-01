# Use Python 3.11 slim image for better performance
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy all files first to check what exists
COPY . .

# Install Python dependencies based on what files exist
RUN if [ -f pyproject.toml ]; then \
        echo "Installing with Poetry..." && \
        pip install poetry && \
        poetry config virtualenvs.create false && \
        poetry install --only=main; \
    elif [ -f requirements.txt ]; then \
        echo "Installing with requirements.txt..." && \
        pip install --no-cache-dir -r requirements.txt; \
    else \
        echo "Installing FastAPI dependencies manually..." && \
        pip install --no-cache-dir \
            fastapi \
            uvicorn[standard] \
            sqlalchemy \
            psycopg2-binary \
            alembic \
            pydantic \
            python-jose[cryptography] \
            passlib[bcrypt] \
            python-multipart \
            python-dotenv; \
    fi

# Create non-root user for security (but keep as root for now to avoid permission issues)
# RUN groupadd -r appuser && useradd -r -g appuser appuser
# RUN chown -R appuser:appuser /app
# USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || curl -f http://localhost:8000/ || exit 1

# Set environment variables
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Run the application
CMD ["uvicorn", "personal_wellness_tracker_backend.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
