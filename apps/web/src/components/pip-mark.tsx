export function PipMark({ mastered = false, label }: { mastered?: boolean; label: string }) {
  const eye = mastered ? 7 : 4.2;
  return (
    <svg width="64" height="64" viewBox="0 0 64 64" role="img" aria-label={label}>
      <rect x="10" y="14" width="44" height="40" rx="12" fill="#2454FF" />
      <circle cx="24" cy="32" r={eye} fill="#F6F1E7" />
      <circle cx="40" cy="32" r={eye} fill="#F6F1E7" />
    </svg>
  );
}
