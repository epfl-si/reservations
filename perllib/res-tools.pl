#
#========= A CHANGER POUR LES INSTALLATIONS INDIVIDUELLES =====
# CHANGER POUR LES INSTALLATIONS INDIVIDUELLES =====
$ABS_HOME		= 'https://absences.epfl.ch';
$RES_HOME		= 'https://reservations.epfl.ch';

$abs_path   = '/var/www/vhosts/app/';
$URLabs			= "${ABS_HOME}/cgi-bin/abs";
$URLres			= "${RES_HOME}/cgi-bin/res";
#==============================================================

use utf8;
use Crypt::RC4;
use Crypt::GCM;
use Crypt::Rijndael;
use Cadi::CadiDB;
use Cadi::Accreds;

#binmode (STDOUT, ':utf8');

# ----------- constantes communes -----------------
$thescript  	= $ENV{'SCRIPT_NAME'};
$querystring	= $ENV{'QUERY_STRING'};
$pathinfo    	= $ENV{'PATH_INFO'};

#	- get access params
require '/var/www/vhosts/app/private/etc/access_params';

#	ws token encryption
$useTokenRC4 	= 0;

$DATE  				= 'ponctuelle';
$DAILY 				= 'quotidienne';
$HEBDO 				= 'chaque';
$FIRST 				= 'le 1er';
$SEC   				= 'le 2e';
$TROIS 				= 'le 3e';
$QUATRE 			= 'le 4e';

$BIHEBDO 			= 'toutes les deux semaines';
$TRIHEBDO 		= 'toutes les trois semaines';
$LAST  				= 'le dernier';
%periodics  	= (
	$HEBDO,		'chaque', 
	$FIRST,		'le 1er', 
	$SEC,			'le 2ème', 
	$TROIS,		'le 3ème', 
	$QUATRE, 	'le 4ème',
	$BIHEBDO, 'toutes les deux semaines',
	$TRIHEBDO,'toutes les trois semaines',
	$LAST,		'le dernier', 
	);

@mois = (0,31,28,31,30,31,30,31,31,30,31,30,31);
@noms_jours = (
	'dimanche',
	'lundi',
	'mardi',
	'mercredi',
	'jeudi',
	'vendredi',
	'samedi',
        );
@mois_noms = (
	'',
	'Janvier',
	'Février',
	'Mars',
	'Avril',
	'Mai',
	'Juin',
	'Juillet',
	'Août',
	'Septembre',
	'Octobre',
	'Novembre',
	'Décembre',
	);
# @years = (2000..2012);
# $MAXDATE = '20300101';

# ----------- colors ---------------------------
$lightgrey	= 'lightgrey';
$teal		= 'teal';

# ----------- params graphiques -----------------
$smallh		= 8;     # ---- hauteur petits caracteres
$smallw		= 5;     # ---- largeur 
$largeh		= 15;    # ---- hauteur grands caracteres
$largew		= 10;    # ---- largeur
$offsetx 	= 10;
$offsety 	= 25;
$intercar 	= 10;

use Net::LDAP;
$ldap  = Net::LDAP->new('ldap.epfl.ch') or erreur ("new LDAP : $!");

my $Accreds  = new Cadi::Accreds ();

#_____________
sub loadargs {

	my ($querystring, @fields, $field, $name, $value);

	$query1 = $ENV{QUERY_STRING};

	if ($ENV{'REQUEST_METHOD'} && $ENV{'REQUEST_METHOD'} eq 'POST') {
		read (STDIN, $query2, $ENV{'CONTENT_LENGTH'});
	}
	$query  = $query1 . '&' . $query2;
	@fields = split (/&/, $query);
	foreach (@fields) {
		s/\+/ /g;
		s/%([0-9a-f]{2,2})/pack ("c", hex ($1))/gie;
	}
	for $field (@fields) {
		next unless ($field =~ /=/);
		($name, $value) = split(/=/, $field, 2);
		$CONTENTS{$name} .= ' ' if ($CONTENTS{$name});
		$value =~ s/^\s*//g;
		$value =~ s/\s*$//g;
		$CONTENTS{$name} .= "$value";
	}

	checkJSExploits (\%CONTENTS);

	%CONTENTS;

}

sub dbquery {
	my ($sql, @params) = @_;
	return unless sql;
	my $sth = $dbh->prepare( $sql ) or die "database fatal error prepare\n$DBI::errstr\n$sql\n";
		 $sth->execute (@params) 			or die "database fatal error : execute : $DBI::errstr";
	return $sth;
}

