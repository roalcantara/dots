# Lua Development Tools

This directory contains a multi-stage Dockerfile that builds both **Busted** (Lua testing framework) and **Selene** (Lua linter) in Alpine Linux for lightweight, fast development tools.

## Multi-Stage Build

The `Dockerfile` creates several stages:

### Build Stages

- `selene-builder` - Builds Selene with all features
- `selene-light-builder` - Builds Selene without default features (smaller)
- `busted-builder` - Builds Busted testing framework

### Final Stages

- `busted` - Lightweight image with only Busted
- `selene` - Lightweight image with only Selene
- `selene-light` - Lightweight image with only Selene Light
- `lua-tools` - Combined image with both Busted and Selene

## Usage

### Using Mise (Recommended)

```bash
# Build specific images
mise run build-busted      # Build Busted image
mise run build-selene      # Build Selene image
mise run build-selene-light # Build Selene Light image
mise run build-tools       # Build combined image

# Run tests with new multi-stage build
mise run test-new

# Run linting
mise run lint              # Full Selene
mise run lint-light        # Lightweight Selene

# Interactive shell with both tools
mise run tools-shell

# Run with built images
mise run run-busted
mise run run-selene
mise run run-selene-light
mise run run-tools
```

### Using Docker Compose

```bash
# Run tests
docker-compose -f tools/docker-compose.yml run --rm test

# Run linting
docker-compose -f tools/docker-compose.yml run --rm lint
docker-compose -f tools/docker-compose.yml run --rm lint-light

# Interactive shell
docker-compose -f tools/docker-compose.yml run --rm tools
```

### Using Docker Directly

```bash
# Build specific targets
docker build -f tools/Dockerfile --target busted -t lua-busted .
docker build -f tools/Dockerfile --target selene -t lua-selene .
docker build -f tools/Dockerfile --target selene-light -t lua-selene-light .
docker build -f tools/Dockerfile --target lua-tools -t lua-tools .

# Run Busted tests
docker run --rm -v $(pwd)/tests:/app/tests -v $(pwd)/lua:/app/lua lua-busted --output=TAP tests/*.lua

# Run Selene linting
docker run --rm -v $(pwd)/lua:/app/lua lua-selene /app/lua

# Interactive shell
docker run --rm -it -v $(pwd)/tests:/app/tests -v $(pwd)/lua:/app/lua lua-tools
```

## Image Sizes

The multi-stage build creates very lightweight images:

- `busted`: ~15MB
- `selene`: ~8MB
- `selene-light`: ~6MB
- `lua-tools`: ~20MB

## Configuration

### Busted Configuration

Create a `busted.lua` file in your project root:

```lua
return {
  output = "TAP",
  verbose = true,
  tests = "tests/",
  lua_path = "./lua/?.lua;./lua/?/init.lua;;",
}
```

### Selene Configuration

Create a `selene.toml` file in your project root:

```toml
std = "lua54"

[globals]
"vim" = "read"
"Snacks" = "read"

[lint]
unused_variable = "disable"
```

## Examples

### Running Tests

```bash
# Run all tests
mise run test-new

# Run specific test file
docker run --rm -v $(pwd)/tests:/app/tests -v $(pwd)/lua:/app/lua lua-busted tests/test_specific.lua
```

### Running Linting

```bash
# Lint entire lua directory
mise run lint

# Lint specific file
docker run --rm -v $(pwd)/lua:/app/lua lua-selene /app/lua/specific_file.lua
```

### Interactive Development

```bash
# Get a shell with both tools available
mise run tools-shell

# Inside the container:
busted --verbose tests/
selene /app/lua
```

## Benefits

1. **Lightweight**: Alpine-based images are much smaller than Ubuntu
2. **Fast**: Multi-stage builds cache dependencies efficiently
3. **Flexible**: Choose the exact tools you need
4. **Consistent**: Same environment across all developers
5. **Isolated**: No need to install Lua tools locally

## Troubleshooting

### Build Issues

If you encounter build issues with Selene:

```bash
# Try with a different Rust version
docker build -f tools/Dockerfile --build-arg RUST_VERSION=1.74 --target selene -t lua-selene .
```

### Permission Issues

```bash
# Make sure volumes are properly mounted
docker run --rm -v $(pwd):/app lua-tools ls -la /app
```

### Test Failures

```bash
# Run with verbose output
docker run --rm -v $(pwd)/tests:/app/tests -v $(pwd)/lua:/app/lua lua-busted --verbose --output=plain tests/
```
