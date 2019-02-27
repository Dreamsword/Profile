<!DOCTYPE html>
<html lang="en">

<head>

<?php
    include('auth.php');
    require('db.php');
    ?>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
<meta name="description" content="">
<meta name="author" content="">

<title>AMPortal</title>

<!-- Bootstrap core CSS -->
<link href="vendor/bootstrap/css/bootstrap.min.css" rel="stylesheet">

<!-- Custom fonts -->
<link href="vendor/font-awesome/css/font-awesome.min.css" rel="stylesheet">
<link href="vendor/devicons/css/devicons.min.css" rel="stylesheet">
<link href="vendor/simple-line-icons/css/simple-line-icons.css" rel="stylesheet">
<script src="vendor/jquery/jquery-latest.js"></script>

<!-- Custom styles -->
<link href="css/amportal.css" rel="stylesheet">

<script>
// Plus, Minus Change
$(function() {
  $('.panel-title').click(function() {
						  $(this).find('.fa-plus,.fa-minus').toggleClass('fa-plus').toggleClass('fa-minus');
						  });
  });

</script>

<style>

.resume-content {
	color: #2f2f2f;
}

.panel-group {
	padding: 20px;
}

.pre-scrollable::-webkit-scrollbar-track {
	-webkit-box-shadow: inset 0 0 6px rgba(0,0,0,0.3);
	background-color: #2f2f2f;
}

.pre-scrollable::-webkit-scrollbar {
width: 10px;
	background-color: #2f2f2f;
}

.pre-scrollable::-webkit-scrollbar-thumb {
	background-color: #1cb0be;
}

.loadMore {
	padding: 10px;
	text-align: center;
	background-color: #1cb0be;
	color: #fff;
	transition: all 400ms ease-in-out;
	-webkit-transition: all 400ms ease-in-out;
	-moz-transition: all 400ms ease-in-out;
	-o-transition: all 400ms ease-in-out;
	text-decoration: none;
	display: block;
	margin: 10px 0;
}

.loadMore:hover {
	background-color: #fff;
	color: #1cb0be;
	text-decoration: none;
}

</style>

</head>

<body id="page-top">

<form method="post">
<input type="hidden" name="amselect" value="select am" />
<input type='image' name="amselect" value="select am" src='/img/arrow-back.png' alt=''>
</form>

<nav class="navbar navbar-expand-lg navbar-dark bg-primary fixed-top" id="sideNav">

<div class="navbar-brand">
<span class="d-block d-lg-none"></span>
<span class="d-none d-lg-block">
<form method="post">
<input type="hidden" name="amselect" value="Tyron Lecki" />
<input class='img-fluid img-profile rounded-circle mx-auto mb-2' type='image' id='imgT' name="amselect" value="Tyron Lecki" src='/img/Tyron-Lecki-Senior-Account-Manager.jpg' style="width: 60%" alt=''>
</form>
</span>
</div>
<div class="navbar-brand">
<span class="d-block d-lg-none"></span>
<span class="d-none d-lg-block">
<form method="post">
<input type="hidden" name="amselect" value="Kaamilah Achmat" />
<input class='img-fluid img-profile rounded-circle mx-auto mb-2' type='image' id='imgK' name="amselect" value="Kaamilah Achmat" src='/img/Kaamilah-Achmat-Senior-Account-Manager.jpg' style="width: 60%" alt=''>
</form>
</span>
</div>
<div class="navbar-brand">
<span class="d-block d-lg-none"></span>
<span class="d-none d-lg-block">
<form method="post">
<input type="hidden" name="amselect" value="Siddharth Bawa" />
<input class='img-fluid img-profile rounded-circle mx-auto mb-2' type='image' id='imgS' name="amselect" value="Siddharth Bawa" src='/img/Siddharth-Bawa-Senior-Account-Manager.jpg' style="width: 60%" alt=''>
</form>
</span>
</div>

