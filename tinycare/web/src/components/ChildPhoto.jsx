import { useMemo } from 'react';

const PLACEHOLDER = '/placeholder-avatar.svg';

export default function ChildPhoto({
  child,
  width,
  height,
  alt = '',
  radius = 'var(--radius-lg)',
  style,
  imgStyle,
  ...rest
}) {
  const src = useMemo(
    () => (child?.photo_url || child?.photo || child?.image_url) || PLACEHOLDER,
    [child]
  );

  let frame;
  if (typeof width === 'number') {
    frame = { width, height: height ?? Math.round(width * 1.5), flexShrink: 0 };
  } else if (width) {
    frame = { width, height, flexShrink: 0 };
  } else {
    frame = { width: '100%', aspectRatio: '4 / 6' };
  }

  return (
    <div
      style={{
        borderRadius: radius,
        overflow: 'hidden',
        ...frame,
        ...style,
      }}
      {...rest}
    >
      <img
        src={src}
        alt={alt || child?.name || 'Foto anak'}
        style={{
          width: '100%',
          height: '100%',
          objectFit: 'cover',
          objectPosition: 'center',
          display: 'block',
          ...imgStyle,
        }}
        onError={(e) => { e.target.src = PLACEHOLDER; }}
      />
    </div>
  );
}