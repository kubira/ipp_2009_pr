#!/usr/bin/perl
#CST:C Stats:xkubis03:Radim Kubis

use File::Basename;  # modul pro adres��e a soubory
use Cwd 'abs_path';

$keysG = 0;
$idG = 0;
$opsG = 0;
$comsG = 0;
$patG = 0;

############################# Parsov�n� argument� ##############################

$uplnaCesta = 1; #pokud budu cht�t vypisovat �plnou cestu
$param = ""; #jak� byl zad�n argument
$input = ""; #jak� bude vstupn� soubor/adres��
$output = ""; #jak� bude v�stupn� soubor
$pattern = ""; #jak� budu hledat pod�et�zec

foreach $parametr (@ARGV) { #proch�z�m postupn� zadan� argumenty
  if($parametr eq "--help") { #pokud je parametr --help
    if(@ARGV == 1) { #pokud byl zad�n jen parametr --help
      print STDOUT "N�pov�da pro cst.pl\n\n";
      print STDOUT "Program lze spustit s parametry:\n\n";
      print STDOUT "  --help                 - vyp�e tuto n�pov�du\n\n";
      print STDOUT "  --input=fileordir.ext  - vstupn� soubor nebo adres�� pro zpracov�n�,\n";
      print STDOUT "                           pokud nen� zad�n, proch�z� se aktu�ln� adres��\n\n";
      print STDOUT "  --output=filename.ext  - v�stupn� soubor,\n";
      print STDOUT "                           pokud nen� zad�n, v�stup je na STDIN\n\n";
      print STDOUT "  -k            - vyp�e po�et kl��ov�ch slov v ka�d�m souboru a celkem\n\n";
      print STDOUT "  -o            - vyp�e po�et oper�tor� v ka�d�m souboru a celkem\n\n";
      print STDOUT "  -ik           - vyp�e po�et identifik�tor� a kl��ov�ch slov\n";
      print STDOUT "                  v ka�d�m souboru a celkem\n\n";
      print STDOUT "  -i            - vyp�e po�et identifik�tor� v ka�d�m souboru a celkem\n\n";
      print STDOUT "  -w=<pattern>  - vyp�e po�et v�skyt� �et�zce <pattern> v ka�d�m souboru\n";
      print STDOUT "                  a celkem\n\n";
      print STDOUT "  -c            - vyp�e po�et koment��� v ka�d�m souboru a celkem\n\n";
      print STDOUT "  -p            - vypisuje pouze n�zvy soubor� bez absolutn� cesty\n\n";
      print STDOUT "Parametry -k, -o, -ik, -i, -w a -c nelze mezi sebou kombinovat\n";
      print STDOUT "a pokud nebude uveden --help, tak je po�adov�no uveden� pr�v� jednoho\n";
      print STDOUT "z t�chto parametr�\n";
      exit 0; #kon��m skript s k�dem 0
    } else { #pokud bylo zad�no v�ce parametr�
      print STDERR "�patn� zadan� parametry!\n"; #vyp�u chybu
      exit 1; #ukon��m skript s k�dem 1
    }
  } elsif($parametr eq "-k") { #pokud byl parametr -k
    if($param eq "") { #pokud je�t� nebyl zad�n ��dn� parametr
      $param = "k"; #ulo��m si jej
    } else { #pokud u� parametr zad�n byl
      print STDERR "�patn� kombinace parametr�!!!\n"; #tisknu chybu
      exit 1; #kon��m s n�vratov�m k�dem 1
    }
  } elsif($parametr eq "-o") { #pokud byl zad�n parametr -o
    if($param eq "") {
      $param = "o";
    } else {
      print STDERR "�patn� kombinace parametr�!!!\n";
      exit 1;
    }
  } elsif($parametr eq "-ik") {
    if($param eq "") {
      $param = "ik";
    } else {
      print STDERR "�patn� kombinace parametr�!!!\n";
      exit 1;
    }
  } elsif($parametr eq "-i") {
    if($param eq "") {
      $param = "i";
    } else {
      print STDERR "�patn� kombinace parametr�!!!\n";
      exit 1;
    }
  } elsif($parametr eq "-c") {
    if($param eq "") {
      $param = "c";
    } else {
      print STDERR "�patn� kombinace parametr�!!!\n";
      exit 1;
    }
  } elsif($parametr eq "-p") {
    if($uplnaCesta == 1) {
      $uplnaCesta = 0;
    } else {
      print STDERR "�patn� kombinace parametr�!!!\n";
      exit 1;
    }
  } elsif($parametr =~ /^-w=.+/) {
    if($param eq "") {
      @policko = split("=", $parametr, 2);
      $pattern = $policko[1];
      print "Pattern: $pattern\n";
      $param = "w";
    } else {
      print STDERR "�patn� kombinace parametr�!!!\n";
      exit 1;
    }
  } elsif($parametr =~ /^--input=.*/) {
    if($input eq "") {
      @policko = split("=", $parametr, 2);
      $input = $policko[1];
      $adresar = $input;
      if($input eq "") {
        print STDERR "Nebyl zad�n vstupn� soubor/adres��!!!\n";
        exit 1;
      }
    } else {
      print STDERR "�patn� kombinace parametr�!!!\n";
      exit 1;
    }
  } elsif($parametr =~ /^--output=.*/) {
    if($output eq "") {
      @policko = split("=", $parametr, 2);
      $output = $policko[1];
      if($output eq "") {
        print STDERR "Nebyl zad�n v�stupn� soubor!!!\n";
        exit 1;
      }
    } else {
      print STDERR "�patn� kombinace parametr�!!!\n";
      exit 1;
    }
  } else {
    print STDERR "Nedefinovan� parametr!\n";
    exit 1;
  }
}