<?php
    $h = 0;
    
    $am = $_POST['amselect'];
    
    $Customers = $con->query("SELECT INFORMATION_SCHEMA.SCHEMATA.SCHEMA_NAME, users.amportal.customer, users.amportal.amName from INFORMATION_SCHEMA.SCHEMATA inner join users.amportal on INFORMATION_SCHEMA.SCHEMATA.SCHEMA_NAME=users.amportal.customer where amName = '$am' order by customer asc;");
    if ($Customers !== false) {
        while ($cRow = $Customers->fetch_assoc()) {
            $cResult[] = $cRow;
        }
    } else {
        $am = 'Unknown';
    }
    
    ?>
<button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
<span class="navbar-toggler-icon"></span>
</button>
<div class="collapse navbar-collapse pre-scrollable" id="navbarSupportedContent">
<ul class="navbar-nav">
<?php
    foreach ($cResult as $key => $cust) {
        echo "<li class='nav-item'>
		<a class='nav-link js-scroll-trigger' id='customer' href='#" . $h . "'>" . $cust['customer'] . "</a>
		</li>";
        $h++;
    }
    ?>
</ul>
</div>
</nav>

<?php
    $person1Tickets = $con->query("SELECT * from `company`.zoho where agent = 'person1';");
    while ($row = $person1Tickets->fetch_assoc()) {
        $result[] = $row;
        unset($row);
        unset($result);
    }
    
    $person2Tickets = $con->query("SELECT * from `company`.zoho where agent = 'person2';");
    while ($row = $person2Tickets->fetch_assoc()) {
        $result[] = $row;
        unset($row);
        unset($result);
    }
    
    $person3Tickets = $con->query("SELECT * from `company`.zoho where agent = 'person3';");
    while ($row = $person3Tickets->fetch_assoc()) {
        $result[] = $row;
        unset($row);
        unset($result);
    }
    
    $totalTickets = $con->query("SELECT count(*) as count from `company`.zoho;");
    while ($totalRow = $totalTickets->fetch_assoc()) {
        $totalResult[] = $totalRow;
    }
    
    if ($am == 'person1') {
        echo "
		<script>
		document.getElementById('imgT').style.width = '100%';
		</script>
		<div class='container-fluid p-0'>
		<section class='resume-section p-3 p-lg-4 d-flex d-column' id='about'>
		<div class='col-md-12'>
		<h1 class='mb-0'>Firstname
		<span class='text-primary'>Lastname</span>
		</h1>
		<div class='subheading mb-3'>Company Name · 011 000 0001 · 082 000 0005 ·
		<a href='mailto:person1@example.com'>person1@example.com</a>
		</div>
		<p class='mb-5'>Senior Account Manager.</p>
		<table width='90%'>
		<tr><th style='color:#2f2f2f'>ID</th><th style='color: #2f2f2f'>Subject</th><th style='color: #2f2f2f'>Status</th></tr>";
        foreach ($ttResult as $key => $tTicket) {
            echo "
			<tr style='border-bottom: 1px solid #2f2f2f; align-right'>
			<td style='padding: 5px 0px 5px 0px; color: #2f2f2f'> <a target='_blank' href=" . $tTicket['URL'] . ">" . $tTicket['ID'] . "</a> </td>", "<td style='color: #2f2f2f'>". $tTicket['subject'] . "</td> ", "<td style='color: #2f2f2f'>". $tTicket['status'] . "</td>
			</tr>
			";
        }
        echo "
		</table>
		</div>
		</section>
		";
    } elseif ($am == 'person2') {
        echo "
		<script>
		document.getElementById('imgK').style.width = '100%';
		</script>
		<div class='container-fluid p-0'>
		<section class='resume-section p-3 p-lg-4 d-flex d-column' id='about'>
		<div class='col-md-12'>
		
		<h1 class='mb-0'>Firstname
		<span class='text-primary'>Lastname</span>
		</h1>
		<div class='subheading mb-3'>Company Name · 011 000 0002 · 082 000 0002 ·
		<a href='mailto:person2@example.com'>person2@example.com</a>
		</div>
		<p class='mb-5'>Senior Account Manager.</p>
		<table width='90%'>
		<tr><th style='color:#2f2f2f'>ID</th><th style='color: #2f2f2f'>Subject</th><th style='color: #2f2f2f'>Status</th></tr>";
        foreach ($ktResult as $key => $kTicket) {
            echo "
			<tr style='border-bottom: 1px solid #2f2f2f; align-right'>
			<td style='padding: 5px 0px 5px 0px; color: #2f2f2f'> <a target='_blank' href=" . $kTicket['URL'] . ">" . $kTicket['ID'] . "</a> </td>", "<td style='color: #2f2f2f'>". $kTicket['subject'] . "</td> ", "<td style='color: #2f2f2f'>". $kTicket['status'] . "</td>
			</tr>
			";
        }
        echo "
		</table>
		</div>
		</section>
		";
    } elseif ($am == 'person3') {
        echo "
		<script>
		document.getElementById('imgS').style.width = '100%';
		</script>
		<div class='container-fluid p-0'>
		<section class='resume-section p-3 p-lg-4 d-flex d-column' id='about'>
		<div class='col-md-12'>
		
		<h1 class='mb-0'>Firstname
		<span class='text-primary'>Lastname</span>
		</h1>
		<div class='subheading mb-3'>Rocketseed SA · 011 000 0003 · 072 000 0009 ·
		<a href='mailto:person3@example.com'>person3@example.com</a>
		</div>
		<p class='mb-5'>Senior Account Manager.</p>
		<table width='90%'>
		<tr><th style='color:#2f2f2f'>ID</th><th style='color: #2f2f2f'>Subject</th><th style='color: #2f2f2f'>Status</th></tr>";
        foreach ($stResult as $key => $sTicket) {
            echo "
			<tr style='border-bottom: 1px solid #2f2f2f; align-right'>
			<td style='padding: 5px 0px 5px 0px; color: #2f2f2f'> <a target='_blank' href=" . $sTicket['URL'] . ">" . $sTicket['ID'] . "</a> </td>", "<td style='color: #2f2f2f'>". $sTicket['subject'] . "</td> ", "<td style='color: #2f2f2f'>". $sTicket['status'] . "</td>
			</tr>
			";
        }
        echo "
		</table>
		</div>
		</section>
		";
    } else {
        echo "
		<div class='container-fluid p-0'>
		<section class='resume-section p-3 p-lg-4 d-flex d-column' id='about'>
		<div class='col-md-12'>
		
		<h1 class='mb-0'>Select
		<span class='text-primary'>AM</span>
		</h1>
		<div class='subheading mb-5'>Company Name ·
		<a href='mailto:supportza@example.com'>supportza@example.com</a>
		</div>
		<table width='60%'>
		<tr><th style='color:#2f2f2f; text-align: center'>Open Tickets</th><th style='color:#2f2f2f; text-align: center'>person1</th><th style='color:#2f2f2f; text-align: center'>Person2</th><th style='color:#2f2f2f; text-align: center'>Person3</th></tr>";
        foreach ($totalResult as $key => $totalTicket) {
            echo "
			<tr style='border-bottom: 1px solid #2f2f2f; align-right'>
			<td style='padding: 5px 0px 5px 0px; color: #2f2f2f; text-align: center'>" . $totalTicket['count'] . " </td> <td style='padding: 5px 0px 5px 0px; color: #2f2f2f; text-align: center'>" . mysqli_num_rows($person1Tickets) . "</td><td style='padding: 5px 0px 5px 0px; color: #2f2f2f; text-align: center'>" . mysqli_num_rows($person2Tickets) . "</td> <td style='padding: 5px 0px 5px 0px; color: #2f2f2f; text-align: center'>" . mysqli_num_rows($person3Tickets) . "</td>
			</tr>
			";
        }
        echo "
		</table>
		</div>
		</section>
		";
    }
    
    $h = 0;
    $i = 1;
    foreach ($cResult as $key => $cust) {
        $company = $cust['customer'];
        $accName = strtolower($company);
        $banners = $con->query("SELECT bannerName, date, url from `$accName`.account_health_banners where date < CURDATE() - INTERVAL 90 day and assigned = 'yes' limit 10;");
        if ($banners !== false) {
            while ($bRow = $banners->fetch_assoc()) {
                $bResult[] = $bRow;
            }
        } else {
            continue;
        }
        if (mysqli_num_rows($banners) >= 1) {
            $bNumber = '1';
        } else {
            $bNumber = '0';
        }
        
        $tracked = $con->query("SELECT url, bannerName, date from `$accName`.account_health_banners where url not like '0' and tracked = 'Not Tracked' limit 10;");
        if ($tracked !== false) {
            while ($tRow = $tracked->fetch_assoc()) {
                $tResult[] = $tRow;
            }
        } else {
            continue;
        }
        if (mysqli_num_rows($tracked) >= 1) {
            $tNumber = '1';
        } else {
            $tNumber = '0';
        }
        
        $basicReport = $con->query("SELECT MAX(activeSenders), MAX(totalEmails), MAX(brandedEmails), MAX(unBrandedEmails), MAX(autoCreatedSenders), MAX(totalSeats) as autoCreatedSenders from `$accName`.report_basic;");
        if ($basicReport !== false) {
            $brResult = $basicReport->fetch_row();
        } else {
            continue;
        }
        
        $noBranding = $con->query("SELECT ID, email from `$accName`.account_health_branding;");
        if ($noBranding !== false) {
            while ($nbRow = $noBranding->fetch_assoc()) {
                $nbResult[] = $nbRow;
            }
        } else {
            continue;
        }
        if (mysqli_num_rows($noBranding) >= 1) {
            $nbNumber = '1';
        } else {
            $nbNumber = '0';
        }
        
        echo "
		<section class='resume-section p-3 p-lg-4 d-flex flex-column' id='" . $h . "'>
		";
        
        if ($am !== 'select am') {
            echo "
			<div class='mb-2'>
			<h2 class='mb-3'>" . $company . "</h2>
			</div>
			";
            
            echo "
			<div class='resume-content'>
			<div class='row lg-12' style='padding-bottom: 20px;'>
			<div class='col-md-2 col-sm-4 col-xs-6'>
			<div>
			<i class='fa fa-paper-plane-o'></i> Total Sent
			</div>
			<div style='margin-left: 30px;'>" . $brResult[1] . " </div>
			</div>
			<div class='col-md-2 col-sm-4 col-xs-6'>
			<div>
			<i class='fa fa-envelope'></i> Branded
			</div>
			<div style='margin-left: 25px;'>" . $brResult[2] . " </div>
			</div>
			<div class='col-md-2 col-sm-4 col-xs-6'>
			<div>
			<i class='fa fa fa-envelope-o'></i> Unbranded
			</div>
			<div style='margin-left: 40px;'>" . $brResult[3] . " </div>
			</div>
			<div class='col-md-2 col-sm-4 col-xs-6'>
			<div>
			<i class='fa fa-user'></i> Active Senders
			</div>
			<div style='margin-left: 50px;'>" . $brResult[0] . " </div>
			</div>
			<div class='col-md-2 col-sm-4 col-xs-6'>
			<div>
			<i class='fa fa-address-card-o'></i> Total Seats
			</div>
			<div style='margin-left: 35px;'>" . $brResult[5] . " </div>
			</div>
			<div class='col-md-2 col-sm-4 col-xs-6'>
			<i class='fa fa-cogs'></i> Autocreated
			<div style='margin-left: 50px;'>" . $brResult[4] . " </div>
			</div>
			</div>
			</div>
			";
            unset($brResult);
            
            echo "
			<div class='lg-12'>
			<div class='lg-2'>
			<div class='panel-group'>
			<div class='panel panel-default'>
			<div class='panel-heading'>
			<h6 class='panel-title'>
			<a data-toggle='collapse' href='#collapse" . $i . "'><i id='banOld' style='color: #fff; background-color: #D00285; padding: 2px;' class='fa fa-plus'></i> Banners older than three months</a>
			</h6>
			</div>
			<div id='collapse" . $i . "' class='panel-collapse collapse'>
			<table width='50%'>
			<tr><th style='color:#2f2f2f'>Name</th>", "<th style='color: #2f2f2f; text-align:right;'>Last Edited<th></tr>
			";
            
            if ($bNumber == 0) {
                echo "<tr style='border-bottom: 1px solid #2f2f2f; padding: 5px 0px 5px 0px;'> <td style='padding-top:7px;padding-bottom:7px;'>All Banners Are Recent</td>", "<td></td> </tr>";
            } else {
                foreach ($bResult as $key => $ban) {
                    echo "
					<tr style='border-bottom: 1px solid #2f2f2f; align-right'>
					<td style='padding: 5px 0px 5px 0px; color: #2f2f2f'> <a target='_blank' href=" . $ban['url'] . ">" . $ban['bannerName'] . "</a> </td>", "<td align='right' style='color: #2f2f2f'>". $ban['date'] . "</td>
					</tr>
					";
                }
                unset($bResult);
            }
            
            echo "
			</table>
			</div>
			</div>
			</div>
			</div>
			";
            
            $i++;
            
            echo "
			<div class='lg-2'>
			<div class='panel-group'>
			<div class='panel panel-default'>
			<div class='panel-heading'>
			<h6 class='panel-title'>
			<a data-toggle='collapse' href='#collapse" . $i . "'><i id='noTrack' style='color: #fff; background-color: #D00285; padding: 2px;' class='fa fa-plus'></i> Banners not tracking</a>
			</h6>
			</div>
			<div id='collapse" . $i . "' class='panel-collapse collapse'>
			<table width='50%'>
			<tr><th style='color:#2f2f2f'>Name</th>", "<th style='color: #2f2f2f; text-align:right'>Last Edited<th></tr>
			";
            
            if ($tNumber == 0) {
                echo "<tr style='border-bottom: 1px solid #2f2f2f; padding: 5px 0px 5px 0px;'> <td style='padding-top:7px;padding-bottom:7px;'>All Banners Tracked</td>", "<td></td> </tr>";
            } else {
                foreach ($tResult as $key => $track) {
                    echo "
					<tr style='border-bottom: 1px solid #2f2f2f; align-right'>
					<td style='padding: 5px 0px 5px 0px; color: #2f2f2f'> <a target='_blank' href=" . $track['url'] . ">" . $track['bannerName'] . "</a> </td>", "<td align='right' style='color: #2f2f2f'>". $track['date'] . "</td>
					</tr>
					";
                }
                unset($tResult);
            }
            
            echo "
			</table>
			</div>
			</div>
			</div>
			</div>
			";
            
            $i++;
            
            echo "
			<div class='lg-2'>
			<div class='panel-group'>
			<div class='panel panel-default'>
			<div class='panel-heading'>
			<h6 class='panel-title'>
			<a data-toggle='collapse' href='#collapse" . $i . "'><i id='noTrack' style='color: #fff; background-color: #D00285; padding: 2px;' class='fa fa-plus'></i> Emails with no branding</a>
			</h6>
			</div>
			<div id='collapse" . $i . "' class='panel-collapse collapse'>
			<table width='50%'>
			<tr><th style='color:#2f2f2f'>Email</th></tr>
			";
            
            if ($nbNumber == 0) {
                echo "<tr style='border-bottom: 1px solid #2f2f2f; padding: 5px 0px 5px 0px;'> <td style='padding-top:7px;padding-bottom:7px;'>All Mails Branded</td>", "<td></td> </tr>";
            } else {
                echo "
				<script>
				$(function () {
				  $('.result".$h."').slice(0, 5).show();
				  });
				$(function () {
				  $('span".$h."').click(function () {
										 $('.result".$h."').slice(0, 1000).show();
										 $(this).hide();
										 });
				  });
				</script>
				";
                foreach ($nbResult as $key => $brand) {
                    echo "
					<tr class='result".$h."' style='display:none; border-bottom: 1px solid #2f2f2f; align-right'>
					<td style='padding: 5px 0px 5px 0px; color: #2f2f2f'>" . $brand['email'] . " </td>
					</tr>
					";
                }
                echo "
				<tr>
				<td>
				<span".$h." class='loadMore'>SHOW ALL</span".$h.">
				</td>
				</tr>
				";
                unset($nbResult);
            }
            
            echo "
			</table>
			</div>
			</div>
			</div>
			</div>
			";
            
            echo "
			</section>
			";
            $i++;
            $h++;
        }
    }
    ?>

<!-- Bootstrap core JavaScript -->
<script src="vendor/bootstrap/js/bootstrap.bundle.min.js"></script>

<!-- Plugin JavaScript -->
<script src="vendor/jquery-easing/jquery.easing.min.js"></script>

<!-- Custom scripts -->
<script src="js/amportal.min.js"></script>

</body>

</html>
