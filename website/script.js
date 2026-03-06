// Scroll reveal
const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
      }
    });
  },
  { threshold: 0.15 }
);

document.querySelectorAll('.reveal').forEach((el) => observer.observe(el));

// Typing animation in capsule
const phrases = [
  'Send the report by Friday',
  'Remind me to call Sarah',
  'The meeting is at three pm',
  'Add milk to the grocery list',
  'Schedule a demo for next week',
];

const typingEl = document.querySelector('.typing-text');
let phraseIndex = 0;
let charIndex = 0;
let deleting = false;
let timeout = null;

function typeLoop() {
  const phrase = phrases[phraseIndex];

  if (!deleting) {
    typingEl.textContent = phrase.slice(0, charIndex + 1);
    charIndex++;
    if (charIndex >= phrase.length) {
      deleting = true;
      timeout = setTimeout(typeLoop, 2000);
      return;
    }
    timeout = setTimeout(typeLoop, 50 + Math.random() * 40);
  } else {
    typingEl.textContent = phrase.slice(0, charIndex);
    charIndex--;
    if (charIndex < 0) {
      deleting = false;
      charIndex = 0;
      phraseIndex = (phraseIndex + 1) % phrases.length;
      timeout = setTimeout(typeLoop, 400);
      return;
    }
    timeout = setTimeout(typeLoop, 25);
  }
}

typeLoop();
