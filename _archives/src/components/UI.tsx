import { RotateCcw, Play, Square, ChevronLeft, ChevronRight, RotateCw } from 'lucide-react';
import { useStore } from '../store/useStore';

export function UI() {
    const { isPlaying, togglePlay, reset, moveSlope, rotateSlope } = useStore();

    const Button = ({ children, onClick, color = 'slate' }: any) => (
        <button
            onPointerDown={(e) => {
                e.preventDefault();
                onClick();
            }}
            className={`
        w-16 h-16 flex items-center justify-center rounded-sm border-2
        ${color === 'red' ? 'border-red-9 text-red-9 bg-red-2' :
                    color === 'green' ? 'border-green-9 text-green-9 bg-green-2' :
                        'border-slate-1 text-slate-1 bg-slate-11'}
        active:scale-95 transition-transform select-none
      `}
        >
            {children}
        </button>
    );

    return (
        <div className="w-full h-full p-4 flex justify-between items-center max-w-2xl mx-auto">
            <div className="flex gap-4">
                <Button onClick={rotateSlope}>
                    <RotateCw size={32} />
                </Button>
                <Button
                    onClick={togglePlay}
                    color={isPlaying ? 'green' : 'red'}
                >
                    {isPlaying ? <Square size={32} fill="currentColor" /> : <Play size={32} fill="currentColor" />}
                </Button>
                <Button onClick={reset}>
                    <RotateCcw size={32} />
                </Button>
            </div>

            <div className="flex gap-4">
                <Button onClick={() => moveSlope(-1)}>
                    <ChevronLeft size={48} />
                </Button>
                <Button onClick={() => moveSlope(1)}>
                    <ChevronRight size={48} />
                </Button>
            </div>
        </div>
    );
}
