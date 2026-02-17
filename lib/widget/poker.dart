import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
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
  final void Function(String text, {String? english}) onSpeak;
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

  // Track betting state within the current street
  bool playerActedThisRound = false;
  bool opponentActedThisRound = false;
  int numRaisesThisRound = 0;
  static const int maxRaises =
      4; // Usual cap in limit hold'em, but we'll use it for logic

  // Animations
  final List<GlobalKey> communityKeys = [];
  final GlobalKey playerHandKey = GlobalKey();
  final GlobalKey opponentHandKey = GlobalKey();

  // Sakura reactions (Japanese cute style)
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

  /// Safely call onSpeak after the current frame to avoid setState during build
  void _safeSpeak(String japanese, {String? english}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onSpeak(japanese, english: english);
      }
    });
  }

  // ================= DEAL =================

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
        // Player button/small blind
        playerChips -= smallBlind;
        opponentChips -= bigBlind;
        playerBet = smallBlind;
        opponentBet = bigBlind;
        playerTurn = true; // Small acts first preflop
      } else {
        // Opponent button/small
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
    String jap = dealComments[idx];
    String eng = [
      "Let's start Poker~! Dealing cards♡",
      "Ehehe, so exciting~! Do your best, Master!",
      "Fufu, Sakura is strong~? I won't lose~♡",
    ][idx];

    _safeSpeak(jap, english: eng);

    if (!playerTurn) {
      _opponentAction();
    }
  }

  // ================= PLAYER ACTIONS =================

  void _playerBet(int amount) {
    // Standard limit raise logic or simplified NL re-raise
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

    playerTurn = false;

    // After player calls, check if betting round is complete
    if (opponentActedThisRound && playerBet == opponentBet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _nextPhase();
        }
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

    playerTurn = false;

    if (opponentActedThisRound && playerBet == opponentBet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _nextPhase();
        }
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
        english: "You folded? Sakura wins~♡");
  }

  // ================= OPPONENT AI (Smart/Hard Difficulty) =================

  /// Calculate implied odds: potential future winnings vs current call
  double _calculateImpliedOdds(int toCall) {
    if (toCall == 0) return 1.0;
    // Estimate potential winnings based on opponent's remaining chips
    int potentialWin = pot + min(playerChips, opponentChips);
    return toCall / potentialWin.toDouble();
  }

  /// Evaluate potential draws (flush/straight draws)
  double _evaluateDrawPotential(List<String> hand, List<String> board) {
    if (board.isEmpty) return 0.0;

    List<Card> allCards = parseCards([...hand, ...board]);
    double drawBonus = 0.0;

    // Check for flush draw (4 cards of same suit)
    Map<String, int> suitCount = {};
    for (var card in allCards) {
      suitCount[card.suit] = (suitCount[card.suit] ?? 0) + 1;
    }
    if (suitCount.values.any((count) => count == 4)) {
      drawBonus += 0.35; // Strong flush draw
    }

    // Check for straight draw (open-ended or gutshot)
    List<int> values = allCards.map((c) => c.value).toSet().toList()..sort();
    int consecutiveCount = 1;
    int maxConsecutive = 1;
    for (int i = 1; i < values.length; i++) {
      if (values[i] - values[i - 1] == 1) {
        consecutiveCount++;
        maxConsecutive = max(maxConsecutive, consecutiveCount);
      } else if (values[i] - values[i - 1] == 2) {
        // Gutshot potential
        drawBonus += 0.1;
        consecutiveCount = 1;
      } else {
        consecutiveCount = 1;
      }
    }
    if (maxConsecutive >= 4) {
      drawBonus += 0.25; // Open-ended straight draw
    }

    return drawBonus.clamp(0.0, 0.4);
  }

  /// Calculate position advantage
  double _getPositionBonus() {
    // Button has positional advantage postflop
    return playerIsButton ? -0.05 : 0.1;
  }

  /// Determine if AI should bluff based on board texture and history
  bool _shouldBluff(double strength, int toCall) {
    // Bluff more on scary boards (high cards, connected)
    if (communityCards.isEmpty) return _random.nextDouble() < 0.12;

    List<Card> boardCards = parseCards(communityCards);
    int highCardCount = boardCards.where((c) => c.value >= 10).length;
    bool scaryBoard = highCardCount >= 2;

    // Semi-bluff with draws
    double drawPotential = _evaluateDrawPotential(opponentHand, communityCards);

    double bluffProbability = 0.08; // Base bluff rate
    if (scaryBoard) bluffProbability += 0.1;
    if (drawPotential > 0.2) bluffProbability += 0.15; // Semi-bluff
    if (toCall == 0) bluffProbability += 0.1; // Free to bet

    return _random.nextDouble() < bluffProbability;
  }

  void _opponentAction() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted ||
          phase == HoldemPhase.idle ||
          phase == HoldemPhase.showdown) return;

      int toCall = currentBet - opponentBet;

      // Calculate hand strength based on phase
      double strength;
      double drawBonus = 0.0;

      if (phase == HoldemPhase.preflop) {
        strength = _preflopStrength(opponentHand);
      } else {
        var (rank, tiebreakers, _) = _getBestHand(opponentHand, communityCards);
        // More nuanced strength calculation
        strength = rank / 9.0;

        // Add kicker strength for made hands
        if (rank <= 2 && tiebreakers.isNotEmpty) {
          strength += (tiebreakers[0] / 14.0) * 0.15;
        }

        // Add draw potential if not already made a strong hand
        if (rank < 4) {
          drawBonus = _evaluateDrawPotential(opponentHand, communityCards);
          // More value on earlier streets for draws
          if (phase == HoldemPhase.flop)
            drawBonus *= 1.0;
          else if (phase == HoldemPhase.turn)
            drawBonus *= 0.6;
          else
            drawBonus *= 0.2; // River - draws missed
        }
      }

      // Add position bonus
      double positionBonus = _getPositionBonus();

      // Calculate pot odds and implied odds
      double potOdds = toCall > 0 ? toCall / (pot + toCall).toDouble() : 0.0;
      double impliedOdds = _calculateImpliedOdds(toCall);

      // Combine all factors
      double effectiveStrength =
          (strength + drawBonus + positionBonus).clamp(0.0, 1.0);
      double adjustedStrength =
          effectiveStrength - (_random.nextDouble() * 0.05); // Slight variance

      String comment = "";

      // Smart folding decision - use implied odds for draws
      bool shouldFold = toCall > 0 &&
          adjustedStrength < (potOdds - 0.05) &&
          (drawBonus < 0.2 ||
              adjustedStrength <
                  impliedOdds *
                      0.8) && // Don't fold good draws with implied odds
          _random.nextDouble() < 0.75;

      if (shouldFold) {
        // Fold
        playerChips += pot;
        pot = 0;
        phase = HoldemPhase.idle;
        status = "Sakura folds. You win the pot!";
        comment = foldComments[_random.nextInt(foldComments.length)];
      } else {
        // Determine bet sizing based on strength
        bool willRaise = numRaisesThisRound < maxRaises &&
            (adjustedStrength > 0.45 || _shouldBluff(strength, toCall)) &&
            opponentChips >= bigBlind * 2;

        if (willRaise) {
          // Smart bet sizing
          int minRaise = max(toCall, bigBlind * 2);
          double sizingFactor;

          if (adjustedStrength > 0.7) {
            sizingFactor = 0.7 + _random.nextDouble() * 0.3;
          } else if (adjustedStrength > 0.5) {
            sizingFactor = 0.5 + _random.nextDouble() * 0.2;
          } else {
            sizingFactor = 0.6 + _random.nextDouble() * 0.25;
          }

          int targetRaise = (pot * sizingFactor).toInt();
          int maxRaisePossible = opponentChips;
          int raiseAmt = targetRaise.clamp(minRaise, maxRaisePossible);

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
          // Call/Check
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

          // Update state first, then handle next phase after frame
          if (mounted) {
            setState(() {});
          }

          if (playerActedThisRound && opponentBet == currentBet) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _nextPhase();
              }
            });
          } else {
            playerTurn = true;
          }
        }
      }

      if (mounted) {
        setState(() {});
      }

      if (comment.isNotEmpty) {
        String? eng;
        if (raiseComments.contains(comment)) {
          int i = raiseComments.indexOf(comment);
          eng = [
            "I'm raising here~! How about that?♡",
            "Ehehe, bet up~! Your turn, Master",
            "Fufu, maybe a strong hand~? Raise!",
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
        _safeSpeak(comment, english: eng);
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

    double score = 0.0;
    if (high == low) {
      score = (high / 14.0) * 0.8 + 0.2;
    } else {
      score = (high / 14.0) * 0.5 + (low / 14.0) * 0.3;
      if (suited) score += 0.2;
      if (gap <= 2) score += 0.15;
    }
    return score.clamp(0.0, 1.0);
  }

  // ================= GAME FLOW =================

  void _nextPhase() {
    if (!mounted) return;

    // Reset betting state for the new street
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

    // Postflop first act: non-button acts first
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
      _safeSpeak(phaseComment, english: eng);
    }

    if (!playerTurn) {
      _opponentAction();
    }
  }

  // ================= HAND EVALUATION =================

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
    for (var v in values) {
      freq[v] = (freq[v] ?? 0) + 1;
    }

    int fourVal = freq.entries
        .firstWhere((e) => e.value == 4, orElse: () => MapEntry(0, 0))
        .key;
    int threeVal = freq.entries
        .firstWhere((e) => e.value == 3, orElse: () => MapEntry(0, 0))
        .key;
    List<int> pairVals = freq.keys.where((k) => freq[k] == 2).toList()
      ..sort((a, b) => b - a);

    if (isStraight && isFlush) {
      if (values[0] == 14 &&
          values[1] == 13 &&
          values[2] == 12 &&
          values[3] == 11 &&
          values[4] == 10) {
        return (9, []); // Royal Flush, no tiebreaker needed typically
      }
      return (8, [values[0]]); // Straight Flush high card
    }
    if (fourVal > 0) {
      int kicker = values.firstWhere((v) => v != fourVal);
      return (7, [fourVal, kicker]);
    }
    if (threeVal > 0 && pairVals.isNotEmpty) {
      return (6, [threeVal, pairVals[0]]);
    }
    if (isFlush) {
      return (5, values);
    }
    if (isStraight) {
      int high = (values[0] == 14 && values[4] == 2) ? 5 : values[0];
      return (4, [high]);
    }
    if (threeVal > 0) {
      List<int> kickers = values.where((v) => v != threeVal).toList();
      return (3, [threeVal, ...kickers]);
    }
    if (pairVals.length >= 2) {
      int kicker = values.firstWhere((v) => freq[v] == 1);
      return (2, [pairVals[0], pairVals[1], kicker]);
    }
    if (pairVals.length == 1) {
      List<int> kickers = values.where((v) => v != pairVals[0]).toList();
      return (1, [pairVals[0], ...kickers]);
    }
    return (0, values);
  }

  bool _isStraight(List<int> values) {
    Set<int> vs = values.toSet();
    if (vs.length != 5) return false;
    int minV = values[4], maxV = values[0];
    if (maxV - minV == 4) return true;
    // Wheel straight A-5
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
      bool better = rank > bestRank ||
          (rank == bestRank && _compareTies(tie, bestTie) > 0);
      if (better) {
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

  // ================= SHOWDOWN =================

  void _showdown() {
    if (!mounted) return;

    showOpponentCards = true;

    var (pRank, pTie, _) = _getBestHand(playerHand, communityCards);
    var (oRank, oTie, _) = _getBestHand(opponentHand, communityCards);

    String text;
    String comment;

    int compare = (pRank > oRank)
        ? 1
        : (pRank < oRank)
            ? -1
            : _compareTies(pTie, oTie);

    if (compare > 0) {
      playerChips += pot;
      text = "You win with ${_rankName(pRank)}!";
      comment = loseComments[_random.nextInt(loseComments.length)];
    } else if (compare < 0) {
      opponentChips += pot;
      text = "Sakura wins with ${_rankName(oRank)}!";
      comment = winComments[_random.nextInt(winComments.length)];
    } else {
      playerChips += pot ~/ 2;
      opponentChips += pot ~/ 2;
      text = "Split pot! Both have ${_rankName(pRank)}";
      comment = splitComments[_random.nextInt(splitComments.length)];
    }

    if (mounted) {
      setState(() {
        pot = 0;
        status = text;
      });
    }

    String? eng;
    if (winComments.contains(comment)) {
      int i = winComments.indexOf(comment);
      eng = [
        "Yay~! Sakura wins~!✨",
        "Ehehe~ I won against Master♡",
        "Kyaa~! So happy~!",
      ][i];
    } else if (loseComments.contains(comment)) {
      int i = loseComments.indexOf(comment);
      eng = [
        "Uuu~ I lost...💦",
        "Master is too strong~♡",
        "I'll definitely win next time!",
      ][i];
    } else if (splitComments.contains(comment)) {
      eng = comment == splitComments[0]
          ? "Split pot~! Fufu, it's fair♡"
          : "Tie~! Let's play again~";
    }

    _safeSpeak(comment, english: eng);
  }

  String _rankName(int rank) {
    const names = [
      'High Card',
      'One Pair',
      'Two Pair',
      'Three of a Kind',
      'Straight',
      'Flush',
      'Full House',
      'Four of a Kind',
      'Straight Flush',
      'Royal Flush'
    ];
    return names[rank];
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    int toCall = currentBet - playerBet;
    bool facingBet = playerBet < currentBet;
    bool showButtons = phase != HoldemPhase.idle &&
        phase != HoldemPhase.showdown &&
        playerTurn;

    return CrtOverlay(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 900.w, maxHeight: 600.h),
          child: HUDContainer(
            accentColor: Colors.greenAccent,
            opacity: 0.1,
            showGrid: true,
            padding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF002200).withOpacity(0.3),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24.r),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.05,
                        child: Image.network(
                          "https://www.transparenttextures.com/patterns/carbon-fibre.png",
                          repeat: ImageRepeat.repeat,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12.w),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Pot Display
                            Align(
                              alignment: Alignment.topRight,
                              child: _buildHUDStat(
                                  "POT", "$pot", Colors.yellowAccent),
                            ),
                            SizedBox(height: 5.h),

                            // Opponent Side
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildPlayerInfo(
                                    "Sakura", opponentChips, Colors.pinkAccent),
                                SizedBox(width: 20.w),
                                Row(
                                  children: opponentHand
                                      .map((c) => _buildCard(c,
                                          isBack: !showOpponentCards))
                                      .toList(),
                                ),
                              ],
                            ),

                            SizedBox(height: 15.h),

                            // Community Cards
                            Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 12.h, horizontal: 15.w),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (i) {
                                  String card = i < communityCards.length
                                      ? communityCards[i]
                                      : '🂠';
                                  bool isBack = i >= communityCards.length;
                                  return Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 4.w),
                                    child: _buildCard(card,
                                        isBack: isBack, isCommunity: true),
                                  );
                                }),
                              ),
                            ),

                            SizedBox(height: 15.h),

                            // Player Side
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: playerHand
                                      .map((c) => _buildCard(c))
                                      .toList(),
                                ),
                                SizedBox(width: 20.w),
                                _buildPlayerInfo(
                                    "You", playerChips, Colors.cyanAccent),
                              ],
                            ),

                            SizedBox(height: 20.h),

                            // Status & Controls
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    status.toUpperCase(),
                                    style: GoogleFonts.vt323(
                                      color: Colors.yellowAccent,
                                      fontSize: 20.sp,
                                      letterSpacing: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (showButtons ||
                                      (phase == HoldemPhase.idle ||
                                          phase == HoldemPhase.showdown))
                                    SizedBox(height: 10.h),
                                  if (phase == HoldemPhase.idle ||
                                      phase == HoldemPhase.showdown)
                                    _buildGameButton(
                                        phase == HoldemPhase.idle
                                            ? "DEAL"
                                            : "PLAY AGAIN",
                                        _deal,
                                        Colors.purpleAccent),
                                  if (showButtons)
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (!facingBet) ...[
                                            _buildGameButton("CHECK",
                                                _playerCheck, Colors.grey),
                                            SizedBox(width: 8.w),
                                            if (numRaisesThisRound < maxRaises)
                                              _buildGameButton(
                                                  "BET",
                                                  () =>
                                                      _playerBet(bigBlind * 2),
                                                  Colors.cyanAccent),
                                          ] else ...[
                                            _buildGameButton("FOLD",
                                                _playerFold, Colors.redAccent),
                                            SizedBox(width: 8.w),
                                            _buildGameButton("CALL",
                                                _playerCall, Colors.blueAccent),
                                            SizedBox(width: 8.w),
                                            if (numRaisesThisRound < maxRaises)
                                              _buildGameButton(
                                                  "RAISE",
                                                  () => _playerBet(
                                                      toCall + bigBlind * 2),
                                                  Colors.orangeAccent),
                                          ],
                                        ],
                                      ),
                                    ),
                                  if (!playerTurn &&
                                      phase != HoldemPhase.idle &&
                                      phase != HoldemPhase.showdown)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 12.w,
                                          height: 12.w,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(
                                                Colors.pinkAccent
                                                    .withOpacity(0.5)),
                                          ),
                                        ),
                                        SizedBox(width: 10.w),
                                        Text(
                                          "Sakura thinking...",
                                          style: GoogleFonts.vt323(
                                              color: Colors.pinkAccent
                                                  .withOpacity(0.6),
                                              fontSize: 14.sp),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.1), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(4.r),
        border: Border(
          right: BorderSide(color: color, width: 2),
          bottom: BorderSide(color: color.withOpacity(0.3), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label,
              style: GoogleFonts.vt323(
                  fontSize: 12.sp,
                  color: color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          Text(value,
              style: GoogleFonts.vt323(
                  fontSize: 20.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(blurRadius: 8, color: color)])),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo(String name, int chips, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.toUpperCase(),
            style: GoogleFonts.vt323(
                fontSize: 16.sp, color: color, fontWeight: FontWeight.w900),
          ),
          Text(
            "$chips ◈",
            style: GoogleFonts.vt323(
                fontSize: 18.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGameButton(String label, VoidCallback? onPressed, Color color) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.vt323(
              color: color, fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCard(String cardStr,
      {bool isBack = false, bool isCommunity = false}) {
    double cardW = isCommunity ? 48.w : 52.w;
    double cardH = isCommunity ? 72.h : 78.h;

    if (isBack) {
      return Container(
        width: cardW,
        height: cardH,
        margin: EdgeInsets.symmetric(horizontal: 2.w),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F1B),
          borderRadius: BorderRadius.circular(6.r),
          border:
              Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child:
                    Icon(Icons.grid_3x3, color: Colors.cyanAccent, size: 40.r),
              ),
            ),
            Center(
              child: Icon(Icons.security,
                  color: Colors.cyanAccent.withOpacity(0.8), size: 24.r),
            ),
          ],
        ),
      );
    }

    Card card = Card(cardStr);
    bool isRed = (card.suit == '♥' || card.suit == '♦');
    Color cardColor = isRed ? Colors.pinkAccent : Colors.cyanAccent;
    String rankDisplay = ranks[card.value - 2];

    return Container(
      width: cardW,
      height: cardH,
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: cardColor.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Corner Rank
          Positioned(
            top: 4.h,
            left: 4.w,
            child: Text(rankDisplay,
                style: GoogleFonts.orbitron(
                    fontSize: 14.sp,
                    color: cardColor,
                    fontWeight: FontWeight.w900,
                    height: 1.0)),
          ),
          // Center Suit
          Center(
            child: Text(card.suit,
                style: TextStyle(
                  fontSize: 24.sp,
                  color: cardColor,
                  shadows: [
                    Shadow(blurRadius: 10, color: cardColor.withOpacity(0.5)),
                  ],
                )),
          ),
          // Bottom Corner Rank (Rotated)
          Positioned(
            bottom: 4.h,
            right: 4.w,
            child: Transform.rotate(
              angle: pi,
              child: Text(rankDisplay,
                  style: GoogleFonts.orbitron(
                      fontSize: 14.sp,
                      color: cardColor,
                      fontWeight: FontWeight.w900,
                      height: 1.0)),
            ),
          ),
        ],
      ),
    );
  }
}
