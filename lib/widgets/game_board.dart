import 'package:flutter/material.dart';
import '../models/game_state.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/responsive_utils.dart';
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
      padding: context.gameBoardPadding,
      child: SingleChildScrollView(
        child: context.isMobile ? _buildMobileLayout(gameState) : _buildDesktopLayout(gameState),
      ),
    );
  }
  Widget _buildDesktopLayout(GameState gameState) {
    return Column(
      children: [
        // Foundations row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            gameState.foundations.length,
            (index) => Padding(
              padding: EdgeInsets.symmetric(horizontal: context.foundationSpacing),
              child: FoundationPileWidget(
                pile: gameState.foundations[index],
                pileIndex: index,
              ),
            ),
          ),
        ),
        SizedBox(height: context.elementSpacing),
        // Tableau and Stock/Waste
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stock and Waste
            Column(
              children: [
                StockPileWidget(),
                SizedBox(height: context.elementSpacing / 2),
                WastePileWidget(),
              ],
            ),
            SizedBox(width: context.elementSpacing),
            // Tableau columns
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate maximum card width based on available space
                  final maxWidth = (constraints.maxWidth - (gameState.tableau.length - 1) * context.elementSpacing) / gameState.tableau.length;
                  final cardWidth = maxWidth.clamp(0.0, context.cardWidth);

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        gameState.tableau.length,
                        (index) => Padding(
                          padding: EdgeInsets.symmetric(horizontal: context.elementSpacing / 2),
                          child: SizedBox(
                            width: cardWidth,
                            child: TableauColumnWidget(
                              column: gameState.tableau[index],
                              columnIndex: index,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(GameState gameState) {
    return Column(
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
        // Tableau columns
        Row(
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
        const SizedBox(height: 20),
        // Stock/Waste row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: Container()),
            StockPileWidget(),
            const SizedBox(width: 20),
            WastePileWidget(),
            Expanded(child: Container()),
          ],
        ),
      ],
    );
  }
}