#_____________
sub erreur {
  my ($messg) = @_;

  return unless $messg;
warn "erreur [$CONTENTS{sciper}] :: $messg\n";
  &header if ($HEADER_DONE eq '');
  printf "<p><font color=\"red\"><b>Erreur</b></font> - %s</p>", $messg;
  &footpage;
}

#_____________
sub check_date {
	my ($date) = @_;
	
	erreur ("date vide") unless $date;
	
	$date =~ s/00000//;
	$date =~ s/\s*//g;
	
	my ($tday, $tmon, $tyear);
	if ($date =~ /\//) {
		($tday, $tmon, $tyear) = split (/\//, $date);
	} elsif ($date =~ /\./) {
		($tday, $tmon, $tyear) = split (/\./, $date);
	} else {
		$tday = substr ($date, 6, 2);
		$tmon = substr ($date, 4, 2);
		$tyear= substr ($date, 0, 4);
	}
	
	erreur ("date vide ou format erroné") unless $tday and $tmon and $tyear;
	
	$date = sprintf "%4d%02d%02d", $tyear, $tmon, $tday;
	my $i    = 0;
	my $y    = substr($date,0,4);
	my $m    = substr($date,4,2);
	my $d    = substr($date,6,2);

# - check annee bisextile "decente"
    &check_feb($y);

	$m =~ s/^0//;
   	if ($m !~ /\d/) {
	  while ($mois_noms[$i] ne $m) {
		$i++;
	  }
	  $m = $i;
   	}

	erreur ("erreur de date - mois erroné: $d, $m, $y")   if $m <= 0 or $m > 12 ;
	erreur ("erreur de date - année erronée: $d, $m, $y") if $y <= 0 ;
	erreur ("erreur de date - jour erroné: $d, $m, $y")   if $d <= 0 or $d > $mois[$m] ;

	return sprintf "%4d%02d%02d", $y, $m, $d;
}

#_____________
sub get_time {
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$mon++;
	$year += 1900;
	$crt_date = sprintf "%4d%02d%02d",$year,$mon,$mday;
    &check_feb($year);
}

#_____________
sub check_feb {
   my ($y) = @_;

   if (&isleap($y)) {
	$mois[2] = 29;
   } else {
	$mois[2] = 28;
   }
}
#_____________
sub rev_date {
	my ($date, $flag) = @_;
     if ($date eq '' or $date eq '00000000' ) {
		return;
     }

     $date =~ s/\://g;
     $date =~ s/\-//g;

     if ($flag eq '1') {
       my $m   = substr($date,4,2);
       my $day = substr($date,6,2);
       $m   =~ s/^0//;
       $day =~ s/^0//;
       
       my $suf;
       if ($lang eq 'en') {
		$suf = ($day == 1) ? "st " : "th";
	   } else {
		$suf = ($day == 1) ? "er " : "";
	   }
	   
	   $suf = '<sup>'.$suf.'</sup>' if $suf;

       if ($lang eq 'en') {
	     return (sprintf "%s&nbsp;%d%s&nbsp;%04d&nbsp;", $mois_noms[$m],, $day,  $suf, substr($date,0,4));
	   } else {
	     return (sprintf "%d%s&nbsp;%s&nbsp;%04d&nbsp;", $day,  $suf, $mois_noms[$m], substr($date,0,4));
	   }
     } elsif ($flag eq '2') {	# - 
     	if (length($date) >= 10 ) {
	 		my $ts 	   = substr($date,8,4);
	 		my $ts_txt = $ts;
	 		if ($ts eq $start_day) {
	 			$ts_txt = $lang eq 'en' ? 'start workday' : 'matin';
	 		}
	 		if ($ts eq $end_m) {
	 			$ts_txt = $lang eq 'en' ? 'noon' : 'midi';
	 		}
	 		if ($ts eq $mid_day) {
	 			$ts_txt = $lang eq 'en' ? 'afternoon' : 'après-midi';
	 		}
	 		if ($ts eq $end_day) {
	 			$ts_txt = $lang eq 'en' ? 'end workday' : 'fin journée';
	 		}
	 		my $date_name = substr(get_day_name (substr($date, 0, 8)), 0, 3);
	 		my $date_name = uc(substr($date_name,0,1)). substr($date_name,1,2);
	 		return (sprintf "$date_name. %02d/%02d/%4d %s",substr($date,6,2),substr($date,4,2),substr($date,0,4),$ts_txt);
		} else {
	 		return (sprintf "%02d/%02d/%4d",substr($date,6,2),substr($date,4,2),substr($date,0,4));
		}
     } else {
     	if (length($date) >= 10 ) {
	 		return (sprintf "%02d/%02d/%4d %s",substr($date,6,2),substr($date,4,2),substr($date,0,4),substr($date,8,4));
		} else {
	 		return (sprintf "%02d/%02d/%4d",substr($date,6,2),substr($date,4,2),substr($date,0,4));
		}
     }
}

#_____________
sub get_crt_day {
  my ($date) = @_;
  use Date::Calc qw(Day_of_Week Week_Number Day_of_Year);
  my $dnum = Day_of_Year(substr($date,0,4),substr($date,4,2),substr($date,6,2));
  return $dnum;
}

#_____________
sub get_week_nb { # numéro de semaine
	my ($date) = @_;

return unless $date;

	use Date::Calc qw(Day_of_Week Week_Number Day_of_Year);
	my $wnum = Week_Number(substr($date,0,4),substr($date,4,2),substr($date,6,2));
	return $wnum;
}

#_____________
sub isleap { # bissextile à bascule
 my $year = $_[0];
 return (($year % 400 == 0) || ($year % 4 == 0 && $year % 100 != 0))
}

#_____________
sub get_month_from_name {
  my ($name) = @_;
  my ($i)	 = 0;
  until ($mois_noms[$i] eq $name) { $i++;}
  return ($i);
}

#_____________
sub get_day_name {
  my ($date)   = @_;
  use Date::Calc qw(Day_of_Week Week_Number Day_of_Year);
  my $wday = Day_of_Week(substr($date,0,4),substr($date,4,2),substr($date,6,2)) % 7;
  return ($noms_jours[$wday]);
}

#_____________
sub get_day_index {
  my ($name) = @_;
  my ($i)	 = 0;
  until ($noms_jours[$i] eq $name) { $i++;}
  return ($i);
}

#_____________
sub get_next_n_day {
   my ($date, $n) = @_;

   return unless $date;
   return $date unless $n;

   my ($jour)     = substr($date,6,2);
   my ($mois)     = substr($date,4,2);
   my ($an)       = substr($date,0,4);
   my ($j1, $end_d, $end_m, $end_a, $tmp_date);
   $mois =~ s/^0//;
   $jour =~ s/^0//;

   $end_m = $mois;
   $end_a = $an;
   $end_d = $jour + $n;

   check_feb($an);
   until ($end_d <= $mois[$end_m] ) {
        $end_d = $end_d - $mois[$end_m];
	$end_m++;
	if ($end_m > 12) {
	  $end_m = 1;
	  $end_a++;
	}
   }
   $tmp_date = sprintf "%4d%02d%02d",$end_a, $end_m, $end_d;
   return ($tmp_date);
}

#_____________
sub get_prev_n_day {
   my ($date, $n) = @_;

#warn "get_prev_n_day :: $date, $n<=\n";
   return unless $date;
   return $date unless $n;

   my ($jour)     = substr($date,6,2);
   my ($mois)     = substr($date,4,2);
   my ($an)       = substr($date,0,4);
   my ($j1, $end_d, $end_m, $end_a, $tmp_date);
   $mois =~ s/^0//;
   $end_m = $mois;
   $end_a = $an;
   $end_d = $jour - $n;

   check_feb($an);
   until ($end_d > 0 ) {
	$end_m--;
	if ($end_m < 1) {
	  $end_m = 12;
	  $end_a--;
	}
        $end_d = $end_d + $mois[$end_m];
   }
   $tmp_date = sprintf "%4d%02d%02d",$end_a, $end_m, $end_d;
   return ($tmp_date);
}
#_____________
sub get_first_week_day {
   my ($date) = @_;
   return unless $date;

  use Date::Calc qw(Day_of_Week Week_Number Day_of_Year);
  my $j1 = Day_of_Week(substr($date,0,4),substr($date,4,2),substr($date,6,2));

   return (&get_prev_n_day($date, $j1 - 1));
}

#_____________
sub get_start_end_week {
   my ($date)     = @_;

   my ($date1)    = &get_first_week_day($date);
   my ($date2)    = &get_next_n_day ($date1, 4);
   return (sprintf "%s\t%s", $date1, $date2);
}
#_____________
sub alpha_sort {
	my ($l1, $l2);

	$l1 = $a;
	$l2 = $b;
	$l1 =~ tr /A-Z/a-z/;
	$l2 =~ tr /A-Z/a-z/;
	return ($l1 cmp $l2);
}
#_____________
sub pr_date_choice_OLD {
   my ($text, $name, $def) = @_;
   my (@days, $i);
   my ($d) = substr ($def, 8, 2);
   my ($m) = substr ($def, 5, 2);
   my ($y) = substr ($def, 0, 4);
   
   @days = (1..31);
   $d =~ s/0//;
   $m =~ s/0//;
   print "$text";
   &pr_select ("d".$name, $d, 1, 0, @days);
   &pr_select ("m".$name, $mois_noms[$m], 1, 0, @mois_noms);
   &pr_select ("y".$name, $y, 1, 0, @years);
}
#_____________
sub pr_select {
  my ($field_name, $value, $dim, $flag, @list) 	= @_;
  my ($index, $selected) ;
  print "<select name=$field_name size=$dim>\n";
  for ($index=0;$index<=$#list; $index++) {
     $selected = ($list[$index] eq $value) ? 'selected' : '';
     $disp     = ($flag) ? "$NAME{$list[$index]}" : $list[$index];
     if ($disp eq '') { next; }
     print "<option value=$list[$index] $selected>$disp\n";
  }
  print "</select>";
}
#_____________
sub pr_date {
   my ($texte, $index, $date) = @_;
   my $d = ($date) ? sprintf "%02d/%02d/%04d",substr($date,6,2),substr($date,4,2),substr($date,0,4): "";
   print qq{<a href="javascript:newWindow('date$index');">$texte
   		<img src="$commondir/.icons/cal.gif" border="0"></a> 
   		<input NAME="date$index" VALUE="$d" SIZE=10> 
   };
}
#_____________
sub draw_rect {
  my ($x1, $y1, $x2, $y2, $border, $bgcolor, $image) = @_;
  
#warn "draw_rect :: $x1, $y1, $x2, $y2, $border, $bgcolor=";
  $image = $img unless $image;
  my @topleft 	= ($x1,$y1);
  my @botright 	= ($x2,$y2);
  $image->bgcolor($bgcolor) ;
  if ($border) {
	$image->fgcolor($lightgrey)
  } else {
	$image->fgcolor(undef)
  }
  $image->rectangle(@topleft,@botright);
  if ($border) {
	 $image->moveTo($x1,$y2);
	 $image->fgcolor('darkslategray');
	 $image->lineTo($x2,$y2);
	 $image->lineTo($x2,$y1);
  }

}
#_____________
sub draw_text {
  my ($x, $y, $fgcolor, $txt, $image) = @_;

#warn "draw_text :: $x, $y, $fgcolor, $txt=";
  
  $image = $img unless $image;
  $fgcolor = 'black' unless $fgcolor;
  $image->moveTo($x,$y);
  $image->fgcolor($fgcolor);
  $image->string($txt);

}
#_____________
sub draw_line {
  my ($x1, $y1, $x2, $y2, $fgcolor, $image) = @_;
 
#warn "draw_line :: $x1, $y1, $x2, $y2, $fgcolor=";

  $image = $img unless $image;
  $image->moveTo($x1,$y1);
  my $fgcolor = 'black';
  $image->fgcolor($fgcolor);
  $image->lineTo($x2,$y2);

}
#_____________
sub debug {
  my (@keys) = keys(%CONTENTS);
  my ($key);

  @keys = sort @keys;

  foreach $key (@keys) {
    warn "DEBUG CONTENTS :: $key = $CONTENTS{$key}\n";
  }
  warn "-------------\n";
  @keys = keys (%ENV);
  @keys = sort @keys;
  foreach $key (@keys) {
    warn "DEBUG ENV :: $key = $ENV{$key}\n";
  }
}
#_____________
sub uniq {
  my (@liste) = @_;

  my %count;
  my @sorted = grep { ++$count{$_} < 2} @liste;
  return @sorted;
}

#_____________
sub checkLDAP {
 my ($email) = @_;

	return 1 unless $email =~ /epfl\.ch$/;
	my $msg = $ldap->search(
	  base 	 => 'c=ch',
	  filter => "(&(mail=$email)(objectclass=person))"
	);
	if ($msg->entries) {
		return 1
	} else {
		return 0
	}
}
#_____________
sub mailto {
  my ($dest, $subj, $msg) = @_;
warn "absres :: tools.pl : mailto :DEBUG=$DEBUG: dest=$dest, subj=$subj=";

  my %mail;
  $mail{From} 	 = $generic_mail; 
  
  my $to;
  my $errmail;
  foreach my $mail (split(/,/, $dest)) {
 	if (checkLDAP($mail)) {
 		$to .= ",$mail"  
 	} else {
 		$errmail .= ",$mail"
 	}
  }
  $to =~ s/^,//;
  erreur ("mailto :: aucun destinataire") unless $to;
  $errmail =~ s/^,//;
  
  $mail{To}   	 = $DEBUG ? 'ion.cionca@epfl.ch' : $to;
  $mail{Smtp} 	 = 'mail.epfl.ch';
  $mail{Subject} = $subj;
  $mail{Message} = $msg;	
  $mail{'Content-Transfer-Encoding'} = '8bit';	
  if (sendmail (%mail)) {
     if ($Mail::Sendmail::error) {
		warn "send_mail  :: ** ERR 1 [$Mail::Sendmail::error]";
     } else {
	   $msg =~ s/\n/;/g;
     }
  } else {
	warn "send_mail  :: ** ERR 2 [$Mail::Sendmail::error]";
  }

  print qq{
		<hr>Cette information a été transmise à: $to
  };
  print qq{
  <p><b>Note </b> - adresse(s) invalide(s) ou inexistante(s) : $errmail<br>Veuillez effectuer les corrections sur votre fiche de remplacements ou vos données personnelles</p>
  } if $errmail;
}

#_____________
sub check_empty {
  my ($var, $var_name) = @_;

  erreur ("champ <b>$var_name</b> vide") if ($var eq '');
}

#_____________
sub removeaccents {
  my ($str) = @_;
  $str =~ tr/\200-\237//d;
  $str =~ tr/\240-\377/"                               AAAAAA CEEEEIIIIDNOOOOO OUUUUY  aaaaaa ceeeeiiiionooooo ouuuuy y"/;
  return $str;
}

#_____________
sub get_obj_tokens {
	my ($objID) = @_;
	return '' unless $objID;

	$dbh = dbconnect ('reservations') unless defined $dbh;

	my $objTokens;
	my $sql = qq{select * from tokens where obj_id=? };
	my $sth = dbquery($sql, $objID);
	while (my $data = $sth->fetchrow_hashref) { 
		$objTokens->{$data->{id}} = $data;
	}	
	return $objTokens;
}

#------
sub getObjIDFromToken {
	my ($token) = @_;
	return '' unless $token;
	return getObjIDFromTokenRC4($token) if $useTokenRC4;
	return getObjIDFromTokenGCM($token);
}

#------
sub getObjIDFromTokenRC4 {
	my ($token) = @_;
	return '' unless $token;
warn "--> getObjIDFromTokenRC4 : $token\n";

	my $rc4  = Crypt::RC4->new ($rc4key);
	my $rnd  = $rc4->RC4 (pack ("H*", substr ($token, 0, 12)));
	   $rc4  = Crypt::RC4->new ($rnd);
	return split /:/, $rc4->RC4 (pack ("H*", substr ($token, 12)));

}
#------
sub getObjIDFromTokenGCM {
	my ($token) = @_;
	return '' unless $token;
warn "--> getObjIDFromTokenGCM : token=$token\n";

	my ($crypt_token, $iv, $tag) = split /:/, $token;
  my $gcm = Crypt::GCM->new (
       -key => pack ('H*', $aeskey),
    -cipher => 'Crypt::Rijndael',
  );
	$gcm->set_iv(pack 'H*', $iv);
  $gcm->aad('');
  $gcm->tag(pack 'H*', $tag);

  my $decrypttoken = $gcm->decrypt (pack 'H*', $crypt_token);
warn "--> getObjIDFromTokenGCM : decrypttoken=$decrypttoken\n";
  return split /:/, $decrypttoken;

}

#--------
sub getObjRes {
  my ($objID, $d1, $d2) = @_;

  return unless $objID and $d1 and $d2;

  my @rsrv;
   # - crt res
  $d1 = substr($d1,0,4)."-".substr($d1,4,2)."-".substr($d1,6,2);
  $d2 = substr($d2,0,4)."-".substr($d2,4,2)."-".substr($d2,6,2);
  my $sql = qq{select * from dates, res where 
  	dates.date >= ?  and 
  	dates.date <= ?  and
  	res.id=dates.res_id and
  	res.obj_id = ?  	
  };
	my $sth = dbquery($sql, $d1, $d2, $objID);

  while (my $data = $sth->fetchrow_hashref) {

		unless ($data->{unite}) {
			my @accreds = sort {$a->{ordre} <=> $b->{ordre}} $Accreds->getAccreds ($data->{sciper});
			$data->{unite} = $accreds[0]->{unite};
		}

		my $item = {
			res_id	=> $data->{id},
			nom			=> $data->{nom},
			obj_id	=> $data->{obj_id},
			sciper	=> $data->{sciper},
			periodic=> $data->{periodic},
			jour		=> $data->{jour},
			date		=> $data->{date},
			datedeb	=> $data->{datedeb},
			datefin	=> $data->{datefin},
			hdeb		=> $data->{hdeb},
			hfin		=> $data->{hfin},
			unite		=> $data->{unite},
			pool		=> $data->{pool},
		};
		push @rsrv, $item;
#warn "--> getObjRes : $data->{unite}, $data->{nom}, $data->{hdeb}, $data->{hfin}, redid=$data->{id}\n";
  }
  $sth->finish;
  
  @rsrv;
}

#__________________
sub getObj {
  my ($objID) = @_;
  return unless $objID;
  
  my @objIDs = split (',', $objID);
  my $ids    = join "','", @objIDs;

  my %obj;
  my $sql = qq{select * from obj where id in ('$ids')};
	my $sth = dbquery($sql);

  while (my $data = $sth->fetchrow_hashref) {
  	$obj{$data->{id}}->{objdata} = $data;
  }

  %obj

}

#----
sub get_dates_from_name {
  my ($periodic, $day_name, $d1, $d2) = @_;

  my @ret_dates	= ();
  my $tmp_d 	= &check_date($d1);

  if ($periodic eq $TRIHEBDO) {
		while ($tmp_d le $d2) {
			my $tmp_dayname = get_day_name($tmp_d);
			if ($tmp_dayname eq $day_name) {
				push (@ret_dates, $tmp_d);
				$tmp_d = &get_next_n_day($tmp_d, 21);
			} else {
				$tmp_d = &get_next_n_day($tmp_d, 1);
			}
    }
    return (@ret_dates);
  }
  if ($periodic eq $BIHEBDO) {
		while ($tmp_d le $d2) {
			my $tmp_dayname = get_day_name($tmp_d);
			if ($tmp_dayname eq $day_name) {
				push (@ret_dates, $tmp_d);
				$tmp_d = &get_next_n_day($tmp_d, 14);
			} else {
				$tmp_d = &get_next_n_day($tmp_d, 1);
			}
		}
    return (@ret_dates);
  }
  if ($periodic eq $HEBDO) {
	while ($tmp_d le $d2) {
	  my $tmp_dayname = get_day_name($tmp_d);
	  if ($tmp_dayname eq $day_name) {
			push (@ret_dates, $tmp_d);
			$tmp_d = &get_next_n_day($tmp_d, 7);
	  } else {
			$tmp_d = &get_next_n_day($tmp_d, 1);
	  }
	}
    return (@ret_dates);
  }
  if ($periodic eq $DAILY) {
		while ($tmp_d le $d2) {
			push (@ret_dates, $tmp_d);
			$tmp_d = &get_next_n_day($tmp_d, 1);
		}
    return (@ret_dates);
  }

#	- une fois par mois ---  
  my $start_m 	= substr ($d1,4,2);
  $start_m		=~ s/^0//;
  my $start_y 	= substr ($d1,0,4);
  while ($tmp_d le $d2) {
		foreach (&get_date_from_name($periodic, $day_name, $start_m, $start_y)) {
			if ($_ ge $d1 && $_ le $d2) {
				push (@ret_dates, $_);
			}
		}
		$start_m++;
		if ($start_m > 12) {
			$start_m = 1; $start_y++;
		}
  	$tmp_d = sprintf "%04d%02d01", $start_y, $start_m;
  }
  return (@ret_dates);
  
}
#----
sub get_date_from_name {
  my ($periodic, $day_name, $m, $y) = @_;
  my @dates 	= ();
  check_feb($y);

  if ($periodic eq $FIRST) {
    for ($i =1; $i <= $mois[$m]; $i++) {
			my $tmp_dayname = get_day_name(sprintf "%4d%2d%2d", $y,$m,$i);
			if ($tmp_dayname eq $day_name) {
				push (@dates, sprintf "%4d%02d%02d", $y, $m, $i);
				return (@dates);
			}
    }
  }
  if ($periodic eq $LAST) {
    for ($i = $mois[$m]; $i > 0; $i--) {
			my $tmp_dayname = get_day_name(sprintf "%4d%2d%2d", $y,$m,$i);
			if ($tmp_dayname eq $day_name) {
				push (@dates, sprintf "%4d%02d%02d", $y, $m, $i);
				return (@dates);
			}
    }
  }
  if ($periodic eq $SEC) {
    $j = 0;
    for ($i =1; $i <= $mois[$m]; $i++) {
			my $tmp_dayname = get_day_name(sprintf "%4d%2d%2d", $y,$m,$i);
			if ($tmp_dayname eq $day_name) {
				$j++;
				if ($j == 2) { 
				 push (@dates, sprintf "%4d%02d%02d", $y, $m, $i);
				 return (@dates);
				}
			}
    }
    return ($dates);
  }
  if ($periodic eq $TROIS) {
    $j = 0;
    for ($i =1; $i <= $mois[$m]; $i++) {
			my $tmp_dayname = get_day_name(sprintf "%4d%2d%2d", $y,$m,$i);
			if ($tmp_dayname eq $day_name) {
				$j++;
				if ($j == 3) { 
					push (@dates, sprintf "%4d%02d%02d", $y, $m, $i);
					return (@dates);
				}
			}
    }
  }
  if ($periodic eq $QUATRE) {
    $j = 0;
    for ($i =1; $i <= $mois[$m]; $i++) {
			my $tmp_dayname = get_day_name(sprintf "%4d%2d%2d", $y,$m,$i);
			if ($tmp_dayname eq $day_name) {
				$j++;
				if ($j == 4) { 
					push (@dates, sprintf "%4d%02d%02d", $y, $m, $i);
					return (@dates);
				}
			}
    }
  }
}

#--------
sub getRes {
  my ($res_id) = @_;
  return unless $res_id;

  my (@dates, %item);
  my $sql = qq{select * from dates, res where
  	res.id=dates.res_id and
  	res.id = ?
  	order by date
  };
	my $sth = dbquery($sql, $res_id);

  while (my $data = $sth->fetchrow_hashref) {
	%item = (
		res_id	=> $data->{id},
		nom		=> $data->{nom},
		descr	=> $data->{descr},
		datedeb	=> $data->{datedeb},
		datefin	=> $data->{datefin},
		obj_id	=> $data->{obj_id},
		sciper	=> $data->{sciper},
		periodic=> $data->{periodic},
		jour	=> $data->{jour},
		hdeb	=> $data->{hdeb},
		hfin	=> $data->{hfin},
		unite	=> $data->{unite},
		pool	=> $data->{pool},
		maj		=> $data->{maj},
		maj_by	=> $data->{maj_by},
	);
	my $date =  $data->{date};
	$date =~ s/\-//g;
	push @dates, $date;
  }
  $sth->finish;

  getUserData ($item{sciper});

#  @dates = sort {$a->{date} cmp $b->{date}} @dates;
  $item{datedeb} = $dates[0] 	   unless $item{datedeb};
  $item{datefin} = $dates[$#dates] unless $item{datefin};

  $item{dates} = \@dates;
  %item;
}

#------------------
sub getUserData {
  my ($scipertodo) = @_;
  return  unless $scipertodo;
  
  my $sql = qq{select dinfo.sciper.sciper, dinfo.sciper.nom_acc, dinfo.sciper.prenom_acc, dinfo.sciper.nom_usuel, dinfo.sciper.prenom_usuel, dinfo.emails.addrlog, dinfo.accred.ordre, dinfo.accred.unite, dinfo.allunits.sigle
  	from dinfo.sciper
  left outer join dinfo.emails on dinfo.sciper.sciper=dinfo.emails.sciper
  left outer join dinfo.accred on dinfo.sciper.sciper=dinfo.accred.sciper
  left outer join dinfo.allunits on dinfo.allunits.id_unite=dinfo.accred.unite
  where  dinfo.sciper.sciper='$scipertodo' order by dinfo.accred.ordre
  };
	my $sth = $db_dinfo->query($sql);

  while (my ($sciper, $nom_acc, $prenom_acc, $nom_usuel, $prenom_usuel, $addrlog, $ordre, $id_unite, $sigle) = $sth->fetchrow) {
  	next unless $sciper;
		my $nom    = $nom_usuel    ? $nom_usuel    : $nom_acc ;
		my $prenom = $prenom_usuel ? $prenom_usuel : $prenom_acc ;

#		$allUnitsUsers{$sigle}->{$sciper} = 1;
		$allUnitsUsers{$id_unite}->{$sciper} = 1;
#		$allUsersUnits{$sciper}->{$sigle} = 1;
		$dinfo->{$sciper}	= {
			nom			=> $nom,
			prenom 	=> $prenom,
			email 	=> $addrlog,
		} unless defined $dinfo->{$sciper};
		if (defined $dinfo->{$sciper}) {
			$dinfo->{$sciper}->{accreds}->{$id_unite} = { sigle => $sigle, ordre => $ordre, };
		}
  }

}

#__________________
sub logger {
  my ($obj_id, $res_id, $msg) = @_;
  return unless $msg;
  my $sql = qq{insert into logs set sciper=?, obj_id=?, res_id=?, msg=?  };
	my $sth = dbquery($sql, $CONTENTS{sciper}, $obj_id, $res_id, $msg);
}

#___________________
sub checkJSExploits {
	my ($args) = @_;

	# - check JS CSS vulnerabilty
	my $exploittxt = $args->{lang} eq 'en' ? qq{content refused, potential malware or illegal keywords found} : 
		qq{contenu refus&eacute;, contient un mot cl&eacute; potentiellement malveillant ou refus&eacute;};
	my @exploits1 = ('FRAME','OBJECT','META','APPLET','LINK','IFRAME');
	# - check JS events vulnerabilty
	my @exploits2 = (
		'onblur',
		'onchange',
		'onclick',
		'oncopy',
		'oncut',
		'ondblclick',
		'ondrag',
		'ondrop',
		'onerror',
		'onfocus',
		'onkey',
		'onkeypress',
		'onload',
		'onmouse',
		'onpaste',
		'onreset',
		'onresize',
		'onsearch',
		'onselect',
		'onsubmit',
		'onunload',
		'oncontext',
		'oninput',
		'oninvalid',
	);

	foreach my $item (keys %$args) {
		$args->{$item} =~ s/\\a/a/ig;
		$args->{$item} =~ s/\\a/a/ig;
		$args->{$item} =~ s/\\b/b/ig;
		$args->{$item} =~ s/\\c/c/ig;
		$args->{$item} =~ s/\\d/d/ig;
		$args->{$item} =~ s/\\e/e/ig;
		$args->{$item} =~ s/\\f/f/ig;
		$args->{$item} =~ s/\\j/j/ig;
		$args->{$item} =~ s/\\k/k/ig;
		$args->{$item} =~ s/\\l/l/ig;
		$args->{$item} =~ s/\\o/o/ig;
		$args->{$item} =~ s/\\p/p/ig;
		$args->{$item} =~ s/\\r/r/ig;
		$args->{$item} =~ s/\\s/s/ig;
		$args->{$item} =~ s/\\t/t/ig;
		$args->{$item} =~ s/\\u/u/ig;
		$args->{$item} =~ s/\\v/v/ig;
		$args->{$item} =~ s/\\x/x/ig;
		$args->{$item} =~ s/\\y/y/ig;

		#	- URI decode
		$args->{$item} =~ s/\+/ /g; $args->{$item} =~ s/&#([A-Fa-f\d]+);/chr $1/eg;

		foreach my $exploit (@exploits1) {
		   erreur ($exploittxt.$exploit) if ($args->{$item} =~ m#<\s*$exploit[^>]*>#i) ;
		}

		#	- check script
		erreur ($exploittxt.' script') if ($args->{$item} =~ m#<\s*script[^>]*>#i) ;

		#	- check style
		erreur ($exploittxt.' style') if ($args->{$item} =~ m#<\s*style[^>]*>#i) ;

		#	- check javascript
		erreur ($exploittxt.' javascript') if ($args->{$item} =~ m#javascript\:#i) ;

		#	- check xss
		erreur ($exploittxt.' xss') if ($args->{$item} =~ m#<\s*xss[^>]*>#i) ;

		foreach my $exploit (@exploits2) {
		   if ($args->{$item} =~ /\b$exploit(enter|up|down|over|out|press)?\s?=/i) {
warn " ** ERR JS EXPLOIT : item=$item, exploit=$exploit\n";		   
			   	erreur ($exploittxt);
		   }
		}
	}
}

1;
