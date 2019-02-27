<?php
require('db.php');
if (session_status()!=PHP_SESSION_ACTIVE) {
    session_start();
}
?>

<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Login</title>
<link rel="stylesheet" href="./css/login.css" />
<style>

#loginbutt button[type="submit"]:hover {
	cursor: pointer;
	background-color: #1cb0be !important;
	color:#fff;
	font-weight: 600;
	padding: 20px;
	width: 20%;
}

input:-webkit-autofill {
    -webkit-box-shadow: 0 0 0 1000px white inset !important;
}

</style>

</head>
<body>
<?php

if (isset($_POST['Email'])) {
    $email = stripslashes($_REQUEST['Email']);
    $email = mysqli_real_escape_string($con, $email);
    $password = stripslashes($_REQUEST['Password']);
    $password = mysqli_real_escape_string($con, $password);
    $query = "SELECT * FROM `login` WHERE Email='$email' and Password='".md5($password)."'";
    $result = mysqli_query($con, $query) or die(mysql_error());
    $info = $result->fetch_row();
    $rows = mysqli_num_rows($result);
    if ($rows==1) {
        $_SESSION['Email'] = $email;
        $_SESSION['Name'] = $info[1];
        $_SESSION['Surname'] = $info[2];
        $_SESSION['Company'] = $info[5];
        header("Location: index.php");
    } else {
        $message = "Email and/or Password incorrect.\\nTry again.";
        echo "<script>
			alert ('$message');
			window.location.href='login.php';
			</script>";
    }
} else {
    ?>

<div class="logo">
	<img width="250" height="50" src="https://3at6ja2ykxb3bo6632sdol54-wpengine.netdna-ssl.com/wp-content/uploads/2016/06/rockedseed.svg" />
</div>

<div class="form">
<h1>Welcome To The AM Portal</h1>
</br>
<form action="" method="post" name="login">
<input type="text" name="Email" placeholder="Email" required />
<input type="password" name="Password" placeholder="Password" required />
<button type="submit" value="Login" id="loginbutt" class="paging" />LOGIN</button>
<div class="support">
	<div><span style="color: #292d33;">Rocketseed | 011  691  7740</span></div>
	<div><span style="color: #292d33;">support@rocketseed.com</span></div>
	<div><span style="color: #f9f9f9;">Space</span></div>
</div>
</form>
</div>


<?php
} ?>
</body>
</html>
