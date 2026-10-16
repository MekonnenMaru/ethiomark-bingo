<?php
// Handle AJAX request
if ($_SERVER['REQUEST_METHOD'] === 'POST' && (isset($_POST['serial']) || isset($_POST['package']))) {
    $base_key = '0dN8G$kPz9HcL3u!vB1eTxQz6RmJ2s'; // 30 bytes
    $base_iv  = 'a9BvC3eF5hJ7kL1M';               // 16 bytes

    $serial = trim($_POST['serial'] ?? '');
    $package = trim($_POST['package'] ?? '');

    // Trim or fallback
    $serial_trimmed = (strlen($serial) >= 2) ? substr($serial, 0, 2) : "XX";

    // Merge to form 32-byte encryption key
    $final_Encrypt_key = $base_key . $serial_trimmed;

    // Encrypt values
    $enc_serial = !empty($serial) ? base64_encode(openssl_encrypt($serial, 'AES-256-CBC', $final_Encrypt_key, 0, $base_iv)) : '';
    $enc_package = !empty($package) ? base64_encode(openssl_encrypt($package, 'AES-256-CBC', $final_Encrypt_key, 0, $base_iv)) : '';

    // Return as JSON
    echo json_encode([
        'enc_serial' => $enc_serial,
        'enc_package' => $enc_package
    ]);
    exit;
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Encrypt Serial & Package</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.min.css">
  <style>
    body {
      font-family: Arial, sans-serif;
      background: #f9f9f9;
      padding: 2rem;
      max-width: 600px;
      margin: auto;
    }
    label {
      display: block;
      margin-top: 1rem;
    }
    input, textarea {
      width: 100%;
      padding: 10px;
      margin-top: 5px;
      border: 1px solid #ccc;
      border-radius: 5px;
    }
    button {
      margin-top: 1rem;
      padding: 10px 20px;
      background-color: #007bff;
      border: none;
      color: white;
      border-radius: 5px;
      cursor: pointer;
    }
    button:hover {
      background-color: #0056b3;
    }
    .copy-btn {
      background-color: #28a745;
      margin-left: 10px;
    }
    .copy-btn:hover {
      background-color: #218838;
    }
    .result-field {
      margin-top: 1rem;
    }
  </style>
</head>
<body>

  <h2>Encrypt Serial Number and Package</h2>
  <p>Enter at least one value to encrypt</p>

  <label for="serial">Serial Number:</label>
  <input type="text" id="serial" placeholder="Enter serial number (optional)">

  <label for="package">Package Number:</label>
  <input type="text" id="package" placeholder="Enter package number (optional)">

  <button onclick="encrypt()">Encrypt</button>

  <div id="result" style="margin-top: 2rem; display: none;">
    <div id="serial-result" class="result-field">
      <label>Encrypted Serial Number:</label>
      <textarea id="encSerial" rows="2" readonly></textarea>
      <button class="copy-btn" onclick="copyText('encSerial')">Copy</button>
    </div>

    <div id="package-result" class="result-field">
      <label>Encrypted Package Number:</label>
      <textarea id="encPackage" rows="2" readonly></textarea>
      <button class="copy-btn" onclick="copyText('encPackage')">Copy</button>
    </div>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
  <script>
    function encrypt() {
      const serial = document.getElementById('serial').value.trim();
      const packageNum = document.getElementById('package').value.trim();

      if (!serial && !packageNum) {
        Swal.fire({
          icon: 'error',
          title: 'Oops...',
          text: 'Please enter at least one value to encrypt!',
        });
        return;
      }

      const formData = new FormData();
      if (serial) formData.append('serial', serial);
      if (packageNum) formData.append('package', packageNum);

      fetch('', {
        method: 'POST',
        body: formData
      })
      .then(res => res.json())
      .then(data => {
        const resultDiv = document.getElementById('result');
        resultDiv.style.display = 'block';
        
        if (data.enc_serial) {
          document.getElementById('encSerial').value = data.enc_serial;
          document.getElementById('serial-result').style.display = 'block';
        } else {
          document.getElementById('serial-result').style.display = 'none';
        }
        
        if (data.enc_package) {
          document.getElementById('encPackage').value = data.enc_package;
          document.getElementById('package-result').style.display = 'block';
        } else {
          document.getElementById('package-result').style.display = 'none';
        }
      })
      .catch(err => {
        Swal.fire({
          icon: 'error',
          title: 'Encryption Error',
          text: 'There was an error processing your request',
        });
        console.error(err);
      });
    }

    function copyText(id) {
      const el = document.getElementById(id);
      el.select();
      document.execCommand('copy');
      
      Swal.fire({
        position: 'top-end',
        icon: 'success',
        title: 'Copied!',
        showConfirmButton: false,
        timer: 1500,
        toast: true
      });
    }
  </script>

</body>
</html>