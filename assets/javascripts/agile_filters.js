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
    initializeCardConfiguration();
    initializeStatusFilters();

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

  function initializeStatusFilters() {
    // Sync "Select All" checkbox state on page load
    syncSelectAllStatus();

    // Add event listeners to individual status checkboxes
    document.querySelectorAll('.status-checkbox').forEach(checkbox => {
      checkbox.addEventListener('change', syncSelectAllStatus);
    });
  }

  function syncSelectAllStatus() {
    const selectAllCheckbox = document.getElementById('select_all_statuses');
    const statusCheckboxes = document.querySelectorAll('.status-checkbox');

    if (!selectAllCheckbox || statusCheckboxes.length === 0) return;

    // Count checked status checkboxes
    const checkedCount = Array.from(statusCheckboxes).filter(cb => cb.checked).length;

    // Update Select All state
    if (checkedCount === statusCheckboxes.length) {
      // All are checked
      selectAllCheckbox.checked = true;
      selectAllCheckbox.indeterminate = false;
    } else if (checkedCount === 0) {
      // None are checked
      selectAllCheckbox.checked = false;
      selectAllCheckbox.indeterminate = false;
    } else {
      // Some are checked (indeterminate state)
      selectAllCheckbox.checked = false;
      selectAllCheckbox.indeterminate = true;
    }
  }

  function initializeCardConfiguration() {
    // Initialize button states based on current selection
    updateCardPreview();

    // Add event listeners for real-time preview updates
    document.querySelectorAll('.column-checkbox').forEach(checkbox => {
      checkbox.addEventListener('change', updateCardPreview);
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

  // Card Configuration Functions
  window.applyCardConfiguration = function() {
    const selectedFields = getSelectedCardFields();

    if (selectedFields.length === 0) {
      alert('Please select at least one field to display on cards.');
      return;
    }

    // Update URL with new configuration and reload
    const url = new URL(window.location.href);
    url.searchParams.delete('c');
    selectedFields.forEach(field => {
      url.searchParams.append('c', field);
    });

    window.location.href = url.toString();
  };

  window.saveCardPreferences = function() {
    const selectedFields = getSelectedCardFields();

    if (selectedFields.length === 0) {
      alert('Please select at least one field to display on cards.');
      return;
    }

    const button = document.getElementById('save-card-preferences-btn');
    const originalText = button.textContent;
    button.textContent = 'Saving...';
    button.disabled = true;

    // Get project identifier from window variable or URL
    const projectId = window.projectIdentifier ||
                     window.location.pathname.match(/projects\/([^\/]+)/)[1];

    fetch(`/projects/${projectId}/agile_board/save_card_preferences`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      body: JSON.stringify({
        card_fields: selectedFields
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        button.textContent = '✓ Saved!';
        setTimeout(() => {
          button.textContent = originalText;
          button.disabled = false;
        }, 2000);
      } else {
        throw new Error(data.error || 'Failed to save preferences');
      }
    })
    .catch(error => {
      console.error('Error saving card preferences:', error);
      alert('Failed to save card preferences: ' + error.message);
      button.textContent = originalText;
      button.disabled = false;
    });
  };

  window.resetCardConfiguration = function() {
    // Reset to default fields
    const defaultFields = ['id', 'subject', 'priority', 'assigned_to', 'story_points'];
    const checkboxes = document.querySelectorAll('.column-checkbox');

    checkboxes.forEach(checkbox => {
      checkbox.checked = defaultFields.includes(checkbox.value);
    });

    // Apply the reset configuration
    applyCardConfiguration();
  };

  window.updateCardPreview = function() {
    // Could add a live preview here in the future
    // For now, just update button states
    const selectedFields = getSelectedCardFields();
    const applyBtn = document.getElementById('apply-card-config-btn');
    const saveBtn = document.getElementById('save-card-preferences-btn');

    if (selectedFields.length === 0) {
      applyBtn.disabled = true;
      saveBtn.disabled = true;
    } else {
      applyBtn.disabled = false;
      saveBtn.disabled = false;
    }
  };

  function getSelectedCardFields() {
    const selectedFields = [];
    const checkboxes = document.querySelectorAll('.column-checkbox:checked');

    checkboxes.forEach(checkbox => {
      selectedFields.push(checkbox.value);
    });

    return selectedFields;
  }

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeFilters);
  } else {
    initializeFilters();
  }

})();