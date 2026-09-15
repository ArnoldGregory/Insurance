// Sidebar menu-group toggle.
//
// MenuViewComponent renders a 2-level tree from GET /api/menus/mine: a
// top-level item with Children becomes a ".nav-group" whose header
// (".nav-group-toggle") expands/collapses its ".nav-submenu" list. This is
// the portal's own custom shell nav (see Menu/Default.cshtml + _Layout.cshtml)
// - separate from the vendored Bootstrap theme used by content pages, so it
// stays a small vanilla-JS toggle rather than Bootstrap's collapse plugin:
// just toggling an "open" class that legacy-shell.css uses to animate
// max-height.
document.addEventListener("DOMContentLoaded", function () {
    document.querySelectorAll(".nav-group-toggle").forEach(function (toggle) {
        toggle.addEventListener("click", function () {
            var group = toggle.closest(".nav-group");
            if (group) {
                group.classList.toggle("open");
            }
        });
    });
});

// Page-freeze loader overlay - shared helpers any view can call around an
// AJAX request to show the user "something is happening" (e.g. the purchase
// wizard's client ID-number search). The overlay markup itself lives once
// in _Layout.cshtml (#page-loader-overlay); these just toggle it.
window.showPageLoader = function (message) {
    var overlay = document.getElementById("page-loader-overlay");
    if (!overlay) return;
    var text = document.getElementById("page-loader-text");
    if (text) text.textContent = message || "Please wait...";
    overlay.classList.add("show");
};
window.hidePageLoader = function () {
    var overlay = document.getElementById("page-loader-overlay");
    if (overlay) overlay.classList.remove("show");
};

// Notification bell - polling badge + manual show/hide toggle. Only present
// in the DOM at all for SA/AA/SP (see _Layout.cshtml's isQuoteBackofficeRole
// check), so every selector below is guarded with a null check and just does
// nothing for roles that don't get a bell (e.g. Agent).
//
// Every ~45s this calls GET /notifications/summary (NotificationsController,
// same portal - not the real API directly, see its doc comment for why),
// and repaints the badge count + dropdown from the JSON it returns:
//   { pendingCount, assignedToMeCount, totalCount }
// This is deliberately NOT real-time (no SignalR/WebSockets) - a periodic
// poll was the explicit, simpler choice for this feature.
//
// Open/close is a plain custom toggle (no Bootstrap dropdown JS involved) -
// click the bell to show/hide #notif-dropdown, click anywhere outside or
// press Escape to close it again.
document.addEventListener("DOMContentLoaded", function () {
    var bellBtn = document.getElementById("notif-bell-btn");
    var dropdown = document.getElementById("notif-dropdown");
    var badge = document.getElementById("notif-badge");
    var body = document.getElementById("notif-dropdown-body");
    if (!badge || !body) return;

    if (bellBtn && dropdown) {
        bellBtn.addEventListener("click", function (e) {
            e.stopPropagation();
            dropdown.classList.toggle("show");
        });
        document.addEventListener("click", function (e) {
            if (!dropdown.classList.contains("show")) return;
            if (dropdown.contains(e.target) || bellBtn.contains(e.target)) return;
            dropdown.classList.remove("show");
        });
        document.addEventListener("keydown", function (e) {
            if (e.key === "Escape") dropdown.classList.remove("show");
        });
    }

    function renderDropdown(data) {
        var rows = "";
        if (data.pendingCount > 0) {
            rows += '<a class="notif-dropdown-item" href="/QuoteRequests?status=PENDING">' +
                '<span>Pending requests in the queue</span>' +
                '<span class="notif-dropdown-item-count">' + data.pendingCount + '</span></a>';
        }
        if (data.assignedToMeCount > 0) {
            rows += '<a class="notif-dropdown-item" href="/QuoteRequests?status=IN_PROGRESS&mine=true">' +
                '<span>Assigned to you, in progress</span>' +
                '<span class="notif-dropdown-item-count">' + data.assignedToMeCount + '</span></a>';
        }
        body.innerHTML = rows || '<div class="notif-dropdown-empty">Nothing needs your attention right now.</div>';
    }

    function poll() {
        fetch("/notifications/summary", { headers: { "Accept": "application/json" } })
            .then(function (res) { return res.ok ? res.json() : null; })
            .then(function (data) {
                if (!data) return;
                var total = data.totalCount || 0;
                if (total > 0) {
                    badge.textContent = total > 99 ? "99+" : String(total);
                    badge.style.display = "block";
                } else {
                    badge.style.display = "none";
                }
                renderDropdown(data);
            })
            .catch(function () { /* a failed poll just leaves the last-known badge showing */ });
    }

    poll();
    setInterval(poll, 45000);
});

