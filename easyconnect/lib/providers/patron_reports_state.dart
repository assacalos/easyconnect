import 'package:flutter/foundation.dart';

@immutable
class PatronReportsState {
  final DateTime startDate;
  final DateTime endDate;
  final bool isLoading;
  final int devisCount;
  final double devisTotal;
  final int bordereauxCount;
  final double bordereauxTotal;
  final int facturesCount;
  final double facturesTotal;
  final int paiementsCount;
  final double paiementsTotal;
  final int depensesCount;
  final double depensesTotal;
  final int salairesCount;
  final double salairesTotal;
  final double beneficeNet;
  /// Trésorerie (sur la période) : encaissements = paiements, décaissements = dépenses + salaires
  final double encaissements;
  final double decaissements;
  final double soldeTresorerie;
  /// Âge des créances : montants par tranche (factures non soldées)
  final double receivables0_30;
  final double receivables31_60;
  final double receivables61_90;
  final double receivablesOver90;

  const PatronReportsState({
    required this.startDate,
    required this.endDate,
    this.isLoading = false,
    this.devisCount = 0,
    this.devisTotal = 0.0,
    this.bordereauxCount = 0,
    this.bordereauxTotal = 0.0,
    this.facturesCount = 0,
    this.facturesTotal = 0.0,
    this.paiementsCount = 0,
    this.paiementsTotal = 0.0,
    this.depensesCount = 0,
    this.depensesTotal = 0.0,
    this.salairesCount = 0,
    this.salairesTotal = 0.0,
    this.beneficeNet = 0.0,
    this.encaissements = 0.0,
    this.decaissements = 0.0,
    this.soldeTresorerie = 0.0,
    this.receivables0_30 = 0.0,
    this.receivables31_60 = 0.0,
    this.receivables61_90 = 0.0,
    this.receivablesOver90 = 0.0,
  });

  PatronReportsState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    bool? isLoading,
    int? devisCount,
    double? devisTotal,
    int? bordereauxCount,
    double? bordereauxTotal,
    int? facturesCount,
    double? facturesTotal,
    int? paiementsCount,
    double? paiementsTotal,
    int? depensesCount,
    double? depensesTotal,
    int? salairesCount,
    double? salairesTotal,
    double? beneficeNet,
    double? encaissements,
    double? decaissements,
    double? soldeTresorerie,
    double? receivables0_30,
    double? receivables31_60,
    double? receivables61_90,
    double? receivablesOver90,
  }) {
    return PatronReportsState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isLoading: isLoading ?? this.isLoading,
      devisCount: devisCount ?? this.devisCount,
      devisTotal: devisTotal ?? this.devisTotal,
      bordereauxCount: bordereauxCount ?? this.bordereauxCount,
      bordereauxTotal: bordereauxTotal ?? this.bordereauxTotal,
      facturesCount: facturesCount ?? this.facturesCount,
      facturesTotal: facturesTotal ?? this.facturesTotal,
      paiementsCount: paiementsCount ?? this.paiementsCount,
      paiementsTotal: paiementsTotal ?? this.paiementsTotal,
      depensesCount: depensesCount ?? this.depensesCount,
      depensesTotal: depensesTotal ?? this.depensesTotal,
      salairesCount: salairesCount ?? this.salairesCount,
      salairesTotal: salairesTotal ?? this.salairesTotal,
      beneficeNet: beneficeNet ?? this.beneficeNet,
      encaissements: encaissements ?? this.encaissements,
      decaissements: decaissements ?? this.decaissements,
      soldeTresorerie: soldeTresorerie ?? this.soldeTresorerie,
      receivables0_30: receivables0_30 ?? this.receivables0_30,
      receivables31_60: receivables31_60 ?? this.receivables31_60,
      receivables61_90: receivables61_90 ?? this.receivables61_90,
      receivablesOver90: receivablesOver90 ?? this.receivablesOver90,
    );
  }
}
