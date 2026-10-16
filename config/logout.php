<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

session_unset();
session_destroy();
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Logout</title>
    <script>
        // Remove local storage items
        localStorage.removeItem('loggedin');
        localStorage.removeItem('cashier_id');

        // Optionally alert the user or log the removed item
        // alert("Local storage cleared: " + localStorage.getItem('cashier_id'));

        // Redirect to the cashier page
        window.location.href = "../";
    </script>
</head>
<body>
</body>
</html>