// "DataTable-lite" - a from-scratch, plain-JS/CSS echo of the real jQuery
// DataTables plugin BIMA_D_LINE - Copy's own admin screens use (see e.g.
// that project's Views/Management/DueInsuranceManagement.cshtml -
// $('#insuranceTable').DataTable({...}), whose default chrome is a search
// box, a page-length selector, sortable columns, a "Showing X to Y of Z
// entries" footer, and a numbered pager). This reproduces that same set of
// behaviors without pulling in jQuery DataTables itself, consistent with
// this project's "no Bootstrap/jQuery plugins" rule - everything below is
// plain DOM APIs.
//
// This operates ONLY on rows already in the table (client-side), same as
// DataTables does by default without server-side processing enabled. It
// does NOT replace real server-side filtering/pagination - a screen like
// Purchases/Index still has its own status/paymentStatus dropdowns and its
// own true Previous/Next links that re-query the API; this is purely a
// fast, no-reload search/sort/page layer on top of whatever one page of
// rows the server already sent down.
//
// Opt in per table by giving it a `data-page-size` attribute (the default
// page length) plus a matching set of `data-table-*` control elements:
//   <input        data-table-search="myTableId">
//   <select        data-table-pagesize="myTableId"><option>10</option>...</select>
//   <table id="myTableId" class="data-table" data-page-size="10">
//     <thead><tr><th data-sort>Name</th>...</tr></thead>
//     <tbody><tr>...</tr>
//       <tr class="data-table-empty-row">...(never searched/sorted/paged)...</tr>
//     </tbody>
//   </table>
//   <span   data-table-info="myTableId"></span>
//   <div    data-table-pager="myTableId"></div>
(function () {
    function initTable(table) {
        var tbody = table.querySelector("tbody");
        var allRows = Array.prototype.slice.call(tbody.querySelectorAll("tr")).filter(function (r) {
            return !r.classList.contains("data-table-empty-row");
        });

        var infoEl = document.querySelector('[data-table-info="' + table.id + '"]');
        var pagerEl = document.querySelector('[data-table-pager="' + table.id + '"]');

        // Nothing to search/sort/page through (server already showed the
        // "no results" empty state) - leave that row exactly as rendered.
        if (allRows.length === 0) {
            if (infoEl) infoEl.textContent = "";
            return;
        }

        var state = {
            query: "",
            sortIndex: null,
            sortAsc: true,
            page: 1,
            pageSize: parseInt(table.getAttribute("data-page-size"), 10) || 10
        };

        function getFiltered() {
            if (!state.query) return allRows.slice();
            return allRows.filter(function (r) {
                return r.textContent.toLowerCase().indexOf(state.query) !== -1;
            });
        }

        function getSorted(rows) {
            if (state.sortIndex === null) return rows;
            var idx = state.sortIndex;
            var copy = rows.slice();
            copy.sort(function (a, b) {
                var av = (a.children[idx] && a.children[idx].textContent.trim()) || "";
                var bv = (b.children[idx] && b.children[idx].textContent.trim()) || "";
                var an = parseFloat(av.replace(/[^0-9.-]/g, ""));
                var bn = parseFloat(bv.replace(/[^0-9.-]/g, ""));
                var bothNumeric = !isNaN(an) && !isNaN(bn) && /[0-9]/.test(av) && /[0-9]/.test(bv);
                var cmp = bothNumeric ? (an - bn) : av.localeCompare(bv);
                return state.sortAsc ? cmp : -cmp;
            });
            return copy;
        }

        function renderPager(totalPages) {
            if (!pagerEl) return;
            pagerEl.innerHTML = "";
            if (totalPages <= 1) return;

            function addBtn(label, page, disabled, current) {
                var btn = document.createElement("button");
                btn.type = "button";
                btn.textContent = label;
                btn.className = "table-pager-btn" + (current ? " active" : "");
                if (disabled) btn.disabled = true;
                btn.addEventListener("click", function () { state.page = page; render(); });
                pagerEl.appendChild(btn);
            }

            addBtn("‹", state.page - 1, state.page === 1, false);

            var maxButtons = 5;
            var startPage = Math.max(1, state.page - Math.floor(maxButtons / 2));
            var endPage = Math.min(totalPages, startPage + maxButtons - 1);
            startPage = Math.max(1, endPage - maxButtons + 1);

            for (var p = startPage; p <= endPage; p++) {
                addBtn(String(p), p, false, p === state.page);
            }

            addBtn("›", state.page + 1, state.page === totalPages, false);
        }

        function render() {
            var filtered = getSorted(getFiltered());
            var total = filtered.length;
            var totalPages = Math.max(1, Math.ceil(total / state.pageSize));
            if (state.page > totalPages) state.page = totalPages;
            if (state.page < 1) state.page = 1;

            var start = (state.page - 1) * state.pageSize;
            var pageRows = filtered.slice(start, start + state.pageSize);

            // Hide every row, then re-append just this page's rows in
            // sorted order - appendChild() on an already-attached node
            // moves it, so this reorders and shows/hides in one pass.
            allRows.forEach(function (r) { r.style.display = "none"; });
            pageRows.forEach(function (r) {
                r.style.display = "";
                tbody.appendChild(r);
            });

            if (infoEl) {
                infoEl.textContent = total === 0
                    ? "No matching records"
                    : "Showing " + (start + 1) + " to " + Math.min(start + state.pageSize, total) + " of " + total + " entries";
            }

            renderPager(totalPages);
        }

        var searchInput = document.querySelector('[data-table-search="' + table.id + '"]');
        if (searchInput) {
            searchInput.addEventListener("input", function () {
                state.query = searchInput.value.trim().toLowerCase();
                state.page = 1;
                render();
            });
        }

        var pageSizeSelect = document.querySelector('[data-table-pagesize="' + table.id + '"]');
        if (pageSizeSelect) {
            pageSizeSelect.value = String(state.pageSize);
            pageSizeSelect.addEventListener("change", function () {
                state.pageSize = parseInt(pageSizeSelect.value, 10) || 10;
                state.page = 1;
                render();
            });
        }

        table.querySelectorAll("th[data-sort]").forEach(function (th) {
            th.addEventListener("click", function () {
                var index = Array.prototype.indexOf.call(th.parentNode.children, th);
                if (state.sortIndex === index) {
                    state.sortAsc = !state.sortAsc;
                } else {
                    state.sortIndex = index;
                    state.sortAsc = true;
                }
                table.querySelectorAll("th[data-sort]").forEach(function (h) { h.removeAttribute("data-sort-dir"); });
                th.setAttribute("data-sort-dir", state.sortAsc ? "asc" : "desc");
                render();
            });
        });

        render();
    }

    document.addEventListener("DOMContentLoaded", function () {
        document.querySelectorAll("table.data-table[data-page-size]").forEach(initTable);
    });
})();

