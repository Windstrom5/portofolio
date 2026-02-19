import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'hud_components.dart';
import 'crt_overlay.dart';

enum HoldemPhase {
  idle,
  preflop,
  flop,
  turn,
  river,
  showdown,
}

class Card {
  final int value;
  final String suit;

  Card(String s)
      : value = _parseValue(s.substring(0, s.length - 1)),
        suit = s[s.length - 1];

  static int _parseValue(String r) {
    if (r == 'A') return 14;
    if (r == 'K') return 13;
    if (r == 'Q') return 12;
    if (r == 'J') return 11;
    if (r == '10') return 10;
    return int.parse(r);
  }

  @override
  String toString() => '$value$suit'; // For debugging
}

class PokerGame extends StatefulWidget {
  final void Function(String text, {String? english, String? emotion}) onSpeak;
  const PokerGame({super.key, required this.onSpeak});

  @override
  State<PokerGame> createState() => _PokerGameState();
}

class _PokerGameState extends State<PokerGame> {
  final Random _random = Random();

  static const List<String> suits = ['♠', '♥', '♦', '♣'];
  static const List<String> ranks = [
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    'J',
    'Q',
    'K',
    'A'
  ];

  List<String> deck = [];
  List<String> playerHand = [];
  List<String> opponentHand = [];
  List<String> communityCards = [];

  int playerChips = 1000;
  int opponentChips = 1000;
  int pot = 0;
  int currentBet = 0;
  int playerBet = 0;
  int opponentBet = 0;
  int smallBlind = 25;
  int bigBlind = 50;

  bool playerIsButton = true;
  HoldemPhase phase = HoldemPhase.idle;
  String status = "Welcome to Texas Hold'em!";

  bool playerTurn = true;
  bool showOpponentCards = false;

  bool playerActedThisRound = false;
  bool opponentActedThisRound = false;
  int numRaisesThisRound = 0;
  static const int maxRaises = 4;

  final List<GlobalKey> communityKeys = [];
  final GlobalKey playerHandKey = GlobalKey();
  final GlobalKey opponentHandKey = GlobalKey();

  // Sakura reactions
  final List<String> dealComments = [
    "ポーカー始めよ～！ カード配るね♡",
    "えへへ、ドキドキする～！ ご主人様、がんばって！",
    "ふふっ、Sakura強いよ～？ 負けないからねっ♡",
  ];

  final List<String> raiseComments = [
    "ここ raise よ～！ どう？♡",
    "えへへ、bet up～！ ご主人様の番だよ～",
    "ふふっ、強い手かも～？  raise！",
  ];

  final List<String> callComments = [
    "call するよ～♡",
    "ふふっ、OK～！ 次行こっ",
    "えへへ、call！ ドキドキ～",
  ];

  final List<String> checkComments = [
    "check だよ～♡",
    "ふふっ、check！ ご主人様どうぞ～",
  ];

  final List<String> foldComments = [
    "うぅ～ fold… ご主人様勝っちゃった♡",
    "くぅ～ 次は勝つよぉ～！",
  ];

  final List<String> winComments = [
    "やったー！ Sakuraの勝ち～！✨",
    "えへへ～ ご主人様に勝っちゃった♡",
    "キャー！ 嬉しいよぉ～！",
  ];

  final List<String> loseComments = [
    "うぅ～… 負けちゃった…💦",
    "ご主人様強すぎるよぉ～♡",
    "次は絶対勝つからねっ！",
  ];

  final List<String> splitComments = [
    "split pot だよ～！ ふふっ、平等ね♡",
    "あいこ～！ また遊ぼう～",
  ];

  final Map<HoldemPhase, List<String>> phaseComments = {
    HoldemPhase.flop: [
      "flop きたよ～！ どうかな♡",
      "えへへ、board オープン～！",
    ],
    HoldemPhase.turn: [
      "turn だよ～♡ ドキドキ～",
      "ふふっ、次の一枚～！",
    ],
    HoldemPhase.river: [
      "river よ～！ 最終だね♡",
      "えへへ、これで決まるよ～！",
    ],
  };

  @override
  void initState() {
    super.initState();
    _buildDeck();
    for (int i = 0; i < 5; i++) {
      communityKeys.add(GlobalKey());
    }
  }

