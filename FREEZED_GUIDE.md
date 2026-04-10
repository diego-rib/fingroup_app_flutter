# Guia Prático de Freezed — aprenda usando este projeto

Freezed é um gerador de código que cria automaticamente:
- `copyWith()` para copiar objetos imutáveis com campos alterados
- `==` e `hashCode` para comparação de igualdade profunda
- `toString()` legível para debug
- `fromJson` / `toJson` (se usar json_serializable junto)
- Sealed classes (union types) para modelar estados

---

## Por que usamos Freezed?

O Flutter docs diz: **"strongly recommend immutable data models; recommend freezed"**.

Sem Freezed, para ter imutabilidade você precisaria escrever manualmente:
```dart
// Sem Freezed — muito boilerplate:
class Expense {
  final String id;
  final double amount;
  
  const Expense({required this.id, required this.amount});
  
  Expense copyWith({String? id, double? amount}) => Expense(
    id: id ?? this.id,
    amount: amount ?? this.amount,
  );
  
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Expense && runtimeType == other.runtimeType &&
    id == other.id && amount == other.amount;
  
  @override
  int get hashCode => id.hashCode ^ amount.hashCode;
  
  @override
  String toString() => 'Expense(id: $id, amount: $amount)';
}
```

Com Freezed, você escreve apenas:
```dart
@freezed
class Expense with _$Expense {
  const factory Expense({
    required String id,
    required double amount,
  }) = _Expense;
}
```
E o gerador cria todo o resto.

---

## Como usar no projeto

### 1. Criar um arquivo novo com Freezed

Crie `lib/domain/entities/meu_modelo.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

// Estas duas linhas são OBRIGATÓRIAS — dizem ao Freezed onde gerar o código
part 'meu_modelo.freezed.dart';       // será gerado
part 'meu_modelo.g.dart';             // gerado pelo json_serializable (só se usar fromJson)

@freezed
class MeuModelo with _$MeuModelo {
  const factory MeuModelo({
    required String id,
    required String nome,
    double? valorOpcional,       // campos opcionais usam ?
    @Default(0) int contador,    // @Default define valor padrão
  }) = _MeuModelo;

  // Se quiser fromJson:
  factory MeuModelo.fromJson(Map<String, dynamic> json) =>
      _$MeuModeloFromJson(json);
}
```

### 2. Rodar o gerador

```bash
dart run build_runner build --delete-conflicting-outputs
```

Em modo watch (recompila ao salvar):
```bash
dart run build_runner watch --delete-conflicting-outputs
```

### 3. Usar copyWith

```dart
final despesa = Expense(id: '1', amount: 50.0, categoryId: 'cat1', ...);

// Cria uma NOVA instância com amount alterado — original intocado
final despesaAtualizada = despesa.copyWith(amount: 75.0);
```

### 4. Comparação de igualdade

```dart
final a = Expense(id: '1', amount: 50.0, ...);
final b = Expense(id: '1', amount: 50.0, ...);

print(a == b); // true — Freezed implementou == por você
```

---

## Sealed classes com Freezed (union types)

Usamos isso no `AuthResult` do domínio (mas com sealed nativo do Dart 3).
Com Freezed você pode fazer o mesmo de forma mais avançada:

```dart
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.idle() = _Idle;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.success(User user) = _Success;
  const factory AuthState.failure(String message) = _Failure;
}

// Uso com pattern matching:
switch (state) {
  case _Idle() => Text('Toque para começar'),
  case _Loading() => CircularProgressIndicator(),
  case _Success(:final user) => Text('Olá, ${user.displayName}'),
  case _Failure(:final message) => Text(message, style: errorStyle),
}
```

---

## Arquivos gerados — não edite!

O Freezed gera arquivos `.freezed.dart` e `.g.dart`. Eles são **ignorados pelo git**
(adicione ao `.gitignore`) e **nunca devem ser editados manualmente**.

Adicione ao `.gitignore`:
```
*.freezed.dart
*.g.dart
```

---

## Entidades deste projeto que usam Freezed

| Arquivo | O que aprende |
|---|---|
| `domain/entities/expense.dart` | Modelo simples com `@Default` |
| `domain/entities/category.dart` | Getter customizado (budgetLimit) |
| `domain/entities/recurring_expense.dart` | Lógica derivada, enums, getters |

Comece lendo esses arquivos e depois rode `build_runner` para ver o que é gerado.
