<?php
session_start();
session_unset();
session_destroy();
header("Location: support_login.php");
exit();
?>