  void _buildDeck() {
    deck.clear();
    for (var s in suits) {
      for (var r in ranks) {
        deck.add('$r$s');
      }
    }
    deck.shuffle(_random);
  }

  void _safeSpeak(String japanese, {String? english, String? emotion}) {
    widget.onSpeak(japanese, english: english, emotion: emotion);
  }

  void _deal() {
    _buildDeck();
    setState(() {
      pot = 0;
      communityCards.clear();
      playerHand.clear();
      opponentHand.clear();
      playerBet = 0;
      opponentBet = 0;
      currentBet = 0;
      playerActedThisRound = false;
      opponentActedThisRound = false;
      numRaisesThisRound = 0;
      showOpponentCards = false;
      playerIsButton = !playerIsButton;

      if (playerIsButton) {
        playerChips -= smallBlind;
        opponentChips -= bigBlind;
        playerBet = smallBlind;
        opponentBet = bigBlind;
        playerTurn = true;
      } else {
        opponentChips -= smallBlind;
        playerChips -= bigBlind;
        opponentBet = smallBlind;
        playerBet = bigBlind;
        playerTurn = false;
      }

      pot = smallBlind + bigBlind;
      currentBet = bigBlind;
      playerHand = [deck.removeLast(), deck.removeLast()];
      opponentHand = [deck.removeLast(), deck.removeLast()];
      phase = HoldemPhase.preflop;
      status = "Pre-Flop!";
    });

    int idx = _random.nextInt(dealComments.length);
    _safeSpeak(dealComments[idx],
        english: [
          "Let's start Poker~! Dealing cards♡",
          "Ehehe, so exciting~! Do your best, Master!",
          "Fufu, Sakura is strong~? I won't lose~♡",
        ][idx],
        emotion: "fun");

    if (!playerTurn) _opponentAction();
  }

  void _playerBet(int amount) {
    if (numRaisesThisRound >= maxRaises) return;
    int toPay = amount;
    if (playerChips < toPay) return;
    setState(() {
      playerChips -= toPay;
      playerBet += toPay;
      pot += toPay;
      currentBet = playerBet;
      status = "You raised to $currentBet";
      numRaisesThisRound++;
      playerActedThisRound = true;
    });
    _safeSpeak("強気だね！ Sakuraも負けないよ♡",
        english: "Aggressive! Sakura won't lose either~♡", emotion: "fun");
    playerTurn = false;
    _opponentAction();
  }

