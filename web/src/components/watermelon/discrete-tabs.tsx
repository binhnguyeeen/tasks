'use client';

import { useCallback, useEffect, useLayoutEffect, useRef, useState, type FC, type ReactNode } from 'react';

import { cn } from '@/lib/utils';

interface TabItem {
  id: string;
  href: string;
  icon: ReactNode;
  label: string;
  activeColor: string;
}

interface DiscreteTabsProps {
  tabs: TabItem[];
  activeTab: string;
}

export const DiscreteTabs: FC<DiscreteTabsProps> = ({ tabs, activeTab }) => {
  const [pill, setPill] = useState<{ x: number; width: number } | null>(null);
  const [settled, setSettled] = useState(false);
  const refs = useRef(new Map<string, HTMLAnchorElement>());

  const measure = useCallback(() => {
    const el = refs.current.get(activeTab);
    if (!el) return;
    const next = { x: el.offsetLeft, width: el.offsetWidth };
    setPill(prev => (prev && prev.x === next.x && prev.width === next.width ? prev : next));
  }, [activeTab]);

  useLayoutEffect(measure, [measure]);

  useEffect(() => {
    if (pill && !settled) setSettled(true);
  }, [pill, settled]);

  useEffect(() => {
    window.addEventListener('resize', measure);
    document.fonts?.ready.then(measure);
    return () => window.removeEventListener('resize', measure);
  }, [measure]);

  return (
    <div className="relative flex w-fit items-center gap-1 rounded-full border border-border bg-zinc-50 p-1 dark:bg-zinc-900">
      <span
        aria-hidden="true"
        className={cn(
          'absolute left-0 top-1 h-8 rounded-full bg-white shadow-sm dark:bg-zinc-800',
          pill ? 'opacity-100' : 'opacity-0',
          settled && 'transition-[transform,width] duration-300 ease-out motion-reduce:transition-none',
        )}
        style={{ width: pill?.width ?? 0, transform: `translate3d(${pill?.x ?? 0}px, 0, 0)` }}
      />
      {tabs.map(tab => {
        const isActive = tab.id === activeTab;

        return (
          <a
            key={tab.id}
            href={tab.href}
            ref={el => {
              if (el) refs.current.set(tab.id, el);
              else refs.current.delete(tab.id);
            }}
            aria-current={isActive ? 'page' : undefined}
            className="relative z-10 flex h-8 items-center gap-2 rounded-full px-3 text-sm font-semibold focus-visible:outline-2 focus-visible:outline-offset-2"
          >
            <span
              className={cn(
                'flex items-center transition-colors duration-300',
                isActive ? tab.activeColor : 'text-neutral-500 dark:text-neutral-400',
              )}
            >
              {tab.icon}
            </span>
            <span
              className={cn(
                'transition-colors duration-300',
                isActive ? tab.activeColor : 'text-neutral-600 dark:text-neutral-400',
              )}
            >
              {tab.label}
            </span>
          </a>
        );
      })}
    </div>
  );
};