// Generic modal open/close - no plugin, just three data attributes:
//   <button data-modal-open="myModal">Open</button>
//   <div class="modal-backdrop" data-modal-backdrop="myModal"></div>
//   <div class="modal" id="myModal">
//     ...<button data-modal-close="myModal">Cancel</button>
//   </div>
// The form inside still submits/redirects the normal full-page way (this
// app doesn't do AJAX form posts anywhere else either) - the modal is
// purely a "don't show this form until asked" affordance, not a SPA-style
// partial update. A page reload after submit naturally leaves it closed.
document.addEventListener("DOMContentLoaded", function () {
    function openModal(id) {
        var modal = document.getElementById(id);
        var backdrop = document.querySelector('[data-modal-backdrop="' + id + '"]');
        if (!modal) return;
        modal.classList.add("show");
        if (backdrop) backdrop.classList.add("show");
        document.body.classList.add("modal-open");
    }

    function closeModal(id) {
        var modal = document.getElementById(id);
        var backdrop = document.querySelector('[data-modal-backdrop="' + id + '"]');
        if (modal) modal.classList.remove("show");
        if (backdrop) backdrop.classList.remove("show");
        document.body.classList.remove("modal-open");
    }

    // Exposed on window so other scripts (the document-preview handler
    // below) can open/close a modal after first filling in its content -
    // data-modal-open only handles the "no content to prepare" case.
    window.openModal = openModal;
    window.closeModal = closeModal;

    document.querySelectorAll("[data-modal-open]").forEach(function (btn) {
        btn.addEventListener("click", function () { openModal(btn.getAttribute("data-modal-open")); });
    });
    document.querySelectorAll("[data-modal-close]").forEach(function (btn) {
        btn.addEventListener("click", function () { closeModal(btn.getAttribute("data-modal-close")); });
    });
    document.querySelectorAll("[data-modal-backdrop]").forEach(function (backdrop) {
        backdrop.addEventListener("click", function () { closeModal(backdrop.getAttribute("data-modal-backdrop")); });
    });
    document.addEventListener("keydown", function (e) {
        if (e.key !== "Escape") return;
        document.querySelectorAll(".modal.show").forEach(function (modal) { closeModal(modal.id); });
    });
});

