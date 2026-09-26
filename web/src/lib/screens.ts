const base = import.meta.env.BASE_URL;

export interface Screenshot {
  light: string;
  dark: string;
  width: number;
  height: number;
  alt: string;
}

export const windowShot: Screenshot = {
  light: `${base}screens/window-dark.webp`,
  dark: `${base}screens/window-dark.webp`,
  width: 2000,
  height: 1397,
  alt: "The Tasks window showing Today, with overdue tasks, tasks due today, and the inspector open on “Pay rent”.",
};

export const menuShot: Screenshot = {
  light: `${base}screens/menu-dark.png`,
  dark: `${base}screens/menu-dark.png`,
  width: 772,
  height: 820,
  alt: "The Tasks menu bar dropdown with a New Task field, two overdue tasks and two tasks due today.",
};
