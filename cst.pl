#!/usr/bin/perl
#CST:C Stats:xkubis03:Radim Kubis

use File::Basename;  # modul pro adresáøe a soubory
use Cwd 'abs_path';

$keysG = 0;
$idG = 0;
$opsG = 0;
$comsG = 0;
$patG = 0;

############################# Parsování argumentù ##############################

$uplnaCesta = 1; #pokud budu chtít vypisovat úplnou cestu
$param = ""; #jaký byl zadán argument
$input = ""; #jaký bude vstupní soubor/adresáø
$output = ""; #jaký bude výstupní soubor
$pattern = ""; #jaký budu hledat podøetìzec

foreach $parametr (@ARGV) { #procházím postupnì zadané argumenty
  if($parametr eq "--help") { #pokud je parametr --help
    if(@ARGV == 1) { #pokud byl zadán jen parametr --help
      print STDOUT "Nápovìda pro cst.pl\n\n";
      print STDOUT "Program lze spustit s parametry:\n\n";
      print STDOUT "  --help                 - vypí¹e tuto nápovìdu\n\n";
      print STDOUT "  --input=fileordir.ext  - vstupní soubor nebo adresáø pro zpracování,\n";
      print STDOUT "                           pokud není zadán, prochází se aktuální adresáø\n\n";
      print STDOUT "  --output=filename.ext  - výstupní soubor,\n";
      print STDOUT "                           pokud není zadán, výstup je na STDIN\n\n";
      print STDOUT "  -k            - vypí¹e poèet klíèových slov v ka¾dém souboru a celkem\n\n";
      print STDOUT "  -o            - vypí¹e poèet operátorù v ka¾dém souboru a celkem\n\n";
      print STDOUT "  -ik           - vypí¹e poèet identifikátorù a klíèových slov\n";
      print STDOUT "                  v ka¾dém souboru a celkem\n\n";
      print STDOUT "  -i            - vypí¹e poèet identifikátorù v ka¾dém souboru a celkem\n\n";
      print STDOUT "  -w=<pattern>  - vypí¹e poèet výskytù øetìzce <pattern> v ka¾dém souboru\n";
      print STDOUT "                  a celkem\n\n";
      print STDOUT "  -c            - vypí¹e poèet komentáøù v ka¾dém souboru a celkem\n\n";
      print STDOUT "  -p            - vypisuje pouze názvy souborù bez absolutní cesty\n\n";
      print STDOUT "Parametry -k, -o, -ik, -i, -w a -c nelze mezi sebou kombinovat\n";
      print STDOUT "a pokud nebude uveden --help, tak je po¾adováno uvedení právì jednoho\n";
      print STDOUT "z tìchto parametrù\n";
      exit 0; #konèím skript s kódem 0
    } else { #pokud bylo zadáno více parametrù
      print STDERR "©patnì zadané parametry!\n"; #vypí¹u chybu
      exit 1; #ukonèím skript s kódem 1
    }
  } elsif($parametr eq "-k") { #pokud byl parametr -k
    if($param eq "") { #pokud je¹tì nebyl zadán ¾ádný parametr
      $param = "k"; #ulo¾ím si jej
    } else { #pokud u¾ parametr zadán byl
      print STDERR "©patná kombinace parametrù!!!\n"; #tisknu chybu
      exit 1; #konèím s návratovým kódem 1
    }
  } elsif($parametr eq "-o") { #pokud byl zadán parametr -o
    if($param eq "") {
      $param = "o";
    } else {
      print STDERR "©patná kombinace parametrù!!!\n";
      exit 1;
    }
  } elsif($parametr eq "-ik") {
    if($param eq "") {
      $param = "ik";
    } else {
      print STDERR "©patná kombinace parametrù!!!\n";
      exit 1;
    }
  } elsif($parametr eq "-i") {
    if($param eq "") {
      $param = "i";
    } else {
      print STDERR "©patná kombinace parametrù!!!\n";
      exit 1;
    }
  } elsif($parametr eq "-c") {
    if($param eq "") {
      $param = "c";
    } else {
      print STDERR "©patná kombinace parametrù!!!\n";
      exit 1;
    }
  } elsif($parametr eq "-p") {
    if($uplnaCesta == 1) {
      $uplnaCesta = 0;
    } else {
      print STDERR "©patná kombinace parametrù!!!\n";
      exit 1;
    }
  } elsif($parametr =~ /^-w=.+/) {
    if($param eq "") {
      @policko = split("=", $parametr, 2);
      $pattern = $policko[1];
      print "Pattern: $pattern\n";
      $param = "w";
    } else {
      print STDERR "©patná kombinace parametrù!!!\n";
      exit 1;
    }
  } elsif($parametr =~ /^--input=.*/) {
    if($input eq "") {
      @policko = split("=", $parametr, 2);
      $input = $policko[1];
      $adresar = $input;
      if($input eq "") {
        print STDERR "Nebyl zadán vstupní soubor/adresáø!!!\n";
        exit 1;
      }
    } else {
      print STDERR "©patná kombinace parametrù!!!\n";
      exit 1;
    }
  } elsif($parametr =~ /^--output=.*/) {
    if($output eq "") {
      @policko = split("=", $parametr, 2);
      $output = $policko[1];
      if($output eq "") {
        print STDERR "Nebyl zadán výstupní soubor!!!\n";
        exit 1;
      }
    } else {
      print STDERR "©patná kombinace parametrù!!!\n";
      exit 1;
    }
  } else {
    print STDERR "Nedefinovaný parametr!\n";
    exit 1;
  }
}

