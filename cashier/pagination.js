function initializeTable(tableId, paginationId, searchInputId, itemsPerPageSelectId) {
    const table = document.getElementById(tableId);
    const pagination = document.getElementById(paginationId);
    const searchInput = document.getElementById(searchInputId);
    const itemsPerPageSelect = document.getElementById(itemsPerPageSelectId);

    // Global Variables
    let currentPage = 1;
    let itemsPerPage = 10;
    let rows = Array.from(table.querySelectorAll('tbody tr'));
    let sortColumnIndex = 0;  // Initially sort by the first column (0 index)
    let sortDirection = 'asc';  // Default sort direction

    // Injecting CSS styles into the document
    const style = document.createElement('style');
    style.innerHTML = `
      /* Sort indicator arrows */
        th.sorted.asc::after {
            content: ' ↑'; /* Up arrow for ascending */
            font-size: 0.8em;
            padding-left: 5px;
        }
        
        th.sorted.desc::after {
            content: ' ↓'; /* Down arrow for descending */
            font-size: 0.8em;
            padding-left: 5px;
        }
        
        /* Font weight and style for sorted column header */
        th.sorted {
            font-weight: bold; /* Make the sorted column header bold */
            color: #007bff; /* Change color to blue (or any desired color) */
            border-bottom: 2px solid #007bff; /* Border under sorted column */
            background-color: #f0f0f0; /* Lightened background color for the sorted column */
        }
        
        /* Sorted column with ascending or descending order */
        th.sorted.asc {
            background-color: #e2f7ff; /* Brighter blue background for ascending */
        }
        
        th.sorted.desc {
            background-color: #d0e1ff; /* Lighter blue background for descending */
        }
        
        /* Optional: Styling for unsorted columns */
        th {
            cursor: pointer; /* Change cursor to indicate it's clickable */
        }
        
        /* Highlighting selected column */
        th.selected {
            background-color: #f2f2f2; /* Lighter background for selected column */
            border-left: 3px solid #ff9900; /* Orange border for selected column */
        }
        
        td.selected {
            background-color: #f2f2f2; /* Light background for selected column cells */
        }

    `;
    document.head.appendChild(style); // Append the styles to the document head

    // Filter table based on search input
    searchInput.addEventListener('input', () => {
        renderTable();
        updatePagination();
    });

    // Set items per page based on select input
    itemsPerPageSelect.addEventListener('change', () => {
        itemsPerPage = parseInt(itemsPerPageSelect.value, 10);
        currentPage = 1; // Reset to first page
        renderTable();
        updatePagination();
    });

    // Add event listeners for sorting each column header
    const headers = table.querySelectorAll('thead th');
    headers.forEach((header, index) => {
        header.addEventListener('click', () => {
            // Remove sorting arrows from all columns
            headers.forEach(header => header.classList.remove('sorted', 'asc', 'desc'));

            // Add sorting class to the clicked column
            header.classList.add('sorted');
            header.classList.add(sortDirection);  // Add asc or desc class for the arrow

            // Determine the sort direction
            if (sortColumnIndex === index) {
                // If the same column is clicked, toggle the sort direction
                sortDirection = (sortDirection === 'asc') ? 'desc' : 'asc';
            } else {
                // Otherwise, start by sorting in ascending order
                sortColumnIndex = index;
                sortDirection = 'asc';
            }
            renderTable();  // Re-render table after sorting
        });
    });

    // Initially sort the table by the first column when the page loads
    headers[sortColumnIndex].classList.add('sorted');
    headers[sortColumnIndex].classList.add(sortDirection);

    // Render table based on current page, items per page, and sorting
    function renderTable() {
        // Filter rows based on search input
        const filteredRows = rows.filter(row => {
            const text = row.textContent.toLowerCase();
            return text.includes(searchInput.value.toLowerCase());
        });

        // Sort rows if a column is selected for sorting
        if (sortColumnIndex !== null) {
            filteredRows.sort((a, b) => {
                const cellA = a.cells[sortColumnIndex].textContent.trim();
                const cellB = b.cells[sortColumnIndex].textContent.trim();

                // Attempt to parse the cell values as numbers
                const numA = parseFloat(cellA.replace(/[^0-9.-]+/g, ''));  // Remove non-numeric characters
                const numB = parseFloat(cellB.replace(/[^0-9.-]+/g, ''));  // Remove non-numeric characters

                // Check if both values are numbers
                const isNumberA = !isNaN(numA);
                const isNumberB = !isNaN(numB);

                // If both are numbers, compare them numerically
                if (isNumberA && isNumberB) {
                    return sortDirection === 'asc' ? numA - numB : numB - numA;
                }

                // Otherwise, fall back to string comparison
                return sortDirection === 'asc' ? cellA.localeCompare(cellB) : cellB.localeCompare(cellA);
            });
        }

        // Paginate the filtered and sorted rows
        const start = (currentPage - 1) * itemsPerPage;
        const end = start + itemsPerPage;
        const paginatedRows = filteredRows.slice(start, end);

        // Clear the table body
        table.querySelector('tbody').innerHTML = '';

        // Append the paginated rows
        paginatedRows.forEach(row => {
            table.querySelector('tbody').appendChild(row);
        });
    }

    // Update pagination buttons based on number of pages
    function updatePagination() {
        const filteredRows = rows.filter(row => {
            const text = row.textContent.toLowerCase();
            return text.includes(searchInput.value.toLowerCase());
        });

        const pageCount = Math.ceil(filteredRows.length / itemsPerPage);
        pagination.innerHTML = ''; // Clear pagination

        // Previous Button
        const prevButton = document.createElement('button');
        prevButton.innerText = 'Previous';
        prevButton.addEventListener('click', () => {
            if (currentPage > 1) {
                currentPage--;
                renderTable();
                updatePagination();
            }
        });
        prevButton.disabled = currentPage === 1;
        pagination.appendChild(prevButton);

        // Current Page Display
        const pageDisplay = document.createElement('span');
        pageDisplay.innerText = `Page ${currentPage} of ${pageCount}`;
        pagination.appendChild(pageDisplay);

        // Next Button
        const nextButton = document.createElement('button');
        nextButton.innerText = 'Next';
        nextButton.addEventListener('click', () => {
            if (currentPage < pageCount) {
                currentPage++;
                renderTable();
                updatePagination();
            }
        });
        nextButton.disabled = currentPage === pageCount;
        pagination.appendChild(nextButton);
    }

    // Initial render
    renderTable();
    updatePagination();
}
