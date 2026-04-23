import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../../../../../core/widgets/home/chat_message_widget.dart';
import '../../../../../core/widgets/home/typing_indicator.dart';
import '../../../../../core/widgets/home/home_search_bar.dart';
import '../../../../../core/services/home_state_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: HomeStateService.getOrCreateHomeCubit(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  Offset _position = const Offset(22, 22);

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      left: _position.dx,
                      top: _position.dy,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _position += details.delta;
                          });
                        },
                        child: SizedBox(
                          width: constraints.maxWidth - 44,
                          height: constraints.maxHeight - 44,
                          child: _buildChatContent(context, state),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatContent(BuildContext context, HomeState state) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x80DCF9E4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF0272BA)),
      ),
      child: Column(
        children: [
              // Header chào buổi sáng trong khung chat
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Text(
                  'DNGO Xin chào!',
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: Color(0xFF517907),
                  ),
                ),
              ),
              // Chat messages
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: state.chatMessages.length + (state.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (state.isTyping && index == state.chatMessages.length) {
                        return const TypingIndicator();
                      }
                      return ChatMessageWidget(
                        message: state.chatMessages[index],
                        onOptionTap: (option) => context.read<HomeCubit>().selectOption(option),
                        onMenuSelected: (menuText) {
                          context.read<HomeCubit>().sendMessage(menuText);
                          // Scroll to bottom after sending
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (_scrollController.hasClients) {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
              // Search bar ở dưới cùng trong khung chat
              Padding(
                padding: const EdgeInsets.all(16),
                child: HomeSearchBar(
                  controller: _searchController,
                  onChanged: (value) => context.read<HomeCubit>().updateSearchQuery(value),
                  onSubmitted: () {
                    context.read<HomeCubit>().performSearch();
                    _searchController.clear();
                  },
                  onSendPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      context.read<HomeCubit>().performSearch();
                      _searchController.clear();
                    }
                  },
                ),
              ),
            ],
          ),
    );
  }

}