  void _playerCall() {
    int toCall = currentBet - playerBet;
    int callAmt = min(toCall, playerChips);
    setState(() {
      playerChips -= callAmt;
      playerBet += callAmt;
      pot += callAmt;
      status = "You called $callAmt";
      playerActedThisRound = true;
    });
    _safeSpeak("コールだね、受けて立つよ！",
        english: "A call? I accept the challenge~!", emotion: "neutral");
    playerTurn = false;
    if (opponentActedThisRound && playerBet == opponentBet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nextPhase();
      });
    } else {
      _opponentAction();
    }
  }

  void _playerCheck() {
    setState(() {
      status = "You checked.";
      playerActedThisRound = true;
    });
    _safeSpeak("チェック？ 様子見かな♡",
        english: "Check? Just testing the waters?♡", emotion: "fun");
    playerTurn = false;
    if (opponentActedThisRound && playerBet == opponentBet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nextPhase();
      });
    } else {
      _opponentAction();
    }
  }

  void _playerFold() {
    setState(() {
      opponentChips += pot;
      pot = 0;
      phase = HoldemPhase.idle;
      status = "You folded. Sakura wins the pot!";
    });
    _safeSpeak("ご主人様 fold したの？ Sakuraの勝ち～♡",
        english: "You folded? Sakura wins~♡", emotion: "joy");
  }

  double _calculateImpliedOdds(int toCall) {
    if (toCall == 0) return 1.0;
    int potentialWin = pot + min(playerChips, opponentChips);
    return toCall / potentialWin.toDouble();
  }

  double _evaluateDrawPotential(List<String> hand, List<String> board) {
    if (board.isEmpty) return 0.0;
    List<Card> allCards = parseCards([...hand, ...board]);
    double drawBonus = 0.0;
    Map<String, int> suitCount = {};
    for (var card in allCards) {
      suitCount[card.suit] = (suitCount[card.suit] ?? 0) + 1;
    }
    if (suitCount.values.any((count) => count == 4)) drawBonus += 0.35;
    List<int> values = allCards.map((c) => c.value).toSet().toList()..sort();
    int consecutiveCount = 1;
    int maxConsecutive = 1;
    for (int i = 1; i < values.length; i++) {
      if (values[i] - values[i - 1] == 1) {
        consecutiveCount++;
        maxConsecutive = max(maxConsecutive, consecutiveCount);
      } else if (values[i] - values[i - 1] == 2) {
        drawBonus += 0.1;
        consecutiveCount = 1;
      } else {
        consecutiveCount = 1;
      }
    }
    if (maxConsecutive >= 4) drawBonus += 0.25;
    return drawBonus.clamp(0.0, 0.4);
  }

  double _getPositionBonus() => playerIsButton ? -0.05 : 0.1;

  bool _shouldBluff(double strength, int toCall) {
    if (communityCards.isEmpty) return _random.nextDouble() < 0.12;
    List<Card> boardCards = parseCards(communityCards);
    int highCardCount = boardCards.where((c) => c.value >= 10).length;
    bool scaryBoard = highCardCount >= 2;
    double drawPotential = _evaluateDrawPotential(opponentHand, communityCards);
    double bluffProbability = 0.08;
    if (scaryBoard) bluffProbability += 0.1;
    if (drawPotential > 0.2) bluffProbability += 0.15;
    if (toCall == 0) bluffProbability += 0.1;
    return _random.nextDouble() < bluffProbability;
  }

  void _opponentAction() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted ||
          phase == HoldemPhase.idle ||
          phase == HoldemPhase.showdown) return;
      int toCall = currentBet - opponentBet;
      double strength;
      double drawBonus = 0.0;

      if (phase == HoldemPhase.preflop) {
        strength = _preflopStrength(opponentHand);
      } else {
        var (rank, tiebreakers, _) = _getBestHand(opponentHand, communityCards);
        strength = rank / 9.0;
        if (rank <= 2 && tiebreakers.isNotEmpty)
          strength += (tiebreakers[0] / 14.0) * 0.15;
        if (rank < 4) {
          drawBonus = _evaluateDrawPotential(opponentHand, communityCards);
          if (phase == HoldemPhase.flop)
            drawBonus *= 1.0;
          else if (phase == HoldemPhase.turn)
            drawBonus *= 0.6;
          else
            drawBonus *= 0.2;
        }
      }

      double positionBonus = _getPositionBonus();
      double potOdds = toCall > 0 ? toCall / (pot + toCall).toDouble() : 0.0;
      double impliedOdds = _calculateImpliedOdds(toCall);
      double effectiveStrength =
          (strength + drawBonus + positionBonus).clamp(0.0, 1.0);
      double adjustedStrength =
          effectiveStrength - (_random.nextDouble() * 0.05);

      String comment = "";
      bool shouldFold = toCall > 0 &&
          adjustedStrength < (potOdds - 0.05) &&
          (drawBonus < 0.2 || adjustedStrength < impliedOdds * 0.8) &&
          _random.nextDouble() < 0.75;

      if (shouldFold) {
        playerChips += pot;
        pot = 0;
        phase = HoldemPhase.idle;
        status = "Sakura folds. You win the pot!";
        comment = foldComments[_random.nextInt(foldComments.length)];
      } else {
        bool willRaise = numRaisesThisRound < maxRaises &&
            (adjustedStrength > 0.45 || _shouldBluff(strength, toCall)) &&
            opponentChips >= bigBlind * 2;
        if (willRaise) {
          int minRaise = max(toCall, bigBlind * 2);
          double sizingFactor = (adjustedStrength > 0.7)
              ? (0.7 + _random.nextDouble() * 0.3)
              : (adjustedStrength > 0.5
                  ? 0.5 + _random.nextDouble() * 0.2
                  : 0.6 + _random.nextDouble() * 0.25);
          int targetRaise = (pot * sizingFactor).toInt();
          int raiseAmt = targetRaise.clamp(minRaise, opponentChips);
          opponentChips -= raiseAmt;
          opponentBet += raiseAmt;
          pot += raiseAmt;
          currentBet = opponentBet;
          status = "Sakura raises to $currentBet!";
          comment = raiseComments[_random.nextInt(raiseComments.length)];
          numRaisesThisRound++;
          opponentActedThisRound = true;
          playerTurn = true;
        } else {
          int callAmt = min(toCall, opponentChips);
          opponentChips -= callAmt;
          opponentBet += callAmt;
          pot += callAmt;
          opponentActedThisRound = true;
          if (toCall == 0) {
            status = "Sakura checks.";
            comment = checkComments[_random.nextInt(checkComments.length)];
          } else {
            status = "Sakura calls $toCall.";
            comment = callComments[_random.nextInt(callComments.length)];
          }
          if (mounted) setState(() {});
          if (playerActedThisRound && opponentBet == currentBet) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _nextPhase();
            });
          } else {
            playerTurn = true;
          }
        }
      }

      if (mounted) setState(() {});
      if (comment.isNotEmpty) {
        String? eng;
        if (raiseComments.contains(comment)) {
          int i = raiseComments.indexOf(comment);
          eng = [
            "I'm raising here~! How about that?♡",
            "Ehehe, bet up~! Your turn, Master",
            "Fufu, maybe a strong hand~? Raise!"
          ][i];
        } else if (callComments.contains(comment)) {
          int i = callComments.indexOf(comment);
          eng = [
            "I'll call~♡",
            "Fufu, OK~! Let's go next",
            "Ehehe, call! So exciting~"
          ][i];
        } else if (checkComments.contains(comment)) {
          int i = checkComments.indexOf(comment);
          eng = ["Check~♡", "Fufu, check! Your turn, Master~"][i];
        } else if (foldComments.contains(comment)) {
          int i = foldComments.indexOf(comment);
          eng = ["Uuu~ fold... You won♡", "Kuu~ I'll win next time~!"][i];
        }

        String emo = "neutral";
        if (raiseComments.contains(comment)) emo = "fun";
        if (foldComments.contains(comment)) emo = "sorrow";
        if (winComments.contains(comment)) emo = "joy";

        _safeSpeak(comment, english: eng, emotion: emo);
      }
    });
  }

  double _preflopStrength(List<String> hand) {
    Card c1 = Card(hand[0]);
    Card c2 = Card(hand[1]);
    bool suited = c1.suit == c2.suit;
    int high = max(c1.value, c2.value);
    int low = min(c1.value, c2.value);
    int gap = high - low;
    double score = (high == low)
        ? (high / 14.0) * 0.8 + 0.2
        : (high / 14.0) * 0.5 + (low / 14.0) * 0.3;
    if (suited) score += 0.2;
    if (gap <= 2) score += 0.15;
    return score.clamp(0.0, 1.0);
  }

  void _nextPhase() {
    if (!mounted) return;
    setState(() {
      playerBet = 0;
      opponentBet = 0;
      currentBet = 0;
      playerActedThisRound = false;
      opponentActedThisRound = false;
      numRaisesThisRound = 0;
    });

    String? phaseComment;
    if (phase == HoldemPhase.preflop) {
      communityCards
          .addAll([deck.removeLast(), deck.removeLast(), deck.removeLast()]);
      phase = HoldemPhase.flop;
      status = "Flop!";
      phaseComment = phaseComments[HoldemPhase.flop]
          ?[_random.nextInt(phaseComments[HoldemPhase.flop]!.length)];
    } else if (phase == HoldemPhase.flop) {
      communityCards.add(deck.removeLast());
      phase = HoldemPhase.turn;
      status = "Turn!";
      phaseComment = phaseComments[HoldemPhase.turn]
          ?[_random.nextInt(phaseComments[HoldemPhase.turn]!.length)];
    } else if (phase == HoldemPhase.turn) {
      communityCards.add(deck.removeLast());
      phase = HoldemPhase.river;
      status = "River!";
      phaseComment = phaseComments[HoldemPhase.river]
          ?[_random.nextInt(phaseComments[HoldemPhase.river]!.length)];
    } else if (phase == HoldemPhase.river) {
      phase = HoldemPhase.showdown;
      _showdown();
      return;
    }

    setState(() {
      playerTurn = !playerIsButton;
    });

    if (phaseComment != null) {
      String? eng;
      if (phaseComments[HoldemPhase.flop]!.contains(phaseComment)) {
        eng = phaseComment == phaseComments[HoldemPhase.flop]![0]
            ? "Flop is here~! How is it?♡"
            : "Ehehe, board revealed~!";
      } else if (phaseComments[HoldemPhase.turn]!.contains(phaseComment)) {
        eng = phaseComment == phaseComments[HoldemPhase.turn]![0]
            ? "It's the turn~♡ So exciting~"
            : "Fufu, next card~!";
      } else if (phaseComments[HoldemPhase.river]!.contains(phaseComment)) {
        eng = phaseComment == phaseComments[HoldemPhase.river]![0]
            ? "It's the river~! Last one♡"
            : "Ehehe, this will decide it~!";
      }
      _safeSpeak(phaseComment, english: eng, emotion: "fun");
    }
    if (!playerTurn) _opponentAction();
  }

  List<List<Card>> _combinations(List<Card> items, int k,
      [int start = 0, List<Card> current = const []]) {
    List<List<Card>> result = [];
    if (current.length == k) {
      result.add(List.from(current));
      return result;
    }
    for (int i = start; i < items.length; i++) {
      result.addAll(_combinations(items, k, i + 1, [...current, items[i]]));
    }
    return result;
  }

  (int, List<int>) _evaluate5(List<Card> five) {
    five.sort((a, b) => b.value - a.value);
    List<int> values = five.map((c) => c.value).toList();
    Set<String> suitsSet = five.map((c) => c.suit).toSet();
    bool isFlush = suitsSet.length == 1;
    bool isStraight = _isStraight(values);
    Map<int, int> freq = {};
    for (var v in values) freq[v] = (freq[v] ?? 0) + 1;
    int fourVal = freq.entries
        .firstWhere((e) => e.value == 4, orElse: () => const MapEntry(0, 0))
        .key;
    int threeVal = freq.entries
        .firstWhere((e) => e.value == 3, orElse: () => const MapEntry(0, 0))
        .key;
    List<int> pairVals = freq.keys.where((k) => freq[k] == 2).toList()
      ..sort((a, b) => b - a);

    if (isStraight && isFlush) {
      if (values[0] == 14 &&
          values[1] == 13 &&
          values[2] == 12 &&
          values[3] == 11 &&
          values[4] == 10) return (9, []);
      return (8, [values[0]]);
    }
    if (fourVal > 0)
      return (7, [fourVal, values.firstWhere((v) => v != fourVal)]);
    if (threeVal > 0 && pairVals.isNotEmpty)
      return (6, [threeVal, pairVals[0]]);
    if (isFlush) return (5, values);
    if (isStraight)
      return (4, [(values[0] == 14 && values[4] == 2) ? 5 : values[0]]);
    if (threeVal > 0)
      return (3, [threeVal, ...values.where((v) => v != threeVal)]);
    if (pairVals.length >= 2)
      return (
        2,
        [pairVals[0], pairVals[1], values.firstWhere((v) => freq[v] == 1)]
      );
    if (pairVals.length == 1)
      return (1, [pairVals[0], ...values.where((v) => v != pairVals[0])]);
    return (0, values);
  }

  bool _isStraight(List<int> values) {
    Set<int> vs = values.toSet();
    if (vs.length != 5) return false;
    if (values[0] - values[4] == 4) return true;
    if (vs.containsAll({14, 5, 4, 3, 2})) return true;
    return false;
  }

  (int, List<int>, List<Card>) _getBestHand(
      List<String> hole, List<String> board) {
    List<Card> allCards = parseCards([...hole, ...board]);
    List<List<Card>> combos = _combinations(allCards, 5);
    int bestRank = -1;
    List<int> bestTie = [];
    List<Card> bestFive = [];
    for (var combo in combos) {
      var (rank, tie) = _evaluate5(combo);
      if (rank > bestRank ||
          (rank == bestRank && _compareTies(tie, bestTie) > 0)) {
        bestRank = rank;
        bestTie = tie;
        bestFive = combo;
      }
    }
    return (bestRank, bestTie, bestFive);
  }

  int _compareTies(List<int> a, List<int> b) {
    int len = min(a.length, b.length);
    for (int i = 0; i < len; i++) {
      if (a[i] > b[i]) return 1;
      if (a[i] < b[i]) return -1;
    }
    return 0;
  }

  List<Card> parseCards(List<String> strs) => strs.map(Card.new).toList();

  void _showdown() {
    if (!mounted) return;
    setState(() {
      showOpponentCards = true;
    });
    var (pRank, pTie, _) = _getBestHand(playerHand, communityCards);
    var (oRank, oTie, _) = _getBestHand(opponentHand, communityCards);
    int res =
        (pRank != oRank) ? (pRank > oRank ? 1 : -1) : _compareTies(pTie, oTie);
    String resultText = "";
    if (res > 0) {
      playerChips += pot;
      resultText = "You win the pot!";
      _safeSpeak(loseComments[_random.nextInt(loseComments.length)],
          english: "Master, you're too strong~♡", emotion: "sorrow");
    } else if (res < 0) {
      opponentChips += pot;
      resultText = "Sakura wins the pot!";
      _safeSpeak(winComments[_random.nextInt(winComments.length)],
          english: "Yatta~! Sakura won!✨", emotion: "joy");
    } else {
      playerChips += pot ~/ 2;
      opponentChips += pot ~/ 2;
      resultText = "Split pot!";
      _safeSpeak(splitComments[_random.nextInt(splitComments.length)],
          english: "Split pot! Fufu, we're equal♡", emotion: "fun");
    }
    setState(() {
      pot = 0;
      status = "Showdown! $resultText";
      phase = HoldemPhase.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1200.w),
        child: CrtOverlay(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF0A2E1F), // Dark felt green center
                  const Color(0xFF051109), // Deeper green/black edge
                ],
                center: Alignment.center,
                radius: 1.2,
              ),
              borderRadius: BorderRadius.circular(160.r), // Oval table feel
              border: Border.all(
                  color: const Color(0xFF3D2B1F), // Wooden trim color
                  width: 8.w),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5),
              ],
            ),
            child: ClipRRect(
              child: HUDContainer(
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 10.h),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          width: 1000
                              .w, // Keep width to maintain aspect ratio/layout
                          // Removed height constraint to allow Column to take needed space
                          padding: EdgeInsets.symmetric(vertical: 20.h),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.min, // Hug content
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildHUDStat("SAKURA CHIPS",
                                      "\$$opponentChips", Colors.pinkAccent),
                                  Column(
                                    children: [
                                      Text("TEXAS HOLD'EM",
                                          style: GoogleFonts.orbitron(
                                              color: Colors.cyanAccent,
                                              fontSize: 24.sp,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 4)),
                                      Text(
                                          phase == HoldemPhase.idle
                                              ? "WAITING FOR DEAL"
                                              : phase.name.toUpperCase(),
                                          style: GoogleFonts.vt323(
                                              color: Colors.white54,
                                              fontSize: 16.sp)),
                                    ],
                                  ),
                                  _buildHUDStat("PLAYER CHIPS",
                                      "\$$playerChips", Colors.cyanAccent),
                                ],
                              ),
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (int i = 0;
                                          i < opponentHand.length;
                                          i++)
                                        _buildCard(opponentHand[i],
                                            isFaceUp: showOpponentCards,
                                            isOpponent: true),
                                    ],
                                  ),
                                  SizedBox(height: 10.h),
                                  if (!playerIsButton &&
                                      phase != HoldemPhase.idle)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Text("D",
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.sp)),
                                    ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text("POT: \$$pot",
                                      style: GoogleFonts.vt323(
                                          color: Colors.yellowAccent,
                                          fontSize: 32.sp)),
                                  SizedBox(height: 20.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (int i = 0; i < 5; i++)
                                        _buildCard(
                                            i < communityCards.length
                                                ? communityCards[i]
                                                : "",
                                            isFaceUp: i < communityCards.length,
                                            isCommunity: true,
                                            key: communityKeys[i]),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  if (playerIsButton &&
                                      phase != HoldemPhase.idle)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Text("D",
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.sp)),
                                    ),
                                  SizedBox(height: 10.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    key: playerHandKey,
                                    children: [
                                      for (int i = 0;
                                          i < playerHand.length;
                                          i++)
                                        _buildCard(playerHand[i],
                                            isFaceUp: true),
                                    ],
                                  ),
                                  SizedBox(height: 30.h),
                                  Container(
                                    height: 80.h,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 20.w),
                                    decoration: BoxDecoration(
                                        color: Colors.black38,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.white10, width: 1)),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (phase == HoldemPhase.idle)
                                          _buildGameButton("DEAL HAND", _deal,
                                              Colors.cyanAccent)
                                        else ...[
                                          if (playerTurn) ...[
                                            _buildGameButton("FOLD",
                                                _playerFold, Colors.redAccent),
                                            SizedBox(width: 10.w),
                                            if (currentBet > playerBet)
                                              _buildGameButton(
                                                  "CALL (\$${currentBet - playerBet})",
                                                  _playerCall,
                                                  Colors.orangeAccent)
                                            else
                                              _buildGameButton(
                                                  "CHECK",
                                                  _playerCheck,
                                                  Colors.greenAccent),
                                            SizedBox(width: 10.w),
                                            if (numRaisesThisRound < maxRaises)
                                              _buildGameButton(
                                                  "RAISE",
                                                  () => _playerBet(bigBlind),
                                                  Colors.purpleAccent),
                                          ] else
                                            Text("SAKURA IS THINKING...",
                                                style: GoogleFonts.vt323(
                                                    color: Colors.pinkAccent,
                                                    fontSize: 24.sp)),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHUDStat(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.1), blurRadius: 10, spreadRadius: 1)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.orbitron(
                  color: color.withOpacity(0.8),
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 4.h),
          Text(value,
              style: GoogleFonts.vt323(
                  color: Colors.white,
                  fontSize: 20.sp,
                  shadows: [
                    Shadow(color: color.withOpacity(0.5), blurRadius: 5)
                  ])),
        ],
      ),
    );
  }

  Widget _buildGameButton(String label, VoidCallback? onPressed, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.5), width: 2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1)
              ]),
          child: Text(label,
              style: GoogleFonts.orbitron(
                  color: color, fontSize: 14.sp, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildCard(String card,
      {bool isFaceUp = true,
      bool isOpponent = false,
      bool isCommunity = false,
      Key? key}) {
    if (card.isEmpty && isFaceUp) {
      return Container(
          key: key,
          width: 80.w,
          height: 120.h,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10, width: 2)));
    }
    if (!isFaceUp) {
      return Container(
          width: 85.w,
          height: 125.h,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                  color: Colors.cyanAccent.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(5, 5),
                ),
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.2),
                  blurRadius: 2,
                  spreadRadius: 1,
                ),
              ]),
          child: Stack(
            children: [
              // Grid pattern on back
              Positioned.fill(
                child: CustomPaint(
                  painter:
                      CardPatternPainter(Colors.cyanAccent.withOpacity(0.1)),
                ),
              ),
              Center(
                  child: Icon(Icons.bolt,
                      size: 40.sp, color: Colors.cyanAccent.withOpacity(0.5))),
            ],
          ));
    }
    String rank = card.substring(0, card.length - 1);
    String suit = card[card.length - 1];
    Color suitColor = (suit == '♥' || suit == '♦') ? Colors.red : Colors.black;
    return Container(
        key: key,
        width: 85.w,
        height: 125.h,
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: suitColor.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(4, 6),
              ),
              if (isCommunity)
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.3),
                  blurRadius: 15,
                )
            ]),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Stack(children: [
              Positioned.fill(
                  child: Opacity(
                      opacity: 0.05,
                      child:
                          CustomPaint(painter: CardPatternPainter(suitColor)))),
              Positioned(
                  top: 5.h,
                  left: 5.w,
                  child: Column(children: [
                    Text(rank,
                        style: TextStyle(
                            color: suitColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp)),
                    Text(suit,
                        style: TextStyle(color: suitColor, fontSize: 16.sp))
                  ])),
              Center(
                  child: Text(suit,
                      style: TextStyle(color: suitColor, fontSize: 32.sp))),
              Positioned(
                  bottom: 5.h,
                  right: 5.w,
                  child: Transform.rotate(
                      angle: pi,
                      child: Column(children: [
                        Text(rank,
                            style: TextStyle(
                                color: suitColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp)),
                        Text(suit,
                            style: TextStyle(color: suitColor, fontSize: 16.sp))
                      ])))
            ])));
  }
}

class CardPatternPainter extends CustomPainter {
  final Color color;
  CardPatternPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;
    for (double i = 0; i < size.width; i += 10) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