if($param eq "") {

  print STDERR "Nebyl zad�n ��dn� p�ep�na�!!!\n";
  exit 2;

}

######################### Konec parsov�n� argument� ############################

####################### Proch�zen� soubor� a adres��� ##########################

@adresare = qw(); #pole pro adres��e, kter� je�t� nebyly prohled�ny
my %soubory;  #pole pro soubory s p��ponami .c a .h

if($input eq "") {
  $adresar = "."; #startovn� adres�� pro vyhled�v�n�
} else {
  $adresar = $input; #startovn� adres�� pro vyhled�v�n�
}

if(-d $adresar) { #pokud je zad�n adres��, tak jej prohled�v�m
  
  @adresare = (@adresare, $adresar); #p�id�m n�zev adres��e do pole adres���

  while(scalar(@adresare) > 0) { #dokud je n�jak� adres�� v poli, prohled�v�m

    $adresar = pop @adresare; #odeberu prvn� adres�� v poli a ulo��m si jej

    opendir($obsah, $adresar) or print STDERR "Nepoda�ilo se otev��t adres�� $adresar: $!\n";
    #otev�u si adres�� pro proch�zen�

    while($polozka = readdir $obsah) { #postupn� proch�z�m polo�ky adres��e
      if($polozka eq "." or $polozka eq "..") { #pokud je polo�ka . nebo ..

        next; #jdu na dal�� polo�ku

      }

      if(-f $adresar."/".$polozka) { #pokud je polo�ka soubor

        my(undef, undef, $pripona) = fileparse($polozka,qr{\..*}); #rozparsuji jeho cestu

        if($pripona eq ".c" || $pripona eq ".h") { #pokud je p��pona souboru .c nebo .h
          if($uplnaCesta == 1) {
            $soubory{abs_path($adresar."/".$polozka)} = 0; #p�id�m soubor do pole soubor�
          } else {
            $soubory{$polozka."/".abs_path($adresar)} = 0;
          }
        }

      } elsif(-d $adresar."/".$polozka) { #pokud je polo�ka adres��

        @adresare = (@adresare, $adresar."/".$polozka); #p�id�m ho do pole adres���

      }
    }

    closedir($obsah); #uzav�u aktu�ln� proch�zen� adres��

  }
} elsif(-f $adresar) { #pokud je zad�n soubor
    $fileta = abs_path($adresar);
    
    my $c = "";
    my $dc = "";
    
    $d = (length($fileta)-1);

    @p = split("", $fileta);
    
    for($x = $d; $x >= 0; $x--) {
      if($p[$x] eq "/" or $p[$x] eq "\\") {
        for($y = ($x+1); $y <= $d; $y++) {
          $c = $c.$p[$y];
        }
        for($z = ($x-1); $z >= 0; $z--) {
          $dc = $p[$z].$dc;
        }
      }
    }
    
    $soubory{($c."/".$dc)} = 0; #p�id�m ho do pole soubor�

} else { #pokud nen� zad�n spr�vn� soubor nebo adres��

  print STDERR "Byl zad�n neexistuj�c� adres��/soubor!!!\n"; #nastala chyba
  exit 1;

}

