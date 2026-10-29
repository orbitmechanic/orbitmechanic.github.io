(() => {
  const head = document.querySelector(".site-head");
  const toggle = document.getElementById("menu-toggle");
  const nav = document.getElementById("site-nav");
  const blueprintButton = document.getElementById("blueprint-toggle");
  const video = document.getElementById("station-loop");
  const hero = document.querySelector(".hero");
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)");

  const setScrolled = () => {
    if (!head) return;
    head.classList.toggle("is-scrolled", window.scrollY > 40);
  };

  const setMenu = (open) => {
    if (!toggle || !nav) return;
    toggle.setAttribute("aria-expanded", String(open));
    nav.classList.toggle("is-open", open);
  };

  const setBlueprint = (open) => {
    document.body.classList.toggle("blueprint", open);
    if (blueprintButton) {
      blueprintButton.textContent = open ? "Exit blueprint (G)" : "Press G for blueprint";
    }
  };

  const isTyping = (target) => {
    if (!(target instanceof HTMLElement)) return false;
    return target.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(target.tagName);
  };

  const tickClock = () => {
    const time = new Date().toLocaleTimeString("en-GB", {
      timeZone: "UTC",
      hour12: false,
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit"
    });
    document.querySelectorAll("#utc-clock, #utc-clock-2").forEach((node) => {
      node.textContent = time;
    });
  };

  const revealItems = () => {
    const items = Array.from(document.querySelectorAll(".reveal"));
    if (!items.length) return;

    const groups = new Map();
    items.forEach((item) => {
      const parent = item.parentElement;
      if (!groups.has(parent)) groups.set(parent, []);
      groups.get(parent).push(item);
    });

    groups.forEach((group) => {
      group.forEach((item, index) => {
        item.style.transitionDelay = `${Math.min(index, 5) * 70}ms`;
      });
    });

    if (!("IntersectionObserver" in window) || reduceMotion.matches) {
      items.forEach((item) => item.classList.add("is-visible"));
      return;
    }

    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      });
    }, { threshold: 0.14, rootMargin: "0px 0px -8% 0px" });

    items.forEach((item) => observer.observe(item));
  };

  const manageVideo = () => {
    if (!video) return;
    if (reduceMotion.matches) {
      video.pause();
      return;
    }
    video.play().catch(() => {});
  };

  setScrolled();
  tickClock();
  revealItems();
  manageVideo();

  window.addEventListener("scroll", setScrolled, { passive: true });
  window.setInterval(tickClock, 1000);

  if (toggle && nav) {
    toggle.addEventListener("click", () => {
      setMenu(toggle.getAttribute("aria-expanded") !== "true");
    });

    nav.querySelectorAll("a").forEach((link) => {
      link.addEventListener("click", () => setMenu(false));
    });
  }

  if (blueprintButton) {
    blueprintButton.addEventListener("click", () => {
      setBlueprint(!document.body.classList.contains("blueprint"));
    });
  }

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") setMenu(false);
    if (event.key.toLowerCase() === "g" && !isTyping(event.target)) {
      setBlueprint(!document.body.classList.contains("blueprint"));
    }
  });

  if (hero && video && "IntersectionObserver" in window) {
    const videoObserver = new IntersectionObserver(([entry]) => {
      if (reduceMotion.matches) return;
      if (entry.isIntersecting) {
        video.play().catch(() => {});
      } else {
        video.pause();
      }
    }, { threshold: 0.05 });
    videoObserver.observe(hero);
  }

  reduceMotion.addEventListener?.("change", manageVideo);
})();
