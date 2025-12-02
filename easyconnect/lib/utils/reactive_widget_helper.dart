import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Helper pour créer des widgets réactifs optimisés qui ne reconstruisent
/// que la partie nécessaire au lieu de tout le widget parent

/// Widget réactif ciblé qui ne reconstruit que son contenu
/// Utilise Obx de manière optimale pour éviter les rebuilds inutiles
class ReactiveWidget<T> extends StatelessWidget {
  final Widget Function(T value) builder;
  final Rxn<T> observable;

  const ReactiveWidget({
    super.key,
    required this.builder,
    required this.observable,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => builder(observable.value as T));
  }
}

/// Widget réactif pour les listes - ne reconstruit que la liste, pas le parent
class ReactiveList<T> extends StatelessWidget {
  final RxList<T> list;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final RxBool? isLoading;

  const ReactiveList({
    super.key,
    required this.list,
    required this.itemBuilder,
    this.emptyBuilder,
    this.loadingBuilder,
    this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    // Obx ciblé uniquement sur la liste
    return Obx(() {
      // Si loading, afficher le loader
      if (isLoading?.value == true && loadingBuilder != null) {
        return loadingBuilder!(context);
      }

      // Si liste vide, afficher le message vide
      if (list.isEmpty && emptyBuilder != null) {
        return emptyBuilder!(context);
      }

      // Construire la liste
      return ListView.builder(
        itemCount: list.length,
        itemBuilder:
            (context, index) => itemBuilder(context, list[index], index),
      );
    });
  }
}

/// Widget réactif pour un seul booléen - très léger
class ReactiveBool extends StatelessWidget {
  final RxBool observable;
  final Widget Function(bool value) builder;

  const ReactiveBool({
    super.key,
    required this.observable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => builder(observable.value));
  }
}

/// Widget réactif pour un entier - très léger
class ReactiveInt extends StatelessWidget {
  final RxInt observable;
  final Widget Function(int value) builder;

  const ReactiveInt({
    super.key,
    required this.observable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => builder(observable.value));
  }
}

/// Widget réactif pour une chaîne - très léger
class ReactiveString extends StatelessWidget {
  final RxString observable;
  final Widget Function(String value) builder;

  const ReactiveString({
    super.key,
    required this.observable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => builder(observable.value));
  }
}

/// Widget conditionnel réactif - ne reconstruit que quand la condition change
class ReactiveConditional extends StatelessWidget {
  final RxBool condition;
  final Widget trueWidget;
  final Widget falseWidget;

  const ReactiveConditional({
    super.key,
    required this.condition,
    required this.trueWidget,
    required this.falseWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => condition.value ? trueWidget : falseWidget);
  }
}

/// Widget qui combine plusieurs observables de manière optimisée
/// Ne reconstruit que si l'un des observables change
class ReactiveCombined extends StatelessWidget {
  final List<RxInterface> observables;
  final Widget Function() builder;

  const ReactiveCombined({
    super.key,
    required this.observables,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Accéder à toutes les valeurs pour déclencher la réactivité
      for (final obs in observables) {
        // Accès pour déclencher l'observation selon le type
        // Utiliser dynamic pour contourner le problème de type narrowing avec RxInterface
        final obsDynamic = obs as dynamic;
        if (obs is RxBool ||
            obs is RxInt ||
            obs is RxString ||
            obs is RxDouble ||
            obs is Rxn) {
          obsDynamic.value; // Accéder à value via dynamic
        } else if (obs is RxList) {
          obsDynamic.length; // Accéder à length via dynamic
        }
      }
      return builder();
    });
  }
}

/// Widget partiel réactif - pour éviter les Obx imbriqués
/// Utilise GetBuilder pour les parties statiques et Obx pour les parties dynamiques
class PartialReactiveWidget extends StatelessWidget {
  final Widget staticPart;
  final Widget Function() dynamicPartBuilder;
  final RxInterface observable;

  const PartialReactiveWidget({
    super.key,
    required this.staticPart,
    required this.dynamicPartBuilder,
    required this.observable,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Partie statique - ne se reconstruit jamais
        staticPart,
        // Partie dynamique - se reconstruit uniquement quand observable change
        Obx(() {
          // Accéder à l'observable pour déclencher la réactivité
          // Utiliser dynamic pour contourner le problème de type narrowing avec RxInterface
          final obs = observable as dynamic;
          if (observable is RxBool ||
              observable is RxInt ||
              observable is RxString ||
              observable is RxDouble ||
              observable is Rxn) {
            obs.value; // Accéder à value via dynamic
          } else if (observable is RxList) {
            obs.length; // Accéder à length via dynamic
          }
          return dynamicPartBuilder();
        }),
      ],
    );
  }
}

/// Helper pour créer des widgets de liste optimisés
/// Sépare la partie statique (en-tête, filtres) de la partie dynamique (liste)
class OptimizedListWidget extends StatelessWidget {
  final Widget? header;
  final Widget? filters;
  final RxList items;
  final Widget Function(BuildContext, dynamic, int) itemBuilder;
  final RxBool? isLoading;
  final Widget? emptyWidget;
  final Widget? loadingWidget;

  const OptimizedListWidget({
    super.key,
    this.header,
    this.filters,
    required this.items,
    required this.itemBuilder,
    this.isLoading,
    this.emptyWidget,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // En-tête statique - ne se reconstruit jamais
        if (header != null) header!,
        // Filtres statiques - ne se reconstruit jamais
        if (filters != null) filters!,
        // Liste réactive - se reconstruit uniquement quand items change
        Expanded(
          child: Obx(() {
            // Vérifier le loading
            if (isLoading?.value == true && loadingWidget != null) {
              return loadingWidget!;
            }

            // Vérifier si vide
            if (items.isEmpty && emptyWidget != null) {
              return emptyWidget!;
            }

            // Construire la liste
            return ListView.builder(
              itemCount: items.length,
              itemBuilder:
                  (context, index) => itemBuilder(context, items[index], index),
            );
          }),
        ),
      ],
    );
  }
}
