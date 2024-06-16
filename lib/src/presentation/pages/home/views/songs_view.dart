import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:meloplay/src/bloc/home/home_bloc.dart';
import 'package:meloplay/src/bloc/player/player_bloc.dart';
import 'package:meloplay/src/core/di/service_locator.dart';
import 'package:meloplay/src/data/repositories/player_repository.dart';
import 'package:meloplay/src/presentation/widgets/song_list_tile.dart';

class SongsView extends StatefulWidget {
  const SongsView({super.key});

  @override
  State<SongsView> createState() => _SongsViewState();
}

class _SongsViewState extends State<SongsView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final audioQuery = sl<OnAudioQuery>();
  final songs = <SongModel>[];
  bool isLoading = true;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(GetSongsEvent());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocListener<HomeBloc, HomeState>(
      listener: (context, state) async {
        if (state is SongsLoaded) {
          setState(() {
            songs.clear();
            songs.addAll(state.songs);
            isLoading = false;
          });

          Fluttertoast.showToast(
            msg: '${state.songs.length} آهنگ پیدا شد',
          );
        }
      },
      child: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: () async {
                context.read<HomeBloc>().add(GetSongsEvent());
              },
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // number of songs
                          Text(
                            '${songs.length} آهنگ',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(32),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.shuffle),
                                    const SizedBox(width: 8),
                                    Text(
                                      'تصادفی',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  // enable shuffle
                                  context.read<PlayerBloc>().add(
                                        PlayerSetShuffleModeEnabled(true),
                                      );

                                  // get random song
                                  final randomSong =
                                      songs[Random().nextInt(songs.length)];

                                  // play random song
                                  context.read<PlayerBloc>().add(
                                        PlayerLoadSongs(
                                          songs,
                                          sl<MusicPlayer>()
                                              .getMediaItemFromSong(randomSong),
                                        ),
                                      );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(32),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.play_arrow),
                                    const SizedBox(width: 8),
                                    Text(
                                      'پخش',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  // disable shuffle
                                  context.read<PlayerBloc>().add(
                                        PlayerSetShuffleModeEnabled(false),
                                      );

                                  // play first song
                                  context.read<PlayerBloc>().add(
                                        PlayerLoadSongs(
                                          songs,
                                          sl<MusicPlayer>()
                                              .getMediaItemFromSong(songs[0]),
                                        ),
                                      );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 16),
                  ),
                  AnimationLimiter(
                    child: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final song = songs[index];
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 500),
                            child: FlipAnimation(
                              child: SongListTile(
                                song: song,
                                songs: songs,
                              ),
                            ),
                          );
                        },
                        childCount: songs.length,
                      ),
                    ),
                  ),
                  // bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
    );
  }

  void scrollToTop() {
    _scrollController.animateTo(
      0.0, // Scroll to the top
      duration:
          const Duration(milliseconds: 500), // Duration of the scroll animation
      curve: Curves.easeInOut, // Animation curve
    );
  }
}
