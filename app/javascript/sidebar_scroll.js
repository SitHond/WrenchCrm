// Keeps the sidebar menu where it was when Turbo swaps the page, so clicking a lower item does not jump to the top.
const KEY = "sidebar-scroll"
let position = null

function menu() {
  return document.querySelector(".sidebar nav")
}

function remember() {
  const nav = menu()
  if (!nav) return
  position = nav.scrollTop
  try { sessionStorage.setItem(KEY, String(position)) } catch {}
}

function restore() {
  const nav = menu()
  if (!nav) return
  if (position === null) {
    try { position = Number(sessionStorage.getItem(KEY)) || 0 } catch { position = 0 }
  }
  nav.scrollTop = position

  const active = nav.querySelector(".nav-link.active")
  if (active) {
    const top = active.offsetTop - nav.offsetTop
    if (top < nav.scrollTop || top + active.offsetHeight > nav.scrollTop + nav.clientHeight) {
      active.scrollIntoView({ block: "nearest" })
    }
  }
}

document.addEventListener("turbo:before-render", remember)
document.addEventListener("turbo:before-visit", remember)
window.addEventListener("pagehide", remember)
document.addEventListener("turbo:render", restore)
document.addEventListener("turbo:load", restore)
