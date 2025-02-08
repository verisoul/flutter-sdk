#!/bin/bash

DIR_DART="lib/src/generated"
DIR_IOS="ios/Classes/Generated"
DIR_ANDROID="android/src/main/kotlin/ai/verisoul/verisoul_sdk/generated"
PKG_ANDROID="ai.verisoul.verisoul_sdk.generated"

mkdir -p $DIR_DART
mkdir -p $DIR_IOS
mkdir -p $DIR_ANDROID

generate_pigeon() {
  name_file=$1
  name_snake=$(basename $name_file .api.dart)
  name_pascal=$(echo "$name_snake" | perl -pe 's/(^|_)./uc($&)/ge;s/_//g')

  dart run pigeon \
      --input "pigeons/$name_snake.api.dart" \
      --dart_out "$DIR_DART/$name_snake.api.g.dart" \
      --swift_out "$DIR_IOS/${name_pascal}Pigeon.swift" \
      --kotlin_out "$DIR_ANDROID/${name_pascal}Pigeon.kt" \
      --kotlin_package $PKG_ANDROID || exit 1;

  echo "Generated $name_snake pigeon"

#  # Generated files are not formatted by default,
#  # this affects pacakge score.
  dart format "$DIR_DART/$name_snake.api.g.dart"
}

for file in pigeons/**
do
  generate_pigeon $file
done