// Document preview modal - lets a reviewer look at a quote offer's uploaded
// document without leaving the portal / opening a new tab. Targets a real
// Bootstrap modal now (#docPreviewModal, one instance per page, see
// Details.cshtml - a plain <div class="modal fade">, opened here via
// jQuery's .modal('show') now that bootstrap.js is loaded) - this just
// decides WHAT to put inside it based on the file extension, since the
// browser can only render some types inline:
//   .pdf                -> <iframe> (browsers render PDFs natively)
//   .jpg/.jpeg/.png      -> <img>
//   anything else (.doc/.docx) -> no inline renderer exists for these in a
//                                 plain browser tab either, so this falls
//                                 back to a plain download link instead of
//                                 pretending to preview it.
document.addEventListener("DOMContentLoaded", function () {
    var body = document.getElementById("doc-preview-body");
    var titleEl = document.getElementById("doc-preview-title");
    if (!body) return;

    document.querySelectorAll("[data-doc-preview]").forEach(function (trigger) {
        trigger.addEventListener("click", function () {
            var url = trigger.getAttribute("data-doc-preview");
            if (!url) return;

            var ext = (trigger.getAttribute("data-doc-ext") || "").toLowerCase();
            var fileName = ext ? "document." + ext : "document";

            if (titleEl) titleEl.textContent = fileName;

            if (ext === "pdf") {
                body.innerHTML = '<iframe src="' + url + '" style="width:100%;height:70vh;border:1px solid #ddd;border-radius:4px;"></iframe>';
            } else if (ext === "jpg" || ext === "jpeg" || ext === "png") {
                body.innerHTML = '<img src="' + url + '" alt="' + fileName + '" style="max-width:100%;max-height:70vh;display:block;margin:0 auto;border-radius:4px;" />';
            } else {
                body.innerHTML = '<p class="text-muted" style="margin:0 0 12px;">This file type can\'t be previewed inline.</p>' +
                    '<a href="' + url + '" target="_blank" rel="noopener" class="btn btn-outline">Download / open ' + fileName + '</a>';
            }

            if (window.jQuery) { jQuery("#docPreviewModal").modal("show"); }
        });
    });
});

