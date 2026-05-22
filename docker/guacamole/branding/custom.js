(function () {
    var STORAGE_KEY = "ladvik-connection-view";
    var GRID_CLASS = "ladvik-grid-view";
    var LIST_CLASS = "ladvik-list-view";
    var TOGGLE_CLASS = "ladvik-view-toggle";

    function getMode() {
        return localStorage.getItem(STORAGE_KEY) || "grid";
    }

    function setMode(mode) {
        document.body.classList.remove(GRID_CLASS, LIST_CLASS);
        document.body.classList.add(mode === "list" ? LIST_CLASS : GRID_CLASS);
        localStorage.setItem(STORAGE_KEY, mode);

        var wrap = document.querySelector("." + TOGGLE_CLASS);
        if (!wrap) {
            return;
        }

        var listBtn = wrap.querySelector("button[data-mode='list']");
        var gridBtn = wrap.querySelector("button[data-mode='grid']");
        if (listBtn) {
            listBtn.classList.toggle("active", mode === "list");
        }
        if (gridBtn) {
            gridBtn.classList.toggle("active", mode === "grid");
        }
    }

    function getAllConnectionsHeader() {
        var headers = Array.prototype.slice.call(document.querySelectorAll(".home-view .connection-list-ui .header"));
        for (var i = 0; i < headers.length; i += 1) {
            var text = headers[i].textContent || "";
            if (/All Connections/i.test(text)) {
                return headers[i];
            }
        }
        return null;
    }

    function mountToggle() {
        if (!document.body.classList.contains("home")) {
            return;
        }

        var header = getAllConnectionsHeader();
        if (!header) {
            return;
        }

        if (header.querySelector("." + TOGGLE_CLASS)) {
            setMode(getMode());
            return;
        }

        var wrap = document.createElement("div");
        wrap.className = TOGGLE_CLASS;

        var listBtn = document.createElement("button");
        listBtn.type = "button";
        listBtn.textContent = "List";
        listBtn.setAttribute("data-mode", "list");
        listBtn.addEventListener("click", function () {
            setMode("list");
        });

        var gridBtn = document.createElement("button");
        gridBtn.type = "button";
        gridBtn.textContent = "Grid";
        gridBtn.setAttribute("data-mode", "grid");
        gridBtn.addEventListener("click", function () {
            setMode("grid");
        });

        wrap.appendChild(listBtn);
        wrap.appendChild(gridBtn);

        header.appendChild(wrap);
        setMode(getMode());
    }

    function tick() {
        mountToggle();
    }

    document.addEventListener("DOMContentLoaded", tick);
    window.addEventListener("hashchange", function () {
        setTimeout(tick, 10);
    });

    var observer = new MutationObserver(function () {
        tick();
    });

    observer.observe(document.documentElement, {
        childList: true,
        subtree: true
    });

    setTimeout(tick, 0);
})();
