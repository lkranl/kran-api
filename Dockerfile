# Use an official Ubuntu base image
FROM python:3.11-slim

# Set environment variables to avoid interactive prompts during package installation
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Update and install necessary system packages
RUN apt-get update && apt-get install -y \
    sudo \
    unixodbc \
    && rm -rf /var/lib/apt/lists/*

# Add the Microsoft ODBC driver package using ADD
ADD https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb /tmp/packages-microsoft-prod.deb

# Install the Microsoft ODBC driver
RUN dpkg -i /tmp/packages-microsoft-prod.deb && \
    rm /tmp/packages-microsoft-prod.deb && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18 && \
    apt-get clean

# Set up the Python virtual environment and install dependencies
WORKDIR /app
COPY requirements.txt .
RUN /bin/bash -c "pip install --upgrade pip && pip install -r requirements.txt"

# Copy the rest of the application code
COPY . .

# Set environment variables from build arguments
ARG DJANGO_SECRET_KEY
ARG DB_NAME
ARG DB_USER
ARG DB_PASSWORD
ARG DB_PORT
ARG DB_HOST
ARG DB_DRIVER

ENV DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY}
ENV DB_NAME=${DB_NAME}
ENV DB_USER=${DB_USER}
ENV DB_PASSWORD=${DB_PASSWORD}
ENV DB_PORT=${DB_PORT}
ENV DB_HOST=${DB_HOST}
ENV DB_DRIVER=${DB_DRIVER}

# Expose the port the app runs on
EXPOSE 8000

# Copy the entrypoint script
CMD ["bash", "-c", "python manage.py makemigrations && python manage.py migrate && python manage.py runserver 0.0.0.0:8000"]