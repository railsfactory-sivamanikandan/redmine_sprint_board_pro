document.addEventListener('DOMContentLoaded', () => {
  initDragDrop({
    cardSelector: '.sprint-card',
    dropSelector: '.sprint-droppable-area',
    dataKey: 'sprint_id',
    dropTargetAttr: 'sprint',
    urlPath: 'update_sprint'
  });
});

function initDragDrop({ cardSelector, dropSelector, dataKey, dropTargetAttr, urlPath }) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  const projectId = window.projectIdentifier;

  document.querySelectorAll(cardSelector).forEach(card => {
    card.addEventListener('dragstart', e => {
      e.dataTransfer.setData('id', card.dataset.id);
      e.dataTransfer.setData('origin', card.parentElement.id); // tbody ID
    });
  });

  document.querySelectorAll(dropSelector).forEach(dropZone => {
    dropZone.addEventListener('dragover', e => {
      e.preventDefault();
      dropZone.classList.add('dragover');
    });

    dropZone.addEventListener('dragleave', () => {
      dropZone.classList.remove('dragover');
    });

    dropZone.addEventListener('drop', e => {
      e.preventDefault();
      dropZone.classList.remove('dragover');

      const id = e.dataTransfer.getData('id');
      const originId = e.dataTransfer.getData('origin');
      const targetSprintId = dropZone.dataset[dropTargetAttr];

      fetch(`/projects/${projectId}/agile_board/${urlPath}?id=${id}&${dataKey}=${targetSprintId}`, {
        method: 'POST',
        headers: { 'X-CSRF-Token': csrfToken }
      }).then(response => {
        if (!response.ok) {
          alert('Failed to update sprint assignment.');
          return;
        }

        const card = document.querySelector(`${cardSelector}[data-id="${id}"]`);
        const oldParent = document.getElementById(originId);
        const newParent = dropZone;

        if (!card || !newParent || newParent === card.parentElement) return;

        const isNowUnassigned = newParent.id === 'unassigned-issues';

        // Remove .action-cell <td> from card if moving to unassigned
        if (isNowUnassigned) {
          const actionCell = card.querySelector('.action-cell');
          if (actionCell) actionCell.remove();
        } else {
          // Add Remove link if moving into sprint
          if (!card.querySelector('.action-cell')) {
            const actionTd = document.createElement('td');
            actionTd.className = 'action-cell';

            const link = document.createElement('a');
            link.href = `/projects/${projectId}/agile_board/update_sprint?id=${id}&sprint_id=`;
            link.className = 'remove-sprint-link icon icon-del';
            link.title = 'Remove from Sprint';
            link.innerText = ' Remove';
            actionTd.appendChild(link);
            card.appendChild(actionTd);
          }
        }

        // Move card to new parent
        newParent.appendChild(card);

        // Remove empty row from new parent
        const emptyRow = newParent.querySelector('.droppable-empty');
        if (emptyRow) emptyRow.remove();

        // Add empty row to old parent if it's now empty
        if (oldParent && oldParent.querySelectorAll(cardSelector).length === 0) {
          const colCount = oldParent.closest('table').querySelectorAll('thead th').length;
          const emptyTr = document.createElement('tr');
          emptyTr.className = 'droppable-empty';
          const td = document.createElement('td');
          td.colSpan = colCount;
          td.innerHTML = oldParent.id === 'unassigned-issues'
            ? '<em>Drop issues here to unassign</em>'
            : '<em>Drop issues here to assign</em>';
          emptyTr.appendChild(td);
          oldParent.appendChild(emptyTr);
        }
      });
    });
  });
}

function attachDragHandlers() {
  document.querySelectorAll('.sprint-card').forEach(card => {
    card.addEventListener('dragstart', e => {
      e.dataTransfer.setData('id', card.dataset.id);
    });
  });
}


