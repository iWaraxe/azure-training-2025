# Multi-stage build for smaller, more secure container
FROM python:3.11-slim AS builder

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir --user -r requirements.txt

# Runtime stage
FROM python:3.11-slim

# Create non-root user for security
RUN groupadd -r marsapp && useradd -r -g marsapp marsapp

# Set working directory
WORKDIR /app

# Copy Python dependencies from builder stage
COPY --from=builder /root/.local /home/marsapp/.local

# Copy application files
COPY mars.py .
COPY mars.config .

# Create logs directory with proper permissions
RUN mkdir -p /mnt/logs && chown -R marsapp:marsapp /mnt/logs /app

# Add local bin to PATH for marsapp user
ENV PATH=/home/marsapp/.local/bin:$PATH

# Switch to non-root user
USER marsapp

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:5000/health')" || exit 1

# Expose port
EXPOSE 5000

# Set environment variables
ENV FLASK_APP=mars.py
ENV FLASK_ENV=production
ENV PYTHONUNBUFFERED=1

# Run the application
ENTRYPOINT ["python", "mars.py"]