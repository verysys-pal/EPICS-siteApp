# Project Structure

## Top-Level Organization
This follows standard EPICS application structure with clear separation of concerns:

```
├── configure/          # Build configuration and dependencies
├── USB1608G_2AO_cppApp/ # Main application directory
├── db/                 # Database templates (top-level copies)
├── dbd/                # Database definitions
├── iocBoot/            # IOC boot configurations
├── bin/                # Compiled executables
└── lib/                # Compiled libraries
```

## Application Directory (`USB1608G_2AO_cppApp/`)
- **src/**: C++ source code, drivers, and SNL programs
- **Db/**: Database templates and substitution files
- **op/**: Operator interface files (MEDM .adl screens)

## Key File Types and Conventions

### Source Code (`src/`)
- `*Main.cpp`: IOC main entry point
- `drv*.cpp`: Device driver implementations
- `*.st`: State Notation Language programs
- `*.dbd`: Database definition fragments
- `Makefile`: Build configuration for the application

### Database Files (`Db/` and `db/`)
- `*.template`: EPICS record templates with macro substitution
- `*.substitutions`: Macro substitution files for template instantiation
- `*_settings.req`: Autosave request files for persistent settings
- `*.db`: Static database files
- `*.proto`: Protocol files for stream device support

### Boot Configuration (`iocBoot/ioc*/`)
- `st.cmd`: Startup command script
- `envPaths`: Environment variable definitions
- `save_restore.cmd`: Autosave/restore configuration
- `auto_settings.req`: Autosave request file
- `autosave/`: Directory for saved settings files

### Build System (`configure/`)
- `RELEASE`: External module dependencies and paths
- `CONFIG*`: Build configuration files
- `RULES*`: Build rule definitions

## Naming Conventions
- **IOC Name**: `USB1608G_2AO_cpp` (device model + language suffix)
- **Port Name**: `USB1608G_2AO_cpp_PORT` (IOC name + _PORT suffix)
- **PV Prefix**: `USB1608G_2AO_cpp:` (IOC name + colon)
- **Record Names**: Follow pattern `$(P)$(R)` where P=prefix, R=record suffix
- **Template Macros**: Use descriptive names like `PORT`, `ADDR`, `SCAN`, `PREC`

## Architecture Patterns
- **Asyn Driver Model**: All device communication through asyn port drivers
- **Template-Based Records**: Parameterized database templates for reusability
- **Modular Design**: Separate drivers for different device functions
- **Standard EPICS IOC**: Follows canonical EPICS application structure