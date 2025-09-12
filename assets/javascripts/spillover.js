// Spillover functionality for Sprint Board Pro
(function() {
  'use strict';

  // Show spillover modal (Agile Board)
  window.showSpilloverModal = function() {
    const modal = document.getElementById('spillover-modal');
    if (modal) {
      modal.style.display = 'flex';
      document.body.classList.add('modal-open');
    }
  };

  // Hide spillover modal (Agile Board)
  window.hideSpilloverModal = function() {
    const modal = document.getElementById('spillover-modal');
    if (modal) {
      modal.style.display = 'none';
      document.body.classList.remove('modal-open');
      // Reset form
      const form = document.getElementById('selective-spillover-form');
      if (form) {
        form.reset();
        // Uncheck all checkboxes
        const checkboxes = form.querySelectorAll('input[type="checkbox"]');
        checkboxes.forEach(cb => cb.checked = false);
      }
    }
  };

  // Show spillover modal (Sprint Show page)
  window.showSprintSpilloverModal = function() {
    const modal = document.getElementById('sprint-spillover-modal');
    if (modal) {
      modal.style.display = 'flex';
      document.body.classList.add('modal-open');
    }
  };

  // Hide spillover modal (Sprint Show page)
  window.hideSprintSpilloverModal = function() {
    const modal = document.getElementById('sprint-spillover-modal');
    if (modal) {
      modal.style.display = 'none';
      document.body.classList.remove('modal-open');
      // Reset form
      const form = document.getElementById('sprint-selective-spillover-form');
      if (form) {
        form.reset();
        // Uncheck all checkboxes
        const checkboxes = form.querySelectorAll('input[type="checkbox"]');
        checkboxes.forEach(cb => cb.checked = false);
      }
    }
  };

  // Toggle all incomplete tasks (Agile Board)
  window.toggleAllIncomplete = function(checked) {
    const checkboxes = document.querySelectorAll('.incomplete-task-checkbox');
    checkboxes.forEach(function(checkbox) {
      checkbox.checked = checked;
    });
    updateSubmitButton();
  };

  // Toggle all incomplete tasks (Sprint Show page)
  window.toggleAllIncompleteSprintShow = function(checked) {
    const checkboxes = document.querySelectorAll('.incomplete-task-checkbox-sprint');
    checkboxes.forEach(function(checkbox) {
      checkbox.checked = checked;
    });
    updateSubmitButtonSprintShow();
  };

  // Update submit button state based on selection (Agile Board)
  function updateSubmitButton() {
    const form = document.getElementById('selective-spillover-form');
    if (!form) return;

    const checkedBoxes = form.querySelectorAll('.incomplete-task-checkbox:checked');
    const submitButton = form.querySelector('input[type="submit"]');
    
    if (submitButton) {
      submitButton.disabled = checkedBoxes.length === 0;
      submitButton.textContent = checkedBoxes.length > 0 
        ? `Move ${checkedBoxes.length} Selected Task${checkedBoxes.length === 1 ? '' : 's'}` 
        : 'Move Selected Tasks';
    }
  }

  // Update submit button state based on selection (Sprint Show page)
  function updateSubmitButtonSprintShow() {
    const form = document.getElementById('sprint-selective-spillover-form');
    if (!form) return;

    const checkedBoxes = form.querySelectorAll('.incomplete-task-checkbox-sprint:checked');
    const submitButton = form.querySelector('#sprint-move-selected-btn');
    
    if (submitButton) {
      submitButton.disabled = checkedBoxes.length === 0;
      submitButton.textContent = checkedBoxes.length > 0 
        ? `Move ${checkedBoxes.length} Selected Task${checkedBoxes.length === 1 ? '' : 's'}` 
        : 'Move Selected Tasks';
    }
  }

  // Close modal when clicking outside
  function setupModalEvents() {
    // Agile Board modal
    const modal = document.getElementById('spillover-modal');
    if (modal) {
      modal.addEventListener('click', function(e) {
        if (e.target === modal) {
          hideSpilloverModal();
        }
      });
    }

    // Sprint Show modal
    const sprintModal = document.getElementById('sprint-spillover-modal');
    if (sprintModal) {
      sprintModal.addEventListener('click', function(e) {
        if (e.target === sprintModal) {
          hideSprintSpilloverModal();
        }
      });
    }

    // Close modal on Escape key
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape') {
        if (modal && modal.style.display !== 'none') {
          hideSpilloverModal();
        }
        if (sprintModal && sprintModal.style.display !== 'none') {
          hideSprintSpilloverModal();
        }
      }
    });
  }

  // Setup form validation
  function setupFormValidation() {
    // Agile Board form
    const form = document.getElementById('selective-spillover-form');
    if (form) {
      // Add change listeners to checkboxes
      const checkboxes = form.querySelectorAll('.incomplete-task-checkbox');
      checkboxes.forEach(function(checkbox) {
        checkbox.addEventListener('change', function() {
          updateSubmitButton();
          updateSelectAllState();
        });
      });

      // Initial state
      updateSubmitButton();

      // Form submit confirmation
      form.addEventListener('submit', function(e) {
        const checkedBoxes = form.querySelectorAll('.incomplete-task-checkbox:checked');
        if (checkedBoxes.length === 0) {
          e.preventDefault();
          alert('Please select at least one task to move.');
          return false;
        }

        const taskCount = checkedBoxes.length;
        const sprintName = form.dataset.targetSprint || 'next sprint';
        const confirmMessage = `Are you sure you want to move ${taskCount} selected task${taskCount === 1 ? '' : 's'} to ${sprintName}?`;
        
        if (!confirm(confirmMessage)) {
          e.preventDefault();
          return false;
        }
      });
    }

    // Sprint Show form
    const sprintForm = document.getElementById('sprint-selective-spillover-form');
    if (sprintForm) {
      // Add change listeners to checkboxes
      const sprintCheckboxes = sprintForm.querySelectorAll('.incomplete-task-checkbox-sprint');
      sprintCheckboxes.forEach(function(checkbox) {
        checkbox.addEventListener('change', function() {
          updateSubmitButtonSprintShow();
          updateSelectAllStateSprintShow();
        });
      });

      // Initial state
      updateSubmitButtonSprintShow();

      // Form submit confirmation
      sprintForm.addEventListener('submit', function(e) {
        const checkedBoxes = sprintForm.querySelectorAll('.incomplete-task-checkbox-sprint:checked');
        if (checkedBoxes.length === 0) {
          e.preventDefault();
          alert('Please select at least one task to move.');
          return false;
        }

        const taskCount = checkedBoxes.length;
        const confirmMessage = `Are you sure you want to move ${taskCount} selected task${taskCount === 1 ? '' : 's'} to the next sprint?`;
        
        if (!confirm(confirmMessage)) {
          e.preventDefault();
          return false;
        }
      });
    }
  }

  // Update select all checkbox state based on individual selections (Agile Board)
  function updateSelectAllState() {
    const selectAllCheckbox = document.getElementById('select_all_incomplete');
    const taskCheckboxes = document.querySelectorAll('.incomplete-task-checkbox');
    const checkedTaskBoxes = document.querySelectorAll('.incomplete-task-checkbox:checked');

    if (!selectAllCheckbox) return;

    if (checkedTaskBoxes.length === 0) {
      selectAllCheckbox.checked = false;
      selectAllCheckbox.indeterminate = false;
    } else if (checkedTaskBoxes.length === taskCheckboxes.length) {
      selectAllCheckbox.checked = true;
      selectAllCheckbox.indeterminate = false;
    } else {
      selectAllCheckbox.checked = false;
      selectAllCheckbox.indeterminate = true;
    }
  }

  // Update select all checkbox state based on individual selections (Sprint Show)
  function updateSelectAllStateSprintShow() {
    const selectAllCheckbox = document.getElementById('select_all_incomplete_sprint');
    const taskCheckboxes = document.querySelectorAll('.incomplete-task-checkbox-sprint');
    const checkedTaskBoxes = document.querySelectorAll('.incomplete-task-checkbox-sprint:checked');

    if (!selectAllCheckbox) return;

    if (checkedTaskBoxes.length === 0) {
      selectAllCheckbox.checked = false;
      selectAllCheckbox.indeterminate = false;
    } else if (checkedTaskBoxes.length === taskCheckboxes.length) {
      selectAllCheckbox.checked = true;
      selectAllCheckbox.indeterminate = false;
    } else {
      selectAllCheckbox.checked = false;
      selectAllCheckbox.indeterminate = true;
    }
  }

  // Initialize spillover functionality when DOM is ready
  document.addEventListener('DOMContentLoaded', function() {
    setupModalEvents();
    setupFormValidation();
  });

  // JIRA-like animations for task movement (optional enhancement)
  function animateTaskMovement(taskElement) {
    if (!taskElement) return;
    
    taskElement.classList.add('moving-to-next-sprint');
    setTimeout(function() {
      taskElement.style.opacity = '0.5';
      taskElement.style.transform = 'translateX(20px)';
    }, 100);
    
    setTimeout(function() {
      taskElement.style.display = 'none';
    }, 500);
  }

  // Handle successful spillover response (for AJAX responses)
  window.handleSpilloverSuccess = function(response) {
    hideSpilloverModal();
    if (response.moved_count > 0) {
      // Show success message
      const message = `Successfully moved ${response.moved_count} task${response.moved_count === 1 ? '' : 's'} to ${response.target_sprint}`;
      showNotification(message, 'success');
      
      // Optionally reload the page to show updated state
      setTimeout(function() {
        window.location.reload();
      }, 1500);
    }
  };

  // Simple notification system (can be enhanced)
  function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `spillover-notification ${type}`;
    notification.textContent = message;
    notification.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      background: ${type === 'success' ? '#4CAF50' : type === 'error' ? '#f44336' : '#2196F3'};
      color: white;
      padding: 12px 20px;
      border-radius: 4px;
      z-index: 10000;
      box-shadow: 0 2px 10px rgba(0,0,0,0.2);
    `;

    document.body.appendChild(notification);

    // Remove after 3 seconds
    setTimeout(function() {
      if (notification.parentNode) {
        notification.parentNode.removeChild(notification);
      }
    }, 3000);
  }
})();