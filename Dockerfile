# Use a lightweight Python base image
FROM python:3.10-slim

# Set the working directory in the container
WORKDIR /app

# Copy all files to the container
COPY . .

# Upgrade pip and install Python dependencies
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Expose the port Hugging Face Spaces expects (default: 7860)
EXPOSE 7860

# Command to run the app using gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:7860", "app:app"]
