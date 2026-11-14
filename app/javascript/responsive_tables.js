// Copies each column header into data-label on its cells so narrow screens can show rows as cards.
function labelTables() {
  document.querySelectorAll("table.table").forEach((table) => {
    const headers = [...table.querySelectorAll("thead th")].map((th) => th.textContent.trim())
    if (headers.length === 0) return

    table.querySelectorAll("tbody tr, tfoot tr").forEach((row) => {
      let column = 0
      ;[...row.children].forEach((cell) => {
        if (!cell.hasAttribute("data-label")) cell.setAttribute("data-label", headers[column] || "")
        column += cell.colSpan || 1
      })
    })
  })
}

document.addEventListener("turbo:load", labelTables)
document.addEventListener("turbo:render", labelTables)
