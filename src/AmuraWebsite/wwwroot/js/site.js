// Lightweight scroll-reveal — no dependency, respects prefers-reduced-motion via CSS.
document.addEventListener("DOMContentLoaded", function () {
    var reveals = document.querySelectorAll(".reveal");
    if (!("IntersectionObserver" in window) || reveals.length === 0) {
        reveals.forEach(function (el) { el.classList.add("is-visible"); });
        return;
    }

    var observer = new IntersectionObserver(
        function (entries) {
            entries.forEach(function (entry) {
                if (entry.isIntersecting) {
                    entry.target.classList.add("is-visible");
                    observer.unobserve(entry.target);
                }
            });
        },
        { threshold: 0.15 }
    );

    reveals.forEach(function (el) { observer.observe(el); });
});

document.addEventListener("DOMContentLoaded", function () {
    var fields = document.querySelectorAll("[data-uppercase]");
    if (!fields.length) return;

    function upper(el) {
        var start = el.selectionStart;
        var end = el.selectionEnd;
        el.value = (el.value || "").toUpperCase();
        try { el.setSelectionRange(start, end); } catch (e) { }
    }

    fields.forEach(function (el) {
        el.addEventListener("input", function () { upper(el); });
    });

    var form = fields[0].form;
    if (form) {
        form.addEventListener("submit", function () {
            fields.forEach(function (el) { el.value = (el.value || "").toUpperCase(); });
        });
    }
});
