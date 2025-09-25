import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'foundation_pile_widget.dart';
import 'tableau_column_widget.dart';
import 'stock_waste_widgets.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final gameState = provider.gameState;

    return Container(
      key: const Key('game-board'),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Foundations row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                gameState.foundations.length,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FoundationPileWidget(
                    pile: gameState.foundations[index],
                    pileIndex: index,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Tableau and Stock/Waste
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stock and Waste
                Column(
                  children: [
                    StockPileWidget(),
                    const SizedBox(height: 8),
                    WastePileWidget(),
                  ],
                ),
                const SizedBox(width: 20),
                // Tableau columns
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      gameState.tableau.length,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TableauColumnWidget(
                          column: gameState.tableau[index],
                          columnIndex: index,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}