// Global page-freeze loader on every form submit / button click - wires the
// showPageLoader/hidePageLoader helpers (defined above) to fire automatically
// so nobody can double-click Submit/Assign/Delete/etc. and fire a duplicate
// request while the first one is still in flight.
//
// Two triggers:
//   1. Every <form> submit, unless it opts out with data-no-loader.
//   2. Every navigating <a class="btn ..."> click (e.g. the grid's "View"
//      links) - not a form, but a slow page load looks just as
//      unresponsive without some feedback.
//
// event.defaultPrevented is checked so a form whose own onsubmit handler
// already cancelled the submission (e.g. the Expire button's
// confirm("...") being dismissed) doesn't still show the overlay for a
// request that never actually happened. No hidePageLoader call is needed
// here on the success path - a real form submit/link click navigates to a
// new page, which naturally clears the overlay; it only needs hiding by
// hand where a request finishes WITHOUT a page navigation (nothing in this
// app does that today - every form posts and redirects).
// SweetAlert2 confirm - opt in per form with data-confirm="message" instead
// of the browser's plain confirm() (e.g. Details.cshtml's "Mark expired"/
// "Delete offer" forms). Registered on the CAPTURE phase specifically so it
// runs BEFORE the page-freeze-loader's bubble-phase submit listener below -
// otherwise the loader overlay would flash on screen underneath the
// confirm dialog before the person has even answered it. On confirm, this
// marks the form (data-confirmed) and calls the native form.submit() (NOT
// requestSubmit()) - native submit() bypasses JS event listeners entirely,
// so there's no risk of re-triggering this same confirm a second time; the
// loader is shown by hand right before that native submit instead, since
// the freeze-loader's own listener won't see this submission either.
document.addEventListener("DOMContentLoaded", function () {
    document.body.addEventListener("submit", function (e) {
        var form = e.target;
        if (!(form instanceof HTMLFormElement)) return;
        var message = form.getAttribute("data-confirm");
        if (!message || form.dataset.confirmed === "1") return;

        e.preventDefault();
        e.stopImmediatePropagation();

        function proceed() {
            form.dataset.confirmed = "1";
            if (window.showPageLoader) showPageLoader(form.getAttribute("data-loader-message") || "Please wait...");
            form.submit();
        }

        if (typeof Swal !== "undefined") {
            Swal.fire({
                title: "Are you sure?", text: message, icon: "warning",
                showCancelButton: true, confirmButtonText: "Yes", cancelButtonText: "Cancel",
                confirmButtonColor: "#d4af37"
            }).then(function (result) { if (result.isConfirmed) proceed(); });
        } else if (window.confirm(message)) {
            proceed();
        }
    }, true);
});

document.addEventListener("DOMContentLoaded", function () {
    document.body.addEventListener("submit", function (e) {
        var form = e.target;
        if (!(form instanceof HTMLFormElement)) return;
        if (form.hasAttribute("data-no-loader")) return;
        if (e.defaultPrevented) return;

        showPageLoader(form.getAttribute("data-loader-message") || "Please wait...");

        // Disable every submit control so a second click/Enter can't fire a
        // duplicate request while the first is in flight. Already-collected
        // form data still posts normally even after its trigger button is
        // disabled.
        form.querySelectorAll('button[type="submit"], input[type="submit"]').forEach(function (btn) {
            btn.disabled = true;
        });
    });

    document.body.addEventListener("click", function (e) {
        var link = e.target.closest("a.btn");
        if (!link) return;
        if (link.hasAttribute("data-modal-open") || link.hasAttribute("data-modal-close")) return;
        if (link.hasAttribute("data-no-loader")) return;
        if (link.target === "_blank") return;
        var href = link.getAttribute("href");
        if (!href || href === "#" || href.indexOf("javascript:") === 0) return;

        showPageLoader("Please wait...");
    });
});

// Mobile sidebar toggle - BIMA_D_LINE - Copy's header has a
// "navbar-toggle" hamburger button that slides its sidebar in/out on
// narrow screens (data-click="sidebar-toggled"). Our sidebar used to just
// disappear below 768px with no way to reopen it; this adds the same
// slide-in-panel behavior via a hamburger button in the topbar (see
// _Layout.cshtml) toggling an "open" class site.css uses to translate the
// sidebar on-screen, plus a backdrop that closes it again on click.
document.addEventListener("DOMContentLoaded", function () {
    var toggleBtn = document.getElementById("sidebar-toggle-btn");
    var sidebar = document.querySelector(".sidebar");
    var backdrop = document.getElementById("sidebar-backdrop");
    if (!toggleBtn || !sidebar) return;

    function closeSidebar() {
        sidebar.classList.remove("open");
        if (backdrop) backdrop.classList.remove("show");
    }

    toggleBtn.addEventListener("click", function () {
        sidebar.classList.toggle("open");
        if (backdrop) backdrop.classList.toggle("show", sidebar.classList.contains("open"));
    });

    if (backdrop) backdrop.addEventListener("click", closeSidebar);

    // Only close on an actual navigation link, not on a group-toggle button
    // (MenuViewComponent's collapsible-group headers are also ".nav-link"
    // for styling purposes - closing the whole overlay when someone just
    // wanted to expand a submenu would immediately hide the very links
    // they were trying to reach).
    sidebar.querySelectorAll("a.nav-link").forEach(function (link) {
        link.addEventListener("click", closeSidebar);
    });
});
