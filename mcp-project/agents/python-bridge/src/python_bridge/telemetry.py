"""
Telemetry integration for the Python Bridge Agent.

This module provides OpenTelemetry integration for monitoring and
debugging the Python Bridge Agent in production.
"""

import os
from contextlib import contextmanager
from typing import Dict, Any, Optional, Generator

from loguru import logger

# Only import OpenTelemetry if it's available
try:
    from opentelemetry import trace
    from opentelemetry.sdk.trace import TracerProvider
    from opentelemetry.sdk.trace.export import BatchSpanProcessor
    from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
    from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator
    from openinference.instrumentation.smolagents import SmolagentsInstrumentor
    _has_opentelemetry = True
except ImportError:
    _has_opentelemetry = False


class TelemetryManager:
    """Manager for OpenTelemetry integration."""
    
    def __init__(self):
        """Initialize the telemetry manager."""
        self.enabled = False
        self.tracer = None
    
    def setup(self, 
              endpoint: Optional[str] = None, 
              headers: Optional[Dict[str, str]] = None) -> bool:
        """
        Set up OpenTelemetry tracing.
        
        Args:
            endpoint: OTLP endpoint URL (default: from OTEL_EXPORTER_OTLP_ENDPOINT)
            headers: Headers for the OTLP exporter (default: from OTEL_EXPORTER_OTLP_HEADERS)
            
        Returns:
            True if setup was successful, False otherwise
        """
        if not _has_opentelemetry:
            logger.warning("OpenTelemetry not available. Install with 'pip install smolagents[telemetry]'")
            return False
        
        try:
            # Configure tracer provider
            trace_provider = TracerProvider()
            
            # Configure exporter
            endpoint = endpoint or os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT")
            headers = headers or {}
            
            if "OTEL_EXPORTER_OTLP_HEADERS" in os.environ:
                header_string = os.environ.get("OTEL_EXPORTER_OTLP_HEADERS", "")
                for item in header_string.split(","):
                    if "=" in item:
                        key, value = item.split("=", 1)
                        headers[key.strip()] = value.strip()
            
            # Only set up if endpoint is configured
            if endpoint:
                logger.info(f"Setting up OpenTelemetry with endpoint: {endpoint}")
                exporter = OTLPSpanExporter(endpoint=endpoint, headers=headers)
                trace_provider.add_span_processor(BatchSpanProcessor(exporter))
                
                # Set up global tracer provider
                trace.set_tracer_provider(trace_provider)
                
                # Initialize the smolagents instrumentation
                SmolagentsInstrumentor().instrument(tracer_provider=trace_provider)
                
                # Get a tracer for this component
                self.tracer = trace.get_tracer("python_bridge")
                self.enabled = True
                logger.info("OpenTelemetry setup complete")
                return True
            else:
                logger.warning("No OpenTelemetry endpoint configured")
                return False
                
        except Exception as e:
            logger.error(f"Failed to set up OpenTelemetry: {str(e)}")
            return False
    
    @contextmanager
    def span(self, name: str, attributes: Optional[Dict[str, Any]] = None) -> Generator:
        """
        Create a span for the given operation.
        
        Args:
            name: Name of the span
            attributes: Attributes to add to the span
            
        Yields:
            Span context
        """
        if not self.enabled or not _has_opentelemetry:
            yield None
            return
        
        attributes = attributes or {}
        
        with self.tracer.start_as_current_span(name) as span:
            # Set span attributes
            for key, value in attributes.items():
                span.set_attribute(key, value)
            
            try:
                yield span
            except Exception as e:
                # Record exception in span
                span.record_exception(e)
                span.set_status(trace.Status(trace.StatusCode.ERROR, str(e)))
                raise
    
    def add_event(self, name: str, attributes: Optional[Dict[str, Any]] = None) -> None:
        """
        Add an event to the current span.
        
        Args:
            name: Name of the event
            attributes: Attributes to add to the event
        """
        if not self.enabled or not _has_opentelemetry:
            return
        
        attributes = attributes or {}
        current_span = trace.get_current_span()
        current_span.add_event(name, attributes)
    
    def set_attribute(self, key: str, value: Any) -> None:
        """
        Set an attribute on the current span.
        
        Args:
            key: Attribute key
            value: Attribute value
        """
        if not self.enabled or not _has_opentelemetry:
            return
        
        current_span = trace.get_current_span()
        current_span.set_attribute(key, value)
    
    def record_exception(self, exception: Exception) -> None:
        """
        Record an exception in the current span.
        
        Args:
            exception: Exception to record
        """
        if not self.enabled or not _has_opentelemetry:
            return
        
        current_span = trace.get_current_span()
        current_span.record_exception(exception)
        current_span.set_status(trace.Status(trace.StatusCode.ERROR, str(exception)))


# Create a singleton telemetry manager
telemetry = TelemetryManager()