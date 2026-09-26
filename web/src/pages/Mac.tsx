import { useEffect } from "react";

const base = import.meta.env.BASE_URL;

export default function Mac() {
  useEffect(() => {
    window.location.replace(`${base}guide.html#install-mac`);
  }, []);
  return null;
}
