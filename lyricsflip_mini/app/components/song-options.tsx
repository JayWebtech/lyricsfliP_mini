'use client';

interface SongOption {
  title: string;
  artist: string;
}

interface SongOptionsProps {
  options: SongOption[];
  onSelect: (option: SongOption, index: number) => void;
  selectedOption?: SongOption | null;
  correctOption?: SongOption | null;
}

export function SongOptions({
  options,
  onSelect,
  selectedOption = null,
  correctOption = null,
}: SongOptionsProps) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-8">
      {options.map((option, index) => {
        const isSelected = selectedOption?.title === option.title;
        const isCorrect = correctOption?.title === option.title;

        let buttonClasses =
          'text-left p-4 rounded-lg transition-all duration-200 ';

        if (isCorrect) {
          buttonClasses += 'bg-green-100 border-2 border-green-500';
        } else if (isSelected) {
          buttonClasses += 'bg-red-100 border-2 border-red-500';
        } else {
          buttonClasses += 'bg-purple-50 border border-purple-100 hover:border-purple-300';
        }

        return (
          <button
            key={index}
            onClick={() => onSelect(option, index)}
            className={buttonClasses}
            disabled={selectedOption !== null}
          >
            <div className="flex items-start gap-2">
              {(isCorrect || isSelected) && (
                <span
                  aria-hidden
                  className={`mt-0.5 inline-flex w-5 h-5 items-center justify-center rounded-full border ${isCorrect ? 'border-green-500 text-green-600' : 'border-red-500 text-red-600'}`}
                >
                  {isCorrect ? '✓' : '✕'}
                </span>
              )}
              <div>
                <h3 className="font-medium text-gray-900">{option.title}</h3>
                <p className="text-sm text-gray-600">{option.artist}</p>
              </div>
            </div>
          </button>
        );
      })}
    </div>
  );
}
