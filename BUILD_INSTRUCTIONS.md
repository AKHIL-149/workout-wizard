# Build Instructions

## Generating Hive Type Adapters

After cloning this repository or adding new Hive models, you need to generate the TypeAdapter files:

```bash
cd fitness_frontend
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate `.g.dart` files for all Hive models, including:
- workout_program.g.dart
- deload_settings.g.dart
- And other model adapters

## Note

The `.g.dart` files are generated code and need to be created before the app will compile successfully.
