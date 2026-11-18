export default function ProductPhoto({ src, size = 56 }: { src: string | null; size?: number }) {
  return (
    <img
      className={src ? 'photo' : 'photo photo-empty'}
      src={src ?? '/logo.png'}
      alt=""
      width={size}
      height={size}
      loading="lazy"
    />
  );
}