if($param eq "") {

  print STDERR "Nebyl zadán ¾ádný pøepínaè!!!\n";
  exit 2;

}

######################### Konec parsování argumentù ############################

####################### Procházení souborù a adresáøù ##########################

@adresare = qw(); #pole pro adresáøe, které je¹tì nebyly prohledány
my %soubory;  #pole pro soubory s pøíponami .c a .h

if($input eq "") {
  $adresar = "."; #startovní adresáø pro vyhledávání
} else {
  $adresar = $input; #startovní adresáø pro vyhledávání
}

if(-d $adresar) { #pokud je zadán adresáø, tak jej prohledávám
  
  @adresare = (@adresare, $adresar); #pøidám název adresáøe do pole adresáøù

  while(scalar(@adresare) > 0) { #dokud je nìjaký adresáø v poli, prohledávám

    $adresar = pop @adresare; #odeberu první adresáø v poli a ulo¾ím si jej

    opendir($obsah, $adresar) or print STDERR "Nepodaøilo se otevøít adresáø $adresar: $!\n";
    #otevøu si adresáø pro procházení

    while($polozka = readdir $obsah) { #postupnì procházím polo¾ky adresáøe
      if($polozka eq "." or $polozka eq "..") { #pokud je polo¾ka . nebo ..

        next; #jdu na dal¹í polo¾ku

      }

      if(-f $adresar."/".$polozka) { #pokud je polo¾ka soubor

        my(undef, undef, $pripona) = fileparse($polozka,qr{\..*}); #rozparsuji jeho cestu

        if($pripona eq ".c" || $pripona eq ".h") { #pokud je pøípona souboru .c nebo .h
          if($uplnaCesta == 1) {
            $soubory{abs_path($adresar."/".$polozka)} = 0; #pøidám soubor do pole souborù
          } else {
            $soubory{$polozka."/".abs_path($adresar)} = 0;
          }
        }

      } elsif(-d $adresar."/".$polozka) { #pokud je polo¾ka adresáø

        @adresare = (@adresare, $adresar."/".$polozka); #pøidám ho do pole adresáøù

      }
    }

    closedir($obsah); #uzavøu aktuálnì procházený adresáø

  }
} elsif(-f $adresar) { #pokud je zadán soubor
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
    
    $soubory{($c."/".$dc)} = 0; #pøidám ho do pole souborù

} else { #pokud není zadán správnì soubor nebo adresáø

  print STDERR "Byl zadán neexistující adresáø/soubor!!!\n"; #nastala chyba
  exit 1;

}

##################### Konec procházení souborù a adresáøù ######################

######################### Funkce pro hledání patternu ##########################

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

###################### Konec funkce pro hledání patternu #######################

###################### Funkce pro hledání id, keys a ops #######################

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

################### Konec funkce pro hledání id, keys a ops ####################

########################### Výpis výsledkù skriptu #############################

if($output ne "") {
  open(OUTPUT, ">$output");
} else {
  open(OUTPUT, ">-");
}

@sou = sort keys %soubory; #seøadím soubory podle cesty a názvu

my $delka = 0;

foreach $klic (@sou) { #procházím pole souborù
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
######################## Konec výpisu výsledkù skriptu #########################
