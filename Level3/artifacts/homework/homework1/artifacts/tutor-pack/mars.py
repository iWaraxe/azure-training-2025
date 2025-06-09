#!/usr/bin/env python3
"""
MARS Application - Modern Flask application for Kubernetes training
Tracks visits with Redis backend and provides health monitoring
"""

from flask import Flask, jsonify, request
from redis import Redis, RedisError
import os
import sys
import logging
import configparser
from datetime import datetime
import json

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/mnt/logs/info.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Load configuration
config = configparser.ConfigParser()
config_path = os.environ.get('CONFIG_PATH', 'mars.config')

try:
    config.read(config_path)
    logger.info(f"Configuration loaded from {config_path}")
except Exception as e:
    logger.error(f"Failed to load config: {e}")
    sys.exit(1)

# Initialize Flask app
app = Flask(__name__)

# Redis connection with retry logic
def get_redis_client():
    """Get Redis client with connection validation"""
    try:
        redis_host = os.environ.get('REDIS_HOST', config.get("config", "redis_address", fallback="localhost"))
        redis_port = int(os.environ.get('REDIS_PORT', config.get("config", "redis_port", fallback="6379")))
        
        redis_client = Redis(
            host=redis_host, 
            port=redis_port,
            decode_responses=True,
            socket_connect_timeout=5,
            socket_timeout=5,
            retry_on_timeout=True
        )
        
        # Test connection
        redis_client.ping()
        logger.info(f"Connected to Redis at {redis_host}:{redis_port}")
        return redis_client
    except Exception as e:
        logger.error(f"Redis connection failed: {e}")
        return None

redis_client = get_redis_client()

@app.route('/')
def hello():
    """Main endpoint that tracks visits"""
    try:
        visit_count = "unknown"
        
        if redis_client:
            visit_count = redis_client.incr('hits')
            
        client_ip = request.environ.get('HTTP_X_FORWARDED_FOR', request.remote_addr)
        user_agent = request.headers.get('User-Agent', 'Unknown')
        
        # Log the visit
        log_data = {
            'timestamp': datetime.utcnow().isoformat(),
            'client_ip': client_ip,
            'user_agent': user_agent,
            'visit_count': visit_count
        }
        logger.info(f"Visit logged: {json.dumps(log_data)}")
        
        return f'Hello Container World! 🚀\nI have been seen {visit_count} times.\nTime: {datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")} UTC\n'
        
    except Exception as e:
        logger.error(f"Error in main route: {e}")
        return f'Hello Container World! (Error: {str(e)})\n', 500

@app.route('/health')
def health():
    """Health check endpoint for Kubernetes probes"""
    try:
        redis_status = "connected" if redis_client and redis_client.ping() else "disconnected"
        
        health_data = {
            'status': 'healthy',
            'timestamp': datetime.utcnow().isoformat(),
            'redis': redis_status,
            'version': '2.0.0'
        }
        
        if redis_status == "disconnected":
            health_data['status'] = 'degraded'
            
        return jsonify(health_data)
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return jsonify({
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }), 500

@app.route('/metrics')
def metrics():
    """Basic metrics endpoint for monitoring"""
    try:
        hit_count = redis_client.get('hits') if redis_client else 0
        
        metrics_data = {
            'mars_visits_total': int(hit_count) if hit_count else 0,
            'mars_app_info': 1,
            'mars_redis_connected': 1 if redis_client else 0
        }
        
        # Return Prometheus-style metrics
        metrics_text = []
        for key, value in metrics_data.items():
            metrics_text.append(f"{key} {value}")
            
        return '\n'.join(metrics_text) + '\n', 200, {'Content-Type': 'text/plain'}
    except Exception as e:
        logger.error(f"Metrics endpoint failed: {e}")
        return f"# Error collecting metrics: {e}\n", 500, {'Content-Type': 'text/plain'}

@app.route('/ready')
def ready():
    """Readiness probe endpoint"""
    try:
        if redis_client and redis_client.ping():
            return jsonify({'status': 'ready'}), 200
        else:
            return jsonify({'status': 'not ready', 'reason': 'redis unavailable'}), 503
    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        return jsonify({'status': 'not ready', 'reason': str(e)}), 503

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal server error: {error}")
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == "__main__":
    # Get server configuration
    server_host = os.environ.get('SERVER_HOST', config.get("config", "server_address", fallback="0.0.0.0"))
    server_port = int(os.environ.get('SERVER_PORT', config.get("config", "server_port", fallback="5000")))
    debug_mode = os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'
    
    logger.info(f"Starting MARS application on {server_host}:{server_port}")
    logger.info(f"Debug mode: {debug_mode}")
    
    app.run(
        host=server_host, 
        port=server_port, 
        debug=debug_mode,
        use_reloader=False  # Disable reloader in container
    )