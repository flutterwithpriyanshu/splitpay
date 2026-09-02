/// One minimal "who pays whom" instruction produced by [simplifyDebts].
class SimplifiedDebt {
  final String fromUid; // this person pays...
  final String toUid; // ...this person
  final double amount;

  const SimplifiedDebt({
    required this.fromUid,
    required this.toUid,
    required this.amount,
  });
}

/// Turns a messy web of "who owes whom how much" into the smallest possible
/// set of payments that settles everyone up — the same idea as Splitwise's
/// "simplify group debts".
///
/// [netBalanceByUid] : uid -> net balance. Positive = this person is owed
/// money overall, negative = this person owes money overall, ~0 = settled.
///
/// Greedy approach: repeatedly match whoever owes the most against whoever
/// is owed the most, settle the smaller of the two amounts, and repeat.
/// This always produces at most (numberOfPeople - 1) payments, which is the
/// minimum possible in the general case.
List<SimplifiedDebt> simplifyDebts(Map<String, double> netBalanceByUid) {
  const epsilon = 0.01; // ignore sub-paisa noise from double math

  final creditors = <MapEntry<String, double>>[]; // owed money (positive)
  final debtors = <MapEntry<String, double>>[]; // owe money (positive amount)

  netBalanceByUid.forEach((uid, balance) {
    if (balance > epsilon) {
      creditors.add(MapEntry(uid, balance));
    } else if (balance < -epsilon) {
      debtors.add(MapEntry(uid, -balance));
    }
  });

  // Largest amounts first keeps the number of resulting transactions small.
  creditors.sort((a, b) => b.value.compareTo(a.value));
  debtors.sort((a, b) => b.value.compareTo(a.value));

  final result = <SimplifiedDebt>[];
  int ci = 0, di = 0;
  var creditorsMutable = creditors.map((e) => MapEntry(e.key, e.value)).toList();
  var debtorsMutable = debtors.map((e) => MapEntry(e.key, e.value)).toList();

  while (ci < creditorsMutable.length && di < debtorsMutable.length) {
    final creditor = creditorsMutable[ci];
    final debtor = debtorsMutable[di];
    final settleAmount = creditor.value < debtor.value
        ? creditor.value
        : debtor.value;

    if (settleAmount > epsilon) {
      result.add(
        SimplifiedDebt(
          fromUid: debtor.key,
          toUid: creditor.key,
          amount: double.parse(settleAmount.toStringAsFixed(2)),
        ),
      );
    }

    creditorsMutable[ci] = MapEntry(creditor.key, creditor.value - settleAmount);
    debtorsMutable[di] = MapEntry(debtor.key, debtor.value - settleAmount);

    if (creditorsMutable[ci].value <= epsilon) ci++;
    if (debtorsMutable[di].value <= epsilon) di++;
  }

  return result;
}
