from setuptools import setup, find_packages

setup(
    name="python_bridge",
    version="0.1.0",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    install_requires=[
        "nats-py>=2.3.0",
        "pydantic>=2.5.0",
        "loguru>=0.7.1",
        "fastapi>=0.110.0",
        "uvicorn>=0.24.0",
        "requests>=2.31.0",
        "smolagents>=1.13.0.dev0",
        # Other AI dependencies will be installed from requirements.txt
    ],
    python_requires=">=3.10",
    description="Python Bridge Agent for MCP with AI capabilities",
    author="MCP Team",
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.10",
    ],
)