document.addEventListener('click', function (e) {
  if (e.target.matches('a.remove-sprint-link')) {
    e.preventDefault();
    if (!confirm('Remove this issue from sprint?')) return;

    const link = e.target;
    const row = link.closest('tr');
    const tableBody = row.parentElement;
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

    fetch(link.href, {
      method: 'POST',
      headers: { 'X-CSRF-Token': csrfToken }
    }).then(response => {
      if (response.ok) {
        const newRow = row.cloneNode(true);
        newRow.querySelector('.action-cell')?.remove(); // Remove action cell for unassigned
        newRow.classList.add('sprint-card');
        newRow.setAttribute('draggable', 'true');
        row.remove();

        // If the old sprint table is now empty, show message
        if (tableBody.querySelectorAll('tr.sprint-card').length === 0) {
          const colCount = tableBody.closest('table').querySelectorAll('thead th').length;
          const emptyTr = document.createElement('tr');
          emptyTr.className = 'droppable-empty';
          const td = document.createElement('td');
          td.colSpan = colCount;
          td.innerHTML = '<em>Drop issues here to assign</em>';
          emptyTr.appendChild(td);
          tableBody.appendChild(emptyTr);
        }

        // Append new row to unassigned issues table
        const unassignedTbody = document.querySelector('#unassigned-issues');
        if (unassignedTbody) {
          const emptyRow = unassignedTbody.querySelector('.droppable-empty');
          if (emptyRow) emptyRow.remove();
          unassignedTbody.appendChild(newRow);
          attachDragHandlers();
        }
      } else {
        alert('Failed to remove from sprint.');
      }
    });
  }
});


document.addEventListener("DOMContentLoaded", function () {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  const projectId = window.projectIdentifier;
  const allowedTransitions = window.allowedStatusTransitions || {};

  let draggedItem = null;

  document.querySelectorAll(".card-list").forEach(list => {
    new Sortable(list, {
      group: "cards",
      animation: 150,

      onStart: function (evt) {
        draggedItem = evt.item;
        const issueId = draggedItem.dataset.id;
        const allowed = allowedTransitions[issueId] || [];

        document.querySelectorAll(".status-column").forEach(col => {
          const statusId = parseInt(col.dataset.statusId);
          if (allowed.includes(statusId)) {
            col.classList.add("allowed-drop");
          } else {
            col.classList.add("not-allowed-drop");
          }
        });
      },

      onEnd: function (evt) {
        const issueId = evt.item.dataset.id;
        const fromStatusId = evt.from.closest(".status-column").dataset.statusId;
        const toStatusId = evt.to.closest(".status-column").dataset.statusId;
        const lockVersion = evt.item.dataset.lockVersion;

        const issueIds = Array.from(evt.to.querySelectorAll(".card")).map(card => card.dataset.id);
        const newPosition = issueIds.indexOf(issueId);
        const oldPosition = evt.oldIndex;

        const statusChanged = fromStatusId !== toStatusId;
        const positionChanged = newPosition !== oldPosition;

        // Check for not allowed status move
        const allowed = window.allowedStatusTransitions?.[issueId] || [];
        if (statusChanged && !allowed.includes(Number(toStatusId))) {
          alert("🚫 This status transition is not allowed.");
          evt.from.insertBefore(evt.item, evt.from.children[evt.oldIndex]);
          document.querySelectorAll(".status-column").forEach(col => {
            col.classList.remove("allowed-drop", "not-allowed-drop");
          });
          return;
        }

        // Only send API call if something actually changed
        if (!statusChanged && !positionChanged) {
          document.querySelectorAll(".status-column").forEach(col => {
            col.classList.remove("allowed-drop", "not-allowed-drop");
          });
          return;
        }

        fetch(`/projects/${projectId}/agile_board/update_issue`, {
          method: "POST",
          headers: {
            'X-CSRF-Token': csrfToken,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({
            id: issueId,
            status_id: toStatusId,
            board_position: newPosition,
            lock_version: lockVersion
          })
        }).then(response => {
          if (response.ok) {
            return response.json();
          } else {
            alert("❌ Update failed. Please try again.");
          }
        }).then(data => {
          if (data?.lock_version) {
            evt.item.dataset.lockVersion = data.lock_version;
          }
        });
        document.querySelectorAll(".status-column").forEach(col => {
          col.classList.remove("allowed-drop", "not-allowed-drop");
        });
      }
    });
  });
});