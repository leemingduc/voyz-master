import 'package:flutter/material.dart';
import 'package:voyz/screens/chat_screen.dart';
import 'package:voyz/screens/destination_detail_screen.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/aivivu_header.dart';

/// Keeps an AI conversation visible while the user explores a destination.
class DestinationChatSplitScreen extends StatefulWidget {
  const DestinationChatSplitScreen({
    super.key,
    required this.destinationName,
    this.chatHistoryDestinationName,
  });

  final String destinationName;
  final String? chatHistoryDestinationName;

  @override
  State<DestinationChatSplitScreen> createState() =>
      _DestinationChatSplitScreenState();
}

class _DestinationChatSplitScreenState
    extends State<DestinationChatSplitScreen> {
  late String _destinationName;
  double _chatPaneFraction = 0.5;

  static const _minChatPaneFraction = 0.25;
  static const _maxChatPaneFraction = 0.75;

  @override
  void initState() {
    super.initState();
    _destinationName = widget.destinationName;
  }

  void _selectDestination(String destinationName) {
    final destination = destinationName.trim();
    if (destination.isEmpty || destination == _destinationName) return;
    setState(() => _destinationName = destination);
  }

  void _resizeChatPane(double delta, double availableSpace) {
    if (availableSpace <= 0) return;
    setState(() {
      _chatPaneFraction = (_chatPaneFraction + delta / availableSpace).clamp(
        _minChatPaneFraction,
        _maxChatPaneFraction,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AivivuHeader(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Khám phá cùng AI',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;
          final chatPane = ChatScreen(
            destinationName: widget.chatHistoryDestinationName,
            contextDestinationName: _destinationName,
            onDestinationSelected: _selectDestination,
            embedded: true,
          );
          final destinationPane = DestinationDetailScreen(
            key: ValueKey(_destinationName),
            destinationName: _destinationName,
            embedded: true,
          );

          if (isWide) {
            return Row(
              children: [
                SizedBox(
                  width: constraints.maxWidth * _chatPaneFraction,
                  child: chatPane,
                ),
                _ResizeHandle(
                  axis: Axis.horizontal,
                  onDragUpdate: (delta) =>
                      _resizeChatPane(delta.delta.dx, constraints.maxWidth),
                ),
                Expanded(child: destinationPane),
              ],
            );
          }

          return Column(
            children: [
              SizedBox(
                height: constraints.maxHeight * _chatPaneFraction,
                child: chatPane,
              ),
              _ResizeHandle(
                axis: Axis.vertical,
                onDragUpdate: (delta) =>
                    _resizeChatPane(delta.delta.dy, constraints.maxHeight),
              ),
              Expanded(child: destinationPane),
            ],
          );
        },
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({required this.axis, required this.onDragUpdate});

  final Axis axis;
  final ValueChanged<DragUpdateDetails> onDragUpdate;

  @override
  Widget build(BuildContext context) {
    final isHorizontal = axis == Axis.horizontal;
    final dividerColor = Colors.white.withValues(alpha: 0.16);

    return MouseRegion(
      cursor: isHorizontal
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: isHorizontal ? onDragUpdate : null,
        onVerticalDragUpdate: isHorizontal ? null : onDragUpdate,
        child: SizedBox(
          width: isHorizontal ? 12 : double.infinity,
          height: isHorizontal ? double.infinity : 12,
          child: Center(
            child: Container(
              width: isHorizontal ? 1 : 40,
              height: isHorizontal ? 40 : 1,
              color: dividerColor,
            ),
          ),
        ),
      ),
    );
  }
}
