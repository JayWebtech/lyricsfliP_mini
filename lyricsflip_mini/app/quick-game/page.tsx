'use client';

import { SongOptions } from '../components/song-options';
import { StatisticsPanel } from '../components/statistics-panel';
import GameResultPopup from '../components/GameResultPopup';
import { LyricCard } from '../components/LyricCard';
import { useGameStore } from 'store/game';
import { ArrowLeft } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { useQuickGame } from '../../hooks/useQuickGame';
import { useEffect } from 'react';

export default function QuickGamePage() {
  const router = useRouter();
  const gameStore = useGameStore();
  const genre = gameStore.gameConfig.genre || 'Pop';
  const difficulty = gameStore.gameConfig.difficulty || 'Easy';

  const {
    currentLyric,
    isGameStarted,
    selectedOption,
    correctOption,
    handleSongSelect,
    gameResult,
    isCardFlipped,
    nextLyric,
  } = useQuickGame(genre);

  const handleBack = () => {
    router.push('/');
  };

  // Remove the check that prevents the game from starting
  // The game will now start automatically when the page loads

  return (
    <div className="container mt-4 mx-auto h-fit w-full mb-20 lg:mb-12 p-4 lg:p-0 md:mt-24 lg:mt-32">
      <div className="mb-6">
        <button onClick={handleBack} className="flex items-center text-gray-600 mb-4">
          <ArrowLeft className="h-4 w-4 mr-2" />
          Back
        </button>
        <h1 className="text-2xl font-bold">Quick Game</h1>
        <p className="text-gray-600 text-sm">
          {`${genre} Genre | ${difficulty} Difficulty`}
        </p>
      </div>

      {gameResult && (
        <GameResultPopup
          isWin={gameResult.isWin}
          isMultiplayer={false}
        />
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-start-2 lg:col-span-1 order-1 lg:order-2">
          <LyricCard
            lyrics={[
              {
                text: currentLyric?.text || "Loading...",
                title: currentLyric?.title || "Loading...",
                artist: currentLyric?.artist || "Loading...",
              },
              nextLyric ? {
                text: nextLyric.text,
                title: nextLyric.title,
                artist: nextLyric.artist,
              } : {
                text: currentLyric?.text || "Loading...",
                title: currentLyric?.title || "Loading...",
                artist: currentLyric?.artist || "Loading...",
              }
            ]}
            isFlipped={isCardFlipped}
          />
        </div>
        <div className="lg:col-start-3 lg:col-span-1 order-2 lg:order-3">
          <StatisticsPanel
            time={`${gameStore.timeLeft}`}
            scores={`${gameStore.score} / ${gameStore.maxRounds}`}
            potWin="N/A"
          />
        </div>
      </div>

      {currentLyric && (
        <SongOptions
          options={currentLyric.options}
          onSelect={handleSongSelect}
          selectedOption={selectedOption}
          correctOption={correctOption}
        />
      )}
    </div>
  );
}