#! usr/bin/perl
# A OR code and info generator for computers
# By Dzu Pham
# Created: 2015-06-09
# Note: The file name is created by the Temp, so it will contain a funky name for the .tex file

use DBI;  # Postgres communication functions
use File::Temp qw/tempfile/;
use File::Copy;
use Cwd;
use Cwd 'abs_path';
use warnings;
no warnings "uninitialized";  # Don't warn about unitialized variables#
use strict 'vars';  # Force all variables to have defined scope

our $hostName;
our $modelNum;
our $tag;
our $start;
our $num=0;
our @mac; #The array to store the MAC address
our @name; #Name the MAC address
our $qrAddress;

my $repdir = substr(abs_path($0), 0, -12);
my ($fh, $filename) = tempfile( SUFFIX => '.tex', DIR => $repdir);
my $report_name = "QR_Lables.pdf";
my $report_file = "QR_Lables.tex";
my $run;
my $count = 0;

my $data = $repdir."data.txt";
open(my $df, "<", $data) or die "Could not open file '$data' $!";

print "\nThe Generator Thingy\n";

sub info{
	#print "What is the Host Name?  ";
	$hostName = <$df>;

	#print "What is the Model Type?  ";
	$modelNum = <$df>;

	#print "What is the Service Tag?  ";
	$tag = <$df>;

	my $a = 1;
	my $line;
	my $check = <$df>;
	$num = 0;
	while($a <= $check){
		$line = <$df>;
		chomp $line;
			$num++;
			$mac[$a] = $line;
			$a++;
	}
	$check = <$df>; # This reads in the 2nd newlines so the file is reday for the next run

	#remove those pesky \n
	chomp $hostName;
	chomp $modelNum;
	chomp $tag;

	$qrAddress = "https://itweb.mst.edu/auth-cgi-bin/cgiwrap/netdb/view-host.pl?host=".$hostName.".managed.mst.edu";
}

sub body{
#This uses the "" so I can access the variables from Perl
print $fh <<"END";
	\\fbox{\\begin{minipage}[c]{\\textwidth}
		\\fbox{\\begin{minipage}{0.7in}
			\\begin{pspicture}(0.7in, 0.85in)
				\\psbarcode{$qrAddress}{height=0.7 width=0.7}{qrcode}
			\\end{pspicture}
		\\end{minipage}}\\hspace{0.1cm}\\vspace{0.5cm}
		\\fbox{\\begin{minipage}[c]{0.7\\textwidth}
			\\ttfamily\\small\\begin{tabular}{l l}\\\\
				\\textbf{$hostName} ($modelNum)\\\\
				$tag \\\\
END

#Prints out the MAC address
if($num != 0){ 
	for(my $i=1; $i <= $num; $i++){
print $fh <<"END";
				$mac[$i] \\\\
END
	} 
}
# 
print $fh <<"END";
			\\end{tabular}
		\\end{minipage}}
	\\end{minipage}}
	\\hdashrule[0.5ex]{8cm}{1pt}{5pt 10pt}\\\\
END
}
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

#Latex information
#Header and Begin informtion
print $fh <<'END';
\documentclass[final,a4paper,notitlepage,10pt]{report}
\usepackage[utf8]{inputenc}% inputenc for encoding to utf8
\usepackage{auto-pst-pdf}% auto-pst-pdf converts pst to pdf
\usepackage{pst-barcode}% pst-barcode try implement QR code
\usepackage{dashrule}% dash lines
\usepackage[paper=a4paper,left=0.7cm,right=0.7cm,top=0.7cm,bottom=0.7cm,noheadfoot] {geometry}% geometry for margins

\setlength\parindent{0pt}
\fboxsep0pt
\fboxrule0pt

\begin{document}
	\thispagestyle{empty}% this page does not have a header
	\hdashrule[0.5ex]{8cm}{1pt}{5pt 10pt}\\
END

do{ # This is the loop of the program
	$count++;
	info();
	body();
	#print "\n\n";
}while($run = <$df>);

print $fh <<'END';
\end{document}
END

close $fh;
close $df;

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#Run LaTeX compiler to generate PDF

system('xelatex -output-directory ' . $repdir . ' ' . $filename);

my $file_prefix = substr($filename, 0, -4);
# remove aux, log and tex files
my $auxfile = $file_prefix . ".aux";
my $logfile = $file_prefix . ".log";
my $pdffile = $file_prefix . ".pdf";
my $texfile = "$repdir$report_file";

move($filename,$texfile); # Renames the .tex file to QR_Lables.tex

system('del ' . $auxfile . ' ' .  $logfile);
#system('del ' . $filename); #comment this out if you want to keep the .tex file
$filename="$repdir$report_name";
move($pdffile,$filename); # Renames the PDF file to QR_Lables.pdf

exec($filename); #opens the PDF
#Note: If you recompile the .tex with M then you will generate .aux and .log files (which you don't really need)