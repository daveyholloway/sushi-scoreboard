<?php
// index.php
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Sushi Buffet Tracker</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <!-- Bootstrap 5 -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">

    <style>
        body { padding-bottom: 4rem; }
        .grid-table th, .grid-table td {
            text-align: center;
            vertical-align: middle;
            white-space: nowrap;
        }
        .plate-label { font-weight: 600; }
        .colour-swatch {
            display: inline-block;
            width: 14px;
            height: 14px;
            border-radius: 50%;
            margin-right: 4px;
            border: 1px solid #ccc;
        }
        .cell-controls button { padding: 0.1rem 0.4rem; }
        .sticky-footer {
            position: fixed;
            bottom: 0; left: 0; right: 0;
            background: #f8f9fa;
            border-top: 1px solid #ddd;
            padding: 0.5rem 1rem;
            z-index: 100;
        }
        .totals-pill { margin-right: 0.5rem; }
    </style>
</head>
<body class="bg-light">

<div class="container py-3">
    <h1 class="h3 mb-3">Sushi Buffet Tracker</h1>

    <!-- 1. Event selection / creation -->
    <div class="card mb-3">
        <div class="card-body">
            <h2 class="h5">1. Choose or create an event</h2>
            <div class="row g-2 align-items-end">
                <div class="col-md-6">
                    <label class="form-label">Existing events</label>
                    <select id="eventSelect" class="form-select">
                        <option value="">Loading…</option>
                    </select>
                </div>
                <div class="col-md-3">
                    <label class="form-label">New event name</label>
                    <input type="text" id="newEventName" class="form-control" placeholder="e.g. Yo! Sushi Shrewsbury">
                </div>
                <div class="col-md-2">
                    <label class="form-label">Date</label>
                    <input type="date" id="newEventDate" class="form-control">
                </div>
                <div class="col-md-1 d-grid">
                    <button id="createEventBtn" class="btn btn-primary">Add</button>
                </div>
            </div>
        </div>
    </div>

    <!-- 2. Participants -->
    <div class="card mb-3" id="participantsCard" style="display:none;">
        <div class="card-body">
            <h2 class="h5">2. Participants for this event</h2>

            <div id="participantsListContainer" class="mb-3">
                <!-- JS will populate checkboxes here -->
            </div>

            <div class="input-group mb-3" style="max-width: 400px;">
                <input type="text" id="newParticipantName" class="form-control" placeholder="Add a new diner">
                <button class="btn btn-primary" id="addParticipantBtn">Add</button>
            </div>

            <div class="d-flex justify-content-end">
                <button id="saveParticipantsBtn" class="btn btn-secondary">Save participants for event</button>
            </div>
        </div>
    </div>


    <!-- 3. Prices -->
    <div class="card mb-3" id="pricesCard" style="display:none;">
        <div class="card-body">
            <h2 class="h5">3. Prices for this sitting</h2>
            <div class="row">
                <div class="col-md-7 mb-3">
                    <h3 class="h6">Plate colours</h3>
                    <div id="colourPricesContainer"></div>
                </div>
                <div class="col-md-5 mb-3">
                    <h3 class="h6">Menu items (white plates)</h3>
                    <div id="menuPricesContainer"></div>
                </div>
            </div>
            <div class="d-flex justify-content-end">
                <button id="savePricesBtn" class="btn btn-secondary">Save prices</button>
            </div>
        </div>
    </div>

    <!-- 4. Grid -->
    <div class="card mb-3" id="gridCard" style="display:none;">
        <div class="card-body">
            <h2 class="h5">4. Tap to record plates</h2>
            <div class="table-responsive">
                <table class="table table-sm table-bordered align-middle grid-table" id="gridTable"></table>
            </div>
            <div class="form-text">
                Tap <strong>+</strong> when someone takes a plate; use <strong>–</strong> if you overshoot.
            </div>
        </div>
    </div>
</div>

<!-- Totals footer -->
<div class="sticky-footer" id="totalsBar" style="display:none;">
    <div class="d-flex flex-wrap align-items-center">
        <div class="me-2 fw-semibold">Totals:</div>
        <div id="totalsContainer" class="d-flex flex-wrap"></div>
    </div>
</div>

<script>
const apiBase = 'api.php';

let currentEventId = null;
let currentParticipants = [];
let currentColours = [];
let currentMenuItems = [];
let gridCounts = { plate: {}, menu: {} };

function fetchJSON(url, options = {}) {
    return fetch(url, options).then(r => r.json());
}
function showToast(msg) { alert(msg); }

/* Events */