##################### Konec proch�zen� soubor� a adres��� ######################

######################### Funkce pro hled�n� patternu ##########################

sub retez {

  my($soubor, $slovo) = @_;

  $znak = '';

  $pozice = 0;

  $help = "";

  $delka = length($slovo);

  $pocet = 0;

  @ok = ($slovo =~ /(.{1})/);

  open($ovladac, $soubor);

  while(sysread($ovladac, $znak, 1) != 0) {

    if($znak eq @ok[0]) {
      $pozice = sysseek($ovladac, 0, 1);
      sysseek($ovladac, -1, 1);
      sysread($ovladac, $help, $delka);

      if($help eq $slovo) {
        $pocet++;
      } else {
        sysseek($ovladac, $pozice, 0);
      }

    }

  }

  $patG += $pocet;

  return $pocet;

  close($ovladac);
}

###################### Konec funkce pro hled�n� patternu #######################

###################### Funkce pro hled�n� id, keys a ops #######################

sub others {

  my($file) = @_;

  $start = 0;
  $ID = 1;
  $OP = 2;
  $STR = 3;
  $SLASH = 4;
  $COM1 = 5;
  $COM2 = 6;
  $PRE = 7;
  $STR2 = 8;
  $nula = 9;
  $hex = 10;
  $dec = 11;
  $dot = 12;
  $postdot = 13;
  $exp = 14;
  $eop = 15;
  $num = 16;
  $oct = 17;
  $intsuffix = 18;
  $hexpref = 19;
  $fsuffix = 20;
  $tecka = 21;
  $hexdot = 22;
  $hexexp = 23;
  $hexpostdot = 24;
  $hexsign = 25;
  $hexnumexp = 26;

  $status = $start;
  $ret = "";
  
  $keys = 0;
  $id = 0;
  $ops = 0;
  $coms = 0;
  
  @keywords = ("_Bool", "_Complex", "_Imaginary", "auto",
               "break","case","char","const","continue",
               "default","do","double","else","enum",
               "extern","float","for","goto","if","inline",
               "int","long","register","restrict","return",
               "short","signed","sizeof","static","struct",
               "switch","typedef","union","unsigned","void",
               "volatile","while");
  
  @operators = ("+", "-", "!", "~", "&", "*", "/", "%", "<",
                ">", "^", "|", "=", "->", "++", "--", "<<", ">>",
                "<=", ">=", "==", "!=", "&&", "||", "+=", "-=",
                "*=", "/=", "%=", "&=", "|=", "^=", "<<=", ">>=");
  
  sysopen($soubor, $file, O_RDONLY);
  
  while ((sysread($soubor, $znak, 1)) != 0) {
    if($status == $start) {
      if($znak eq "L") {
        sysread($soubor, $znak, 1);
        if($znak eq "\'") {
          $status = $STR2;
        } elsif($znak eq "\"") {
          $status = $STR;
        } else {
          $ret = "L".$znak;
          $status = $ID;
        }
      } elsif($znak =~ /^[1-9]$/) {
        $status = $dec;
      } elsif($znak eq "0") {
        $status = $nula;
      } elsif($znak eq "#") {
        $status = $PRE;
      } elsif($znak =~ /^[\\\)\(]$/) {
        next;
      } elsif ($znak =~ /^[\"]$/) {
        $status = $STR;
      } elsif ($znak =~ /^[\']$/) {
        $status = $STR2;
      } elsif ($znak eq "/") {
        $status = $SLASH;
      } elsif($znak eq ".") {
        $status = $tecka;
      } elsif($znak =~ /^[[:alpha:]_]$/) {
        $ret = $znak;
        $status = $ID;
      } elsif((@pole = grep /\Q$znak\E/, @operators) > 0) {
        if($znak eq "*") {
          if(sysread($soubor, $znak, 1) == 1) {
            if($znak ne "*") {
              sysseek($soubor, -1, 1);
              $status = $OP;
            } else {
              $ops += 2;
            }
          }
        } else {
          $status = $OP;
        }
      } else {
        if($ret ne "") {
        }
        $ret = "";
        $status =$start;
      }
    } elsif($status == $tecka) {
      if($znak =~ /^[0-9]$/) {
        $status = $postdot;
      } else {
        sysseek($soubor, -1, 1);
        $ops++;
        $status = $start;
      }
    } elsif($status == $nula) {
      if($znak eq "x" or $znak eq "X") {
        $status = $hexpref;
      } elsif($znak =~ /^[0-7]$/) {
        $status = $oct;
      } elsif($znak eq ".") {
        $status = $dot;
      } elsif($znak =~ /^[uUlL]$/) {
        sysseek($soubor, -1, 1);
        $status = $intsuffix;
      } else {
        sysseek($soubor, -1, 1);
        $status = $start;
      }
    } elsif($status == $hexnumexp) {
      if($znak =~ /^[0-9]$/) {
        $status = $hexnumexp;
      } elsif($znak =~ /^[lLfF]$/) {
        $status = $start;
      } else {
        sysseek($soubor, -1, 1);
        $status = $start;
      }
    } elsif($status == $hexpostdot) {
      if($znak =~ /^[0-9A-Fa-f]$/) {
        $status = $hexpostdot;
      } elsif($znak eq "p" or $znak eq "P") {
        $status = $hexexp;
      }
    } elsif($status == $hexexp) {
      if($znak eq "+" or $znak eq "-") {
        $status = $hexsign;
      } elsif($znak =~ /^[0-9]$/) {
        $status = $hexnumexp;
      }
    } elsif($status == $hexsign) {
      if($znak =~ /^[0-9]$/) {
        $status = $hexnumexp;
      }
    } elsif($status == $hexpref) {
      if($znak =~ /^[0-9a-fA-F]$/) {
        $status = $hex;
      } elsif($znak eq ".") {
        $status = $hexdot;
      }
    } elsif($status == $oct)  {
      if($znak =~ /^[0-7]$/) {
        $status = $oct;
      } elsif($znak =~ /^[uUlL]$/) {
        sysseek($soubor, -1, 1);
        $status = $intsuffix;
      } else {
        sysseek($soubor, -1, 1);
        $status = $start;
      }
    } elsif($status == $intsuffix) {
      if($znak eq "u" or $znak eq "U") {
        sysread($soubor, $znak, 1);
        if($znak eq "l") {
          sysread($soubor, $znak, 1);
          if($znak eq "l") {
            $status = $start;
          } else {
            sysseek($soubor, -1, 1);
            $status = $start;
          }
        } elsif($znak eq "L") {
          sysread($soubor, $znak, 1);
          if($znak eq "L") {
            $status = $start;
          } else {
            sysseek($soubor, -1, 1);
            $status = $start;
          }
        } else {
          sysseek($soubor, -1, 1);
          $status = $start;
        }
      } elsif($znak eq "l") {
        sysread($soubor, $znak, 1);
        if($znak eq "l") {
          sysread($soubor, $znak, 1);
          if($znak eq "U" or $znak eq "u") {
            $status = $start;
          } else {
            sysseek($soubor, -1, 1);
            $status = $start;
          }
        } elsif($znak eq "U" or $znak eq "u") {
          $status = $start;
        } else {
          sysseek($soubor, -1, 1);
          $status = $start;
        }
      } elsif($znak eq "L") {
        sysread($soubor, $znak, 1);
        if($znak eq "L") {
          sysread($soubor, $znak, 1);
          if($znak eq "U" or $znak eq "u") {
            $status = $start;
          } else {
            sysseek($soubor, -1, 1);
            $status = $start;
          }
        } elsif($znak eq "U" or $znak eq "u") {
          $status = $start;
        } else {
          sysseek($soubor, -1, 1);
          $status = $start;
        }
      }
    } elsif($status == $dec) {
      if($znak eq ".") {
        $status = $dot;
      } elsif($znak eq "E" or $znak eq "e") {
        $status = $exp;
      } elsif($znak =~ /^[0-9]$/) {
        $status = $dec;
      } elsif($znak =~ /^[uUlL]$/) {
        sysseek($soubor, -1, 1);
        $status = $intsuffix;
      } else {
        sysseek($soubor, -1, 1);
        $status = $start;
      }
    } elsif($status == $dot) {
      if($znak =~ /^[0-9]$/) {
        $status = $postdot;
      } elsif($znak eq "e" or $znak eq "E") {
        $status = $exp;
      } elsif($znak =~ /^[lLfF]$/) {
        $status = $start;
      } else {
        sysseek($soubor, -1, 1);
        $status = $start;
      }
    } elsif($status == $postdot) {
      if($znak eq "E" or $znak eq "e") {
        $status = $exp;
      } elsif($znak =~ /^[0-9]$/) {
        $status = $postdot;
      } elsif($znak =~ /^[fFlL]$/) {
        $status = $start;
      } else {
        sysseek($soubor, -1, 1);
        $status = $start;
      }
    } elsif($status == $exp) {
      if($znak eq "+" or $znak eq "-") {
        $status = $eop;
      } elsif($znak =~ /^[0-9]$/) {
        $status = $num;
      } else {
        sysseek($soubor, -1, 1);
        $status = $start;
      }
    } elsif($status == $eop) {
      if($znak =~ /^[0-9]$/) {
        $status = $num;
      } else {
        sysseek($soubor, -1, 1);
        $status = $start;
      }
    } elsif($status == $num) {
      if($znak =~ /^[0-9]$/) {
        $status = $num;
      } elsif($znak =~ /^[fFlL]$/) {
        $status = $start;
      } else {
        sysseek($soubor, -1, 1);
        $status = $start;
      }
    } elsif($status == $hexdot) {
      if($znak =~ /^[0-9A-Fa-f]$/) {
        $status = $hexpostdot;
      } elsif($znak eq "p" or $znak eq "P") {
        $status = $hexexp;
      }
    } elsif($status == $hex) {
      if($znak =~ /^[0-9A-Fa-f]$/) {
        $status = $hex;
      } elsif($znak eq "p" or $znak eq "P") {
        $status = $hexexp;
      } elsif($znak =~ /^[uUlL]$/) {
        sysseek($soubor, -1, 1);
        $status = $intsuffix;
      } elsif($znak eq ".") {
        $status = $hexdot;
      } else {
        sysseek($soubor, -1, 1);
        $status = $start;
      }
    } elsif($status == $PRE) { 
      if($znak eq "\\") {
        sysread($soubor, $znak, 1);
        if($znak eq "\r") {
          sysread($soubor, $znak, 1);
        }
      } elsif($znak eq "\n") {
        $status = $start;
      }
    } elsif($status == $ID) {
      if($znak =~ /^[[:alnum:]_]$/) {
        $ret = $ret.$znak;
      } else {
        sysseek $soubor, -1, 1;
        if($ret ne "") {
            @pole = grep /^\Q$ret\E$/, @keywords;
            if(@pole == 1) {
              $keys++;
            } else {
              $id++;
            }
            $status = $start;
            $ret = "";
        }
      }
    } elsif($status == $OP) {
      if($znak eq ".") {
        print "tecka!\n";
      }
      if((@pole = grep /\Q$znak\E/, @operators) > 0) {
      } else {
        $ops++;
        sysseek $soubor, -1, 1;
        $status = $start;
      }
    } elsif($status == $STR2) {
      if($znak eq "\\") {
        sysread($soubor, $znak, 1);
      } elsif($znak eq "\'") {
        $status = $start;
      }
    } elsif($status == $STR) {
      if($znak eq "\\") {
        sysread($soubor, $znak, 1);
      } elsif($znak eq "\"") {
        $status = $start;
      }
    } elsif($status == $SLASH) {
      if($znak eq "/") {
        $status = $COM1;
      } elsif($znak eq "*") {
        $status = $COM2;
      } else {
        $status = $OP;
        sysseek($soubor, -1, 1);
      }
    } elsif($status == $COM1) {
      $coms += 2;
      sysseek($soubor, -1, 1);
      while(sysread($soubor, $znak, 1) == 1) {
        if($znak eq "\r") {
          sysread($soubor, $znak, 1);
          if($znak eq "\n") {
            $coms++;
            last;
          } else {
            $coms++;
            sysseek($soubor, -1, 1);
          }
        } elsif($znak eq "\n") {
          $coms++;
          last;
        } else {
          $coms++;
        }
      }
      $status = $start;
    } elsif($status == $COM2) {
      $coms += 2;
      sysseek($soubor, -1, 1);
      while(sysread($soubor, $znak, 1) == 1) {
        if($znak eq "*") {
          sysread($soubor, $znak, 1);
          if($znak eq "/") {
            $coms += 2;
            last;
          } else {
            $coms++;
            sysseek($soubor, -1, 1);
          }
        } elsif($znak eq "\r") {
          sysread($soubor, $znak, 1);
          if($znak eq "\n") {
            $coms++;
          } else {
            $coms++;
            sysseek($soubor, -1, 1);
          }
        } else {
          $coms++;
        }
      }
      $status = $start;
    }
  }

  close($soubor);

  $keysG += $keys;
  $idG += $id;
  $opsG += $ops;
  $comsG += $coms;

  if($param eq "i") {
    return $id;
  } elsif($param eq "o") {
    return $ops;
  } elsif($param eq "c") {
    return $coms;
  } elsif($param eq "ik") {
    return ($id+$keys);
  } elsif($param eq "k") {
    return $keys;
  }

}

################### Konec funkce pro hled�n� id, keys a ops ####################

########################### V�pis v�sledk� skriptu #############################

if($output ne "") {
  open(OUTPUT, ">$output");
} else {
  open(OUTPUT, ">-");
}

@sou = sort keys %soubory; #se�ad�m soubory podle cesty a n�zvu

my $delka = 0;

foreach $klic (@sou) { #proch�z�m pole soubor�
  if($uplnaCesta == 1) {
    if($delka < length($klic)) {
      $delka = length($klic);
    }
    if($param eq "w") {
      $soubory{$klic} = retez($klic, $pattern);
    } else {
      $soubory{$klic} = others($klic);
    }
  } else {
    my($s, $c) = split("/", $klic, 2);
    if($delka < length($s)) {
      $delka = length($s);
    }
    
    if($param eq "w") {
      $soubory{$klic} = retez($c."/".$s, $pattern);
    } else {
      $soubory{$klic} = others($c."/".$s);
    }
  }
}

$delka++;

@pole = values %soubory;
my $d = 0;

foreach $f (@pole) {
  if($d < length($f)) {
    $d = length($f);
  }
}

foreach $klic (@sou) {
  if($uplnaCesta == 1) {
    print OUTPUT $klic." "x($delka-length($klic)+$d-length($soubory{$klic}))."".$soubory{$klic}."\n";
  } else {
    my($s, $c) = split("/", $klic, 2);
    print OUTPUT $s." "x($delka-length($s)+$d-length($soubory{$klic}))."".$soubory{$klic}."\n";
  }
}

if($param eq "o") {
  print OUTPUT "CELKEM:"." "x($delka-7+$d-(length($opsG)))."$opsG\n";
} elsif($param eq "i") {
  print OUTPUT "CELKEM:"." "x($delka-7+$d-(length($idG)))."$idG\n";
} elsif($param eq "k") {
  print OUTPUT "CELKEM:"." "x($delka-7+$d-length($keysG))."$keysG\n";
} elsif($param eq "c") {
  print OUTPUT "CELKEM:"." "x($delka-7+$d-length($comsG))."$comsG\n";
} elsif($param eq "ik") {
  print OUTPUT "CELKEM:"." "x($delka-7+$d-length(($keysG+$idG)))."".($keysG+$idG)."\n";
} elsif($param eq "w") {
  print OUTPUT "CELKEM:"." "x($delka-7+$d-length($patG))."$patG\n";
}

close OUTPUT;
######################## Konec v�pisu v�sledk� skriptu #########################
