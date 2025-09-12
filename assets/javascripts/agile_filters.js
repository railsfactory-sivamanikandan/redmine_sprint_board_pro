// Enhanced Agile Board Filters
(function() {
  'use strict';

  // Toggle fieldset visibility
  window.toggleFieldset = function(legend) {
    const fieldset = legend.parentElement;
    const content = fieldset.querySelector('div');
    const icon = legend.querySelector('svg use');

    if (content.style.display === 'none') {
      content.style.display = 'block';
      fieldset.classList.remove('collapsed');
      fieldset.classList.add('expanded');
      if (icon) {
        icon.setAttribute('href', '/assets/icons-731dc012.svg#icon--angle-down');
      }
    } else {
      content.style.display = 'none';
      fieldset.classList.remove('expanded');
      fieldset.classList.add('collapsed');
      if (icon) {
        icon.setAttribute('href', '/assets/icons-731dc012.svg#icon--angle-right');
      }
    }
  };

  // Toggle all status checkboxes
  window.toggleAllStatuses = function(checked) {
    const statusCheckboxes = document.querySelectorAll('.status-checkbox');
    statusCheckboxes.forEach(checkbox => {
      checkbox.checked = checked;
    });
  };

  // Handle story points operator change
  function handleStoryPointsOperator() {
    const operatorSelect = document.querySelector('select[name="op[story_points]"]');
    if (!operatorSelect) return;

    operatorSelect.addEventListener('change', function() {
      const valuesContainer = this.closest('tr').querySelector('.values');
      const existingInputs = valuesContainer.querySelectorAll('.value-input');

      if (this.value === '><') {
        // Show range inputs
        if (existingInputs.length === 1) {
          const secondInput = document.createElement('input');
          secondInput.type = 'text';
          secondInput.name = 'v[story_points][]';
          secondInput.className = 'value-input';
          secondInput.placeholder = 'To';
          valuesContainer.appendChild(secondInput);
        }
      } else {
        // Remove second input if exists
        if (existingInputs.length > 1) {
          existingInputs[1].remove();
        }
      }
    });
  }

  // Initialize enhanced filters
  function initializeFilters() {
    handleStoryPointsOperator();

    // Add filter removal functionality
    document.querySelectorAll('.icon-del').forEach(button => {
      button.addEventListener('click', function(e) {
        e.preventDefault();
        const row = this.closest('tr');
        if (row) {
          row.style.display = 'none';
          // Clear form values in the row
          row.querySelectorAll('input, select').forEach(input => {
            if (input.type === 'checkbox') {
              input.checked = false;
            } else {
              input.value = '';
            }
          });
        }
      });
    });

    // Auto-submit on certain filter changes
    document.querySelectorAll('.filter-select, .group-by-select').forEach(select => {
      select.addEventListener('change', function() {
        if (this.dataset.autoSubmit !== 'false') {
          // Add small delay to allow multiple rapid changes
          clearTimeout(window.filterTimeout);
          window.filterTimeout = setTimeout(() => {
            document.getElementById('query_form').submit();
          }, 500);
        }
      });
    });
  }

  // Show/Hide Query Save Form (Redmine style)
  window.showQuerySaveForm = function() {
    const saveSection = document.getElementById('query-save-section');
    const buttons = document.querySelector('.buttons');

    if (saveSection) {
      saveSection.style.display = 'block';
      // Focus on the name field
      const nameField = saveSection.querySelector('input[name="query[name]"]');
      if (nameField) {
        nameField.focus();
        nameField.select();
      }
    }

    // Hide the original buttons while saving
    if (buttons) {
      buttons.style.display = 'none';
    }
  };

  window.hideQuerySaveForm = function() {
    const saveSection = document.getElementById('query-save-section');
    const buttons = document.querySelector('.buttons');

    if (saveSection) {
      saveSection.style.display = 'none';
    }

    // Show the original buttons again
    if (buttons) {
      buttons.style.display = 'block';
    }
  };

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeFilters);
  } else {
    initializeFilters();
  }

})();