function loadEvents() {
    fetchJSON(apiBase + '?action=list_events')
        .then(data => {
            const sel = document.getElementById('eventSelect');
            sel.innerHTML = '<option value="">Select an event…</option>';
            if (data.ok) {
                data.events.forEach(ev => {
                    const opt = document.createElement('option');
                    opt.value = ev.id;
                    opt.textContent = `${ev.event_date} – ${ev.name}`;
                    sel.appendChild(opt);
                });
            }
        });
}

document.getElementById('createEventBtn').addEventListener('click', () => {
    const name = document.getElementById('newEventName').value.trim();
    const date = document.getElementById('newEventDate').value;
    if (!name || !date) return showToast('Please enter a name and date.');
    fetchJSON(apiBase + '?action=create_event', {
        method: 'POST',
        body: JSON.stringify({ name, event_date: date })
    }).then(data => {
        if (!data.ok) return showToast(data.error || 'Error creating event');
        currentEventId = data.event_id;
        loadEvents();
        document.getElementById('eventSelect').value = currentEventId;
        onEventSelected();
    });
});

document.getElementById('eventSelect').addEventListener('change', () => {
    currentEventId = document.getElementById('eventSelect').value || null;
    onEventSelected();
});

function onEventSelected() {
    const hasEvent = !!currentEventId;
    document.getElementById('participantsCard').style.display = hasEvent ? '' : 'none';
    document.getElementById('pricesCard').style.display = 'none';
    document.getElementById('gridCard').style.display = 'none';
    document.getElementById('totalsBar').style.display = 'none';
    if (!hasEvent) return;
    loadAllParticipants();
    loadEventSetup();
}

/* Participants */

function loadAllParticipants() {
    fetchJSON(apiBase + '?action=list_participants')
        .then(data => {
            if (!data.ok) return;
            const sel = document.getElementById('existingParticipants');
            sel.innerHTML = '';
            data.participants.forEach(p => {
                const opt = document.createElement('option');
                opt.value = p.id;
                opt.textContent = p.name;
                sel.appendChild(opt);
            });
        });
}

function renderParticipantsList(allParticipants, eventParticipantIds) {
    const container = document.getElementById('participantsListContainer');
    container.innerHTML = '';

    allParticipants.forEach(p => {
        const id = p.id;
        const checked = eventParticipantIds.includes(id) ? 'checked' : '';

        const row = document.createElement('div');
        row.className = 'form-check mb-1';

        row.innerHTML = `
            <input class="form-check-input participant-checkbox" type="checkbox" value="${id}" id="p_${id}" ${checked}>
            <label class="form-check-label" for="p_${id}">
                ${p.name}
            </label>
        `;

        container.appendChild(row);
    });
}

document.getElementById('saveParticipantsBtn').addEventListener('click', () => {
    const checkboxes = document.querySelectorAll('.participant-checkbox');
    const selectedIds = [];

    checkboxes.forEach(cb => {
        if (cb.checked) selectedIds.push(parseInt(cb.value, 10));
    });

    fetchJSON(apiBase + '?action=set_event_participants', {
        method: 'POST',
        body: JSON.stringify({
            event_id: currentEventId,
            participant_ids: selectedIds,
            new_names: []
        })
    }).then(data => {
        if (!data.ok) return showToast(data.error || 'Error saving participants');
        showToast('Participants updated.');
        loadEventSetup();
    });
});

document.getElementById('addParticipantBtn').addEventListener('click', () => {
    const name = document.getElementById('newParticipantName').value.trim();
    if (!name) return;

    fetchJSON(apiBase + '?action=set_event_participants', {
        method: 'POST',
        body: JSON.stringify({
            event_id: currentEventId,
            participant_ids: currentParticipants.map(p => p.id),
            new_names: [name]
        })
    }).then(data => {
        if (!data.ok) return showToast(data.error || 'Error adding participant');

        document.getElementById('newParticipantName').value = '';
        loadEventSetup();
    });
});



/* Event setup */

function loadEventSetup() {
    if (!currentEventId) return;

    fetchJSON(apiBase + '?action=get_event_setup&event_id=' + encodeURIComponent(currentEventId))
        .then(data => {
            if (!data.ok) return showToast(data.error || 'Error loading event setup');

            currentParticipants = data.participants || [];
            currentColours = data.colours || [];
            currentMenuItems = data.menu_items || [];

            // Load ALL known participants
            fetchJSON(apiBase + '?action=list_participants')
                .then(all => {
                    if (!all.ok) return;

                    const eventIds = currentParticipants.map(p => p.id);
                    renderParticipantsList(all.participants, eventIds);
                });

            renderPriceEditors(data.colour_prices || {}, data.menu_prices || {});
            document.getElementById('pricesCard').style.display = '';

            if (currentParticipants.length > 0) {
                document.getElementById('gridCard').style.display = '';
                document.getElementById('totalsBar').style.display = '';
                loadGridData();
            } else {
                document.getElementById('gridCard').style.display = 'none';
                document.getElementById('totalsBar').style.display = 'none';
            }
        });
}



