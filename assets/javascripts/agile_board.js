document.addEventListener('DOMContentLoaded', () => {
  initDragDrop({
    cardSelector: '.card',
    dropSelector: '.status-column',
    dataKey: 'status_id',
    dropTargetAttr: 'statusId',
    urlPath: 'update_status'
  });

  initDragDrop({
    cardSelector: '.sprint-card',
    dropSelector: '.droppable-area',
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
      const targetValue = dropZone.dataset[dropTargetAttr];

      fetch(`/projects/${projectId}/agile_board/${urlPath}?id=${id}&${dataKey}=${targetValue}`, {
        method: 'POST',
        headers: { 'X-CSRF-Token': csrfToken }
      }).then(() => location.reload());
    });
  });
}