function renderPriceEditors(colourPrices, menuPrices) {
    const colourDiv = document.getElementById('colourPricesContainer');
    colourDiv.innerHTML = '';
    currentColours.forEach(c => {
        const row = document.createElement('div');
        row.className = 'input-group input-group-sm mb-1';
        const swatch = c.hex_colour ? `<span class="colour-swatch" style="background:${c.hex_colour};"></span>` : '';
        row.innerHTML = `
            <span class="input-group-text" style="min-width:120px;">
                ${swatch}${c.name}
            </span>
            <span class="input-group-text">£</span>
            <input type="number" step="0.01" min="0" class="form-control text-end colour-price-input"
                   data-id="${c.id}" value="${colourPrices[c.id] ?? ''}">
        `;
        colourDiv.appendChild(row);
    });

    const menuDiv = document.getElementById('menuPricesContainer');
    menuDiv.innerHTML = '';
    currentMenuItems.forEach(m => {
        const row = document.createElement('div');
        row.className = 'input-group input-group-sm mb-1';
        const defaultHint = m.default_price ? ` (default £${parseFloat(m.default_price).toFixed(2)})` : '';
        row.innerHTML = `
            <span class="input-group-text" style="min-width:160px;">
                ${m.name}${defaultHint}
            </span>
            <span class="input-group-text">£</span>
            <input type="number" step="0.01" min="0" class="form-control text-end menu-price-input"
                   data-id="${m.id}" value="${menuPrices[m.id] ?? (m.default_price ?? '')}">
        `;
        menuDiv.appendChild(row);
    });
}

document.getElementById('savePricesBtn').addEventListener('click', () => {
    if (!currentEventId) return;
    const colourInputs = document.querySelectorAll('.colour-price-input');
    const menuInputs = document.querySelectorAll('.menu-price-input');
    const colour_prices = {};
    const menu_prices = {};

    colourInputs.forEach(inp => {
        const id = inp.dataset.id;
        const val = parseFloat(inp.value);
        if (!isNaN(val) && val > 0) colour_prices[id] = val;
    });
    menuInputs.forEach(inp => {
        const id = inp.dataset.id;
        const val = parseFloat(inp.value);
        if (!isNaN(val) && val > 0) menu_prices[id] = val;
    });

    fetchJSON(apiBase + '?action=save_prices', {
        method: 'POST',
        body: JSON.stringify({ event_id: currentEventId, colour_prices, menu_prices })
    }).then(data => {
        if (!data.ok) return showToast(data.error || 'Error saving prices');
        showToast('Prices saved.');
        updateTotals();
    });
});

/* Grid */

function loadGridData() {
    if (!currentEventId) return;
    fetchJSON(apiBase + '?action=get_grid_data&event_id=' + encodeURIComponent(currentEventId))
        .then(data => {
            if (!data.ok) return;
            gridCounts = { plate: {}, menu: {} };
            (data.plate || []).forEach(r => {
                const key = `${r.participant_id}_${r.plate_colour_id}`;
                gridCounts.plate[key] = parseInt(r.quantity, 10) || 0;
            });
            (data.menu || []).forEach(r => {
                const key = `${r.participant_id}_${r.menu_item_id}`;
                gridCounts.menu[key] = parseInt(r.quantity, 10) || 0;
            });
            renderGrid();
            updateTotals();
        });
}

function renderGrid() {
    const table = document.getElementById('gridTable');
    table.innerHTML = '';

    if (currentParticipants.length === 0) {
        table.innerHTML = '<tr><td class="text-muted">Add participants to start tracking.</td></tr>';
        return;
    }

    const thead = document.createElement('thead');
    const hr = document.createElement('tr');
    hr.innerHTML = '<th scope="col">Plate / Item</th>';
    currentParticipants.forEach(p => {
        const th = document.createElement('th');
        th.scope = 'col';
        th.textContent = p.name;
        hr.appendChild(th);
    });
    thead.appendChild(hr);
    table.appendChild(thead);

    const tbody = document.createElement('tbody');

    currentColours.forEach(c => {
        const tr = document.createElement('tr');
        const labelTd = document.createElement('td');
        const swatch = c.hex_colour ? `<span class="colour-swatch" style="background:${c.hex_colour};"></span>` : '';
        labelTd.innerHTML = `<span class="plate-label">${swatch}${c.name}</span>`;
        tr.appendChild(labelTd);

        currentParticipants.forEach(p => {
            const td = document.createElement('td');
            const key = `${p.id}_${c.id}`;
            const qty = gridCounts.plate[key] || 0;
            td.innerHTML = `
                <div class="cell-controls d-flex justify-content-center align-items-center gap-1">
                    <button class="btn btn-outline-secondary btn-sm btn-minus" data-type="plate" data-pid="${p.id}" data-id="${c.id}">−</button>
                    <span class="count" data-type="plate" data-pid="${p.id}" data-id="${c.id}">${qty}</span>
                    <button class="btn btn-outline-primary btn-sm btn-plus" data-type="plate" data-pid="${p.id}" data-id="${c.id}">+</button>
                </div>
            `;
            tr.appendChild(td);
        });

        tbody.appendChild(tr);
    });

    if (currentMenuItems.length > 0) {
        const sep = document.createElement('tr');
        const td = document.createElement('td');
        td.colSpan = currentParticipants.length + 1;
        td.className = 'table-secondary text-start';
        td.textContent = 'Menu items';
        sep.appendChild(td);
        tbody.appendChild(sep);

        currentMenuItems.forEach(m => {
            const tr = document.createElement('tr');
            const labelTd = document.createElement('td');
            labelTd.innerHTML = `<span class="plate-label">${m.name}</span>`;
            tr.appendChild(labelTd);

            currentParticipants.forEach(p => {
                const td = document.createElement('td');
                const key = `${p.id}_${m.id}`;
                const qty = gridCounts.menu[key] || 0;
                td.innerHTML = `
                    <div class="cell-controls d-flex justify-content-center align-items-center gap-1">
                        <button class="btn btn-outline-secondary btn-sm btn-minus" data-type="menu" data-pid="${p.id}" data-id="${m.id}">−</button>
                        <span class="count" data-type="menu" data-pid="${p.id}" data-id="${m.id}">${qty}</span>
                        <button class="btn btn-outline-primary btn-sm btn-plus" data-type="menu" data-pid="${p.id}" data-id="${m.id}">+</button>
                    </div>
                `;
                tr.appendChild(td);
            });

            tbody.appendChild(tr);
        });
    }

    table.appendChild(tbody);

    table.querySelectorAll('.btn-plus, .btn-minus').forEach(btn => {
        btn.addEventListener('click', onCellButtonClick);
    });
}

function onCellButtonClick(e) {
    const btn = e.currentTarget;
    const type = btn.dataset.type;
    const pid = parseInt(btn.dataset.pid, 10);
    const id = parseInt(btn.dataset.id, 10);
    const delta = btn.classList.contains('btn-plus') ? 1 : -1;
    if (!currentEventId || !pid || !id) return;

    const action = type === 'plate' ? 'increment_plate' : 'increment_menu';
    const payload = { event_id: currentEventId, participant_id: pid, delta };
    if (type === 'plate') payload.plate_colour_id = id;
    else payload.menu_item_id = id;

    fetchJSON(apiBase + '?action=' + action, {
        method: 'POST',
        body: JSON.stringify(payload)
    }).then(data => {
        if (!data.ok) return showToast(data.error || 'Error updating count');
        const newQty = data.quantity ?? 0;
        const key = `${pid}_${id}`;
        if (type === 'plate') gridCounts.plate[key] = newQty;
        else gridCounts.menu[key] = newQty;

        const span = document.querySelector(`span.count[data-type="${type}"][data-pid="${pid}"][data-id="${id}"]`);
        if (span) span.textContent = newQty;
        updateTotals();
    });
}

/* Totals */

function updateTotals() {
    if (!currentEventId) return;
    fetchJSON(apiBase + '?action=get_totals&event_id=' + encodeURIComponent(currentEventId))
        .then(data => {
            if (!data.ok) return;
            const perPerson = data.per_person || {};
            const container = document.getElementById('totalsContainer');
            container.innerHTML = '';
            currentParticipants.forEach(p => {
                const total = perPerson[p.id] ?? 0;
                const pill = document.createElement('div');
                pill.className = 'badge bg-primary text-light totals-pill';
                pill.textContent = `${p.name}: £${total.toFixed(2)}`;
                container.appendChild(pill);
            });
        });
}

/* Init */

document.addEventListener('DOMContentLoaded', () => {
    loadEvents();
});
</script>

</body>
</html>
