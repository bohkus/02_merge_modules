#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Std;

use XML::Parser::PerlSAX;
use Win32::TieRegistry( TiedHash => '%RegHash' );

use Win32::OLE;
use Win32::OLE qw(in with);
use Win32::OLE::Variant;
use Win32::OLE::Const 'Microsoft Outlook';



$::option_CPATH_LETTER			= get_cme_drive();
$::option_inputFile				= "merge_plan.xml";
$::options_active				= 0;
$::options_verbose				= 0;
$::options_selfmail				= 0;

#@::merge_plans;

#%::plan_0001_;
$::plan_0001_{"view_name"}	    ="";
$::plan_0001_{"TOP_CRH_name"}	="";
$::plan_0001_{"TOP_CRH_branch"}	="";
$::plan_0001_{"TOP_CRH_path"}	="";
$::plan_0001_{"SUB_CRH_name"}	="";
$::plan_0001_{"SUB_CRH_branch"}	="";
$::plan_0001_{"SUB_CRH_path"}	="";
#$::plan_0001_{"CNHxxxxxxx"}; these key will hold the new labels



# -------------------------------------------------------------------------------------------------------------------
sub get_cme_drive{
	my (%reghash,$Registry,$key,$value);
	
	$Registry = \%RegHash;
	
	%reghash =(%{$Registry->{"HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\Mvfs\\Parameters\\"}});
	
	while (($key,$value) = each %reghash){
		#print ("\n$key $value");
		last if ($key eq "\\drive");
	};
	
	return $value;
}

# -------------------------------------------------------------------------------------------------------------------

sub read_input_file{
	my %SAX_HASH;
	$SAX_HASH{handler} = MyHandler->new();
	$SAX_HASH{parser} = XML::Parser::PerlSAX->new( Handler => $SAX_HASH{handler} );

	my $instance = $::option_inputFile;

	my %parser_args = (Source => { SystemId => $instance });

	$SAX_HASH{parser}->parse(%parser_args)
}

# -------------------------------------------------------------------------------------------------------------------

sub delteteView
{
    my ($view) = @_;
    my $cmd;
    my $output;
    my $prefix_view = $ENV{username}."_".$view;
	printf("\n [deleteView] ".$prefix_view."");
	$cmd = "cme rmview $view";
	$output = qx($cmd);
    $output =~ /Success/  || die("failed: $cmd $!\n");
}

# -------------------------------------------------------------------------------------------------------------------
 
sub createView
{

    my ($view) = @_;
    my $cmd;
    my $output;
    my $prefix_view = $ENV{username}."_".$view;
    printf("\n [createView] ".$prefix_view."");
    $cmd = "cme mkview $view";
    $output = qx($cmd);
    $output =~ /Success/  || die("failed: $cmd $!\n");

}

# -------------------------------------------------------------------------------------------------------------------
sub mail{
	my ($mailto,$mail_body) = @_;
	my $item;
	my $Outlook = Win32::OLE->GetActiveObject
                           ('Outlook.Application') ||
                Win32::OLE->new('Outlook.Application');

	# Create Mail Item
	$item = $Outlook->CreateItem(0);  # 0 = mail item.
	unless ($item){
  		print ("\n [Send Mail] - Outlook is not running, cannot send mail.");
	}

	$item->{'Subject'} = "[SCRIPT NOTIFICATION] merge_modules.pl";
	$item->{'To'} = $mailto.";";
	$item->{'Body'} = $mail_body."\r\n";

	print("\n [Send Mail] - to $mailto");
	# Send the Email
	$item->Send();
}

# -------------------------------------------------------------------------------------------------------------------

 sub addModuleToView
{
  my ($module,$label_or_branch,$view) = @_;
  my $prefix_view = $ENV{username}."_".$view;
  my $cmd;
  my $output;
  
  printf("\n [addModuleToView] - adding $module\@$label_or_branch")  if ($::options_verbose == 1);

  if ($label_or_branch =~ /[A-Z]/){	#LABES DO HAVE BIG CHARACTERS
  	$cmd = "cme setcs -module $module -label $label_or_branch $prefix_view";
  }else{							#branches ARE WRITTEN WITH SMALL LETTERS
  	$cmd = "cme setcs -module $module -branch $label_or_branch $prefix_view";
  }
  $output = qx($cmd);
  $output =~ /Success/  || die("failed: $cmd $!\n");
 }

# -------------------------------------------------------------------------------------------------------------------
#cme_freeze_ISO($::plan_0001_{"SUB_CRH_name"},$::plan_0001_{"SUB_CRH_branch"},"");

# -------------------------------------------------------------------------------------------------------------------

sub execute_plan_0001_{
	print "\n MERGE DESCRIPTION for _0001_";
	print "\n The merge scenario works on two ISO branches.          ";
	print "\n The iso branches for TOP_CRH and SUB_CRH have to be given.";
	print "\n The CNH Labels will be merged into the one SUB_CRH.    ";
	print "\n The SUB_CRH will be merged into the TOP_CRH.           ";
	print "\n ";
	print "\n EXECUTION PARAMETERS for _0001_";
	print "\n ";
	print "\n key: VIEW,           value: ".$::plan_0001_{"view_name"};
	print "\n ";
	print "\n key: TOP_CRH_name,   value: ".$::plan_0001_{"TOP_CRH_name"};
	print "\n key: TOP_CRH_branch, value: ".$::plan_0001_{"TOP_CRH_branch"};
	print "\n key: TOP_CRH_path,   value: ".$::plan_0001_{"TOP_CRH_path"};
	
	print "\n key: SUB_CRH_name,   value: ".$::plan_0001_{"SUB_CRH_name"};
	print "\n key: SUB_CRH_branch, value: ".$::plan_0001_{"SUB_CRH_branch"};
	print "\n key: SUB_CRH_path,   value: ".$::plan_0001_{"SUB_CRH_path"};
	
	my $username_up_cast = uc($ENV{username});
	my $prefix_view = $username_up_cast."_".$::plan_0001_{"view_name"};
	my $SUB_CRH_1551 = $::option_CPATH_LETTER.":\\".$prefix_view."\\".$::plan_0001_{"SUB_CRH_path"};
	my $TOP_CRH_1551 = $::option_CPATH_LETTER.":\\".$prefix_view."\\".$::plan_0001_{"TOP_CRH_path"};

	my $SUB_CRH_LABEL_new;

	foreach my $key ( keys %::plan_0001_ )
	{
		if ($key =~ /^(CNH|cnh)/){
			print "\n key: $key, value: $::plan_0001_{$key}";
		}
		
	}
	if ($::options_active){
		#Lets DO IT
		
		# create VIEW with SUB_CRH BRANCH
		createView($::plan_0001_{"view_name"});
		addModuleToView($::plan_0001_{"SUB_CRH_name"},$::plan_0001_{"SUB_CRH_branch"},$::plan_0001_{"view_name"});
		
		# checkout \LD_SubSystems_006\crh1091033_thorium_itp_pltf_sw\1551_crh1091033.cfg
		ct_checkOut($SUB_CRH_1551,$::plan_0001_{"COMMENT"});
		
		# substitute cnh modules into 1551_crh1091033.cfg
		substitute_001_modules($SUB_CRH_1551,\%::plan_0001_);
		
		# checkin \LD_SubSystems_006\crh1091033_thorium_itp_pltf_sw\1551_crh1091033.cfg
		cme_checkInFile($SUB_CRH_1551,$::plan_0001_{"COMMENT"},0);
		
		# CREATE LABEL for SUB_CRH
		$::plan_0001_{"SUB_CRH_LABEL"} = cme_freezeModules($::plan_0001_{"SUB_CRH_name"},$::plan_0001_{"SUB_CRH_branch"},"");

		#  ---------------------------------------

		# add TOP_CRH BRANCH to the VIEW
		addModuleToView($::plan_0001_{"TOP_CRH_name"},$::plan_0001_{"TOP_CRH_branch"},$::plan_0001_{"view_name"});

		# checkout \LD_SubSystems_009\crh1090921_thorium\1551_crh1090921.cfg
		ct_checkOut($TOP_CRH_1551,$::plan_0001_{"COMMENT"});

		# substitute LABEL for SUB_CRH into 1551_crh1090921.cfg
		substitute_001_modules($TOP_CRH_1551,\%::plan_0001_);

		# checkin  \LD_SubSystems_009\crh1090921_thorium\1551_crh1090921.cfg
		cme_checkInFile($TOP_CRH_1551,$::plan_0001_{"COMMENT"},0);

		# CREATE LABEL for TOP_CRH
		my $end = cme_freezeModules($::plan_0001_{"TOP_CRH_name"},$::plan_0001_{"TOP_CRH_branch"},"");
		print ("\n $end" );
		# 
		
		# delete VIEW 
		delteteView($prefix_view);

		#SUMMARY RESULT
		print ("\nSUMMARY RESULT _plan_0001_:\n".$::plan_0001_{"TOP_CRH_name"}."@".$end."\n".$::plan_0001_{"SUB_CRH_name"}."@".$::plan_0001_{"SUB_CRH_LABEL"});
		mail($ENV{username},"\nSUMMARY RESULT _plan_0001_:\n".$::plan_0001_{"TOP_CRH_name"}."@".$end."\n".$::plan_0001_{"SUB_CRH_name"}."@".$::plan_0001_{"SUB_CRH_LABEL"}) if ($::options_selfmail);
		
	}
}

# -------------------------------------------------------------------------------------------------------------------
 sub cme_timestamp
{
	my $stamp;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
	$year = $year - 100;
	$mon  = $mon + 1;
	
	$mon = "0".$mon if ($mon < 10);
	$mday = "0".$mday if ($mday < 10);
	$hour = "0".$hour if ($hour < 10);
	$min = "0".$min if ($min < 10);
	$sec = "0".$sec if ($sec < 10);
	
	$stamp = $year.$mon.$mday."_".$hour.$min;
	return $stamp;
 }

# -------------------------------------------------------------------------------------------------------------------
 sub util_lowcast_module
{
	my ($module) = @_;
	$module =~ s/CNH/cnh/;
	$module =~ s/CRH/crh/;	
	return $module;
}
# -------------------------------------------------------------------------------------------------------------------
sub substitute_001_modules{

	my $FILE;
	my @file_arr;
	my $line;
	my $line_count = 0;
	my ($path1551,$plan_0001_) = @_;
	$path1551 =~ s/\\\\/\\/;

	my $label;
	my $module;
	
	my $option_modules			= 1;
	my $Flag1551_subsystems		= 0;
	my $Flag1551_modules		= 0;

	printf("\n [substitute_001_modules] - found Project File  $path1551")  if ($::options_verbose == 1);

	open ($FILE,"<$path1551") || die "can't open $path1551";
	while(<$FILE>) {
  		#chomp;
  		push(@file_arr, $_);
	}
	close $FILE;

	#open ($FILE,">$path1551"."_temp.txt") || die "can't open $path1551";
	open ($FILE,">$path1551") || die "can't open $path1551";
	foreach $line (@file_arr){
			$module,$label = "no";
			$line_count++;
		
		    if ($line =~ /^\[SubSystems\]/) {
				$Flag1551_subsystems	= 1;
				$Flag1551_modules		= 0;
          		print $FILE ("$line");
          		next;
          	}
          	if ($line =~ /^\[Modules\]/) {   
				$Flag1551_subsystems	= 0 if ($option_modules == 1);
				$Flag1551_modules		= 1 if ($option_modules == 1);
				print $FILE ("$line");
				next;
          	}
		  	if (($Flag1551_subsystems && ($line =~ /^\[/))||($Flag1551_modules && ($line =~ /^\[/))){
  					$Flag1551_subsystems 	= 0;  
  					$Flag1551_modules 		= 0;  
					print $FILE ("$line");
					next;
  			}
  			if ($Flag1551_subsystems){
				if  (($line =~ /^\s*#/) || ($line =~ /^\s*!/)) {	#skip all commands (#)and instructions (!)
  					print $FILE ("$line");
  					next;
				}else{	
					if ($line =~ /^(CRH|crh|CNH|cnh)\d*@[0-9a-zA-Z]*/) {
  						($module,$label) = split(/@/,$line);
						chomp ($label);
						chomp ($module);
								#print ("\n ".$module." @ ".$label);
								if (util_lowcast_module($::plan_0001_{"SUB_CRH_name"}) eq util_lowcast_module($module)){
									print ("\n [substitute_001_modules] - changes for line $line_count with ".$module." to ".$$plan_0001_{"SUB_CRH_LABEL"});
									$line =~ s/([_0-9a-zA-Z]{1,})$/$$plan_0001_{"SUB_CRH_LABEL"}/;
								}
								    
									
								
						
					}
				}
  			}
  			if ($Flag1551_modules){

				if  (($line =~ /^\s*#/) || ($line =~ /^\s*!/)) {	#skip all commands (#)and instructions (!)
  					print $FILE ("$line");
  					next;
				}else{		
  					if ($line =~ /\s([_0-9a-zA-Z]{1,})$/) {
  						$label = $1; 
  						$label =~ s/^\s+//;
  						$line =~ m/^\s*([_0-9a-zA-Z]*)\\((CRH|crh|CNH|cnh)\d*)_/;
  						$module = $2; 
					
						chomp ($label);
					
						foreach my $key ( keys %$plan_0001_ )	# look for request if Module Label should be exchanged
						{
							if ($key =~ /^(CNH|cnh)/){
								#print "\n key: $key, value: $$plan_0001_{$key}";
								#print "\n $key  = $module";
								if (util_lowcast_module($key) eq util_lowcast_module($module)){
									print ("\n [substitute_001_modules] - changes for line $line_count with ".$module." to ".$$plan_0001_{$key});
								    
								    $line =~ s/([_0-9a-zA-Z]{1,})$/$$plan_0001_{$key}/;
								}
							}
						}
  						print $FILE ("$line");
  						next;
  					}
				}
  				print $FILE ("$line");
  				next;
  			}
  			

		
  			print $FILE ("$line");
	}
	
	close $FILE;
	


	
}
# -------------------------------------------------------------------------------------------------------------------
sub printlog{
	my ($log) = @_;
	print ($log) if ($::options_verbose == 1);
}

# -------------------------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------------------------
#		CME_CT_COMMANDS ported from cme_ct_commands.pm 
# -------------------------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------------------------

sub isBranch
{
  my $version = shift;
  my $result = "0";
  
  
  if(getBranchType($version) != 0)
  {
    $result = 1;     
  }
  return $result;
}

sub getBranchType
{

  my $branch = shift;
  #my $f = (caller(0))[3]; #printlog("$f ($branch)\n");   
  my $result = 0;
  $branch = lc($branch);
  if($branch =~ /(.+)_iso$/)
  {
    $result = 1;     
  }
  elsif($branch =~ /c.h\d+(_\d+)*_r\d+$/)
  {
    $result = 2;   
  }

  return $result;
}


sub cme_freezeModules
{
  my $module = uc(shift);
  my $branch = shift;
  my $comment = shift;
  my $result = -1;
  my $lbcat = "none";
  my $label = uc($branch);
  $label =~ s /_ISO$//;
  $label = $label."_".cme_timestamp();
  
  my $output;
  
  if(isBranch($branch))
  {
    my $type = getBranchType($branch);
    if($type == 1)
    {
      $lbcat = "ISO"    
    }
    elsif($type == 2)
    {
      $lbcat = "CHECKPOINT"  
    }
  }
  else
  {
    return $result;
  }
  
  $comment = "automatically checked in, comment $comment" if (length($comment) < 10);
  
  my $cmd = "cme freeze -module $module -lbcat $lbcat -branch $branch -comment \"$comment\" $label";
  printlog "\n [cme_freezeModules] - $module @ $label";

  $output = qx($cmd);
  #printlog("\n$output\n");
  if($output =~ /Success/)
  {
    $result = $label;
  }
  printf(" result: $result");
  return $result;
}


sub ct_checkOut
{
  ###check out file with no comment
  ###only check out if file is not checked out and exists
  ###pre: file must exist in view
  ###pre: file is drive:\path\file, the version is set in the view
  ###post: file is checked out

  my $doCheckOut =1;  

  my ($path2file,$comment) = @_;
  my $result = 0;
  $path2file =~ s/\//\\/g;
  my $cmd;

  $result = ct_isCheckedOut($path2file,1);

  if ($result != 1)
  {
    if ($comment eq ""){
    	$cmd = "cleartool checkout -nc $path2file";
    }else{
    	$cmd = "cleartool checkout -c  \" $comment \" $path2file";
    }
    printlog("\n [checkout file] $path2file");
    #printlog("\n $cmd");
    if($doCheckOut == 1)
    {
      my $output = qx($cmd 2>&1);
      #printlog("$output");
      if($output =~ /Checked out/)
      {
        $result = 1;
      }
      else
      {
        $result = -1;
      }
    }
    else
    {
      printlog("doCheckOut is set to 0\n\n");
    }
  }

  printlog(" returns $result");
  return $result;

}


###############################################################################


sub cme_checkInFile
{
  my $fileName = shift;
  my $comment = shift;
  my $taskID = shift;

	my $doCheckIn;
	$doCheckIn = 1;


  if($comment eq "" or length($comment) < 10)
  {
    $comment = "automatically checked in, comment $comment";
  }

  #my $f = (caller(0))[3]; printlog("$f($fileName, $comment, $taskID)\n");
  my $result = 0;


  $fileName =~ s/\//\\/g; $fileName =~ s/\\\\/\\/g;

  my $cmd = "";
  if($taskID != 0)
  {
    $cmd = "cme ci -task $taskID -identical -comment \"$comment\" $fileName";
  }
  else
  {
    $cmd = "cme ci -identical -comment \"$comment\" $fileName";
  }
  printlog("\n [checkin file] $fileName");
  if($doCheckIn == 1)
  {
    my $output = qx($cmd);
    #printlog("$output");

    if($output =~ /File\(s\) checked-in/i)
    {
      $result = 1;
    }
  }
  else
  {
    #printerr("$f($fileName, $comment, $taskID) failed\n");
    $result = -1;
  }
  
  printlog(" returns $result");
  return $result;

}


###############################################################################

sub ct_isCheckedOut
{
  ### returns 0 (no) or 1 (yes) if a special file or any files in a dir a checked out
  ### path can be drive:\path\ or drive\path\file

  my $path2file = shift;
  my $nonRecursive = shift;
  my $f = (caller(0))[3]; #printlog("$f($path2file,$nonRecursive)\n");
  my $result = -1;

  my $cmd = "ct lsco -recurse -cview $path2file";
  if($nonRecursive == 1)
  {
    if(-d $path2file)
    {
        ##use -d to get correct info for dirs
        $cmd = "ct lsco -d -cview $path2file";
    }
    else
    {
      $cmd = "ct lsco -cview $path2file";
    }
  }


  #printlog("$cmd\n");
  my $output = qx($cmd 2>&1);
  #printlog("$output\n");

  if($output =~ /checkout version/ or $output =~ /checkout directory version/)
  {
    #printlog("already checkedOut: $path2file \n");
    $result = 1;
  }
  elsif ($output eq "")
  {
    #printlog("not checkedOut: $path2file \n");
    $result = 0;
  }
  else
  {
    #printlog("ERROR: $output\n");
    $result = -1;
  }

  #printlog("$f returns $result\n");
  return $result;
}


###############################################################################
# -------------------------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------------------------
#		MAIN 
# -------------------------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------------------------
my %options=();
getopts("X:havm",\%options);
if (defined $options{h}){
		print "\nHELP  "; 
		print ("\n ");
		print ("\n ");
		print ("\n ");
		print ("\n ");
		print ("\n - v verbose");
		print ("\n - a aktivate (without -a the script will just tell what it would like to do for you)");
		print ("\n - m write mail to your login");

		exit;
}
if (defined $options{v}){
	$::options_verbose	 = 1;
}
if (defined $options{a}){
	$::options_active		 = 1;
}
if (defined $options{m}){
	$::options_selfmail		 = 1;
}



print "-X $options{X}\n" 				if (defined $options{X}) && ($::options_verbose ==1);
$::option_inputFile		 		=  $options{X} 	if defined $options{X};

read_input_file();

execute_plan_0001_();


exit;

package MyHandler;

my $flag_0001_;
my $flag_0001_merge_list;

    sub new {
        my ($type) = @_;
		$flag_0001_ = 0;
		$flag_0001_merge_list = 0;
        return bless {}, $type;
    }


    sub start_element {
        my ($self, $element) = @_;

		
        #print "Start element: $element->{Name}          $$element{Attributes}{name} $$element{Attributes}{value}\n";

		if ($element->{Name} eq "_0001_"){
			$flag_0001_ 			= 1;
		}
		if ($element->{Name} eq "merge_list"){
			$flag_0001_merge_list 	= 1;
		}

		# CONFIGURATION FOR PLAN 001
		if ($flag_0001_ == 1){
			
			if ($element->{Name} eq "VIEW"){
				$::plan_0001_{"view_name"} = $$element{Attributes}{name};
			}
			if ($element->{Name} eq "COMMENT"){
				$::plan_0001_{"COMMENT"} = $$element{Attributes}{name};
			}
			if ($element->{Name} eq "TOP_CRH"){
				$::plan_0001_{"TOP_CRH_name"}   = $$element{Attributes}{name}; 
				$::plan_0001_{"TOP_CRH_branch"} = $$element{Attributes}{branch};
				$::plan_0001_{"TOP_CRH_path"}   = $$element{Attributes}{path};
			}
			if ($element->{Name} eq "SUB_CRH"){
				$::plan_0001_{"SUB_CRH_name"}   = $$element{Attributes}{name}; 
				$::plan_0001_{"SUB_CRH_branch"} = $$element{Attributes}{branch};
				$::plan_0001_{"SUB_CRH_path"}   = $$element{Attributes}{path};
			}
			if ($element->{Name} eq "merge"){
				$::plan_0001_{$$element{Attributes}{name}} = $$element{Attributes}{label};
			}

		}
    }

    sub end_element {
        my ($self, $element) = @_;

        #print "End element: $element->{Name}\n";

		if ($element->{Name} eq "_0001_"){
			$flag_0001_				 = 0;
		}
		if ($element->{Name} eq "merge_list"){
			$flag_0001_merge_list	 = 0;
		}
    }
    


    sub characters {
        my ($self, $data) = @_;
		my ($module,$label);
		if ( $flag_0001_ & $flag_0001_merge_list  ){
			if ($data->{Data} =~ m/@/){
				($module,$label) = split (/@/,$data->{Data});
				$module =~ s/\s//g;
				$label =~ s/\s//g;
				#print ("\n".$module." @ ".$label);
				$::plan_0001_{$module} = $label;
			}

		}

    }


1;

__END__

=pod

=head1 NAME

merge_modules.pl

=head1 WARNINGS

You have to update your system form the defaulte SDE_PERL

Versin to at least 5.10

simple execute sde_perl viewConfiguration.pl -h

for more info.

The info_merge_modules.html documentation for this script can be generated :

>pod2html -infile merge_modules.pl -outfile info_merge_modules.html

=head1 VERSION

VERSION 00.01.04

=head1 SYNOPSIS

=head2 EXAMPLES

sde_perl merge_modules.pl -a -v -X merge_plan.xml

=head2 OPTIONS

=head3 -a 

=head3 -v 

=head3 -X INPUT FILE (default is merge_plan.xml)
		
=head3 -h help

=head2 MERGE DESCRIPTION for _0001_

The merge scenario works on two ISO branches.

The iso branches for TOP_CRH and SUB_CRH have to be given.

The CNH Labels will be merged into the one SUB_CRH.

The SUB_CRH will be merged into the TOP_CRH.

=head2 MERGE DESCRIPTION for _0002_

TODO


=head1 Prediction




=head1 Author

L<bohumil.kus@stericsson.com>.



=head1 TUTORIALS ? EXAMPLES


>sde_perl merge_modules.pl -a -v -X merge_plan.xml
Useless use of private variable in void context at merge_modules.pl line 250.
-X merge_plan.xml

 MERGE DESCRIPTION for _0001_
 The merge scenario works on two ISO branches.
 The iso branches for TOP_CRH and SUB_CRH have to be given.
 The CNH Labels will be merged into the one SUB_CRH.
 The SUB_CRH will be merged into the TOP_CRH.

 EXECUTION PARAMETERS for _0001_


>sde_perl merge_modules.pl -a -v -X merge_plan.xml
Useless use of private variable in void context at merge_modules.pl line 250.
-X merge_plan.xml

 MERGE DESCRIPTION for _0001_
 The merge scenario works on two ISO branches.
 The iso branches for TOP_CRH and SUB_CRH have to given.
 The CNH Labels will be merged into the one SUB_CRH.
 The SUB_CRH will be merged into the TOP_CRH.

 EXECUTION PARAMETERS for _0001_

 key: VIEW,           value: TEST_00

 key: TOP_CRH_name,   value: CRH1090921
 key: TOP_CRH_branch, value: nbg_script_developmet_iso
 key: TOP_CRH_path,   value: \LD_SubSystems_009\crh1090921_thorium\1551_crh1090921.cfg
 key: SUB_CRH_name,   value: CRH1091033
 key: SUB_CRH_branch, value: nbg_script_developmet_iso
 key: SUB_CRH_path,   value: \LD_SubSystems_006\crh1091033_thorium_itp_pltf_sw\1551_crh1091033.cfg
 key: CNH1607883, value: CNH1607883_R2D006
 key: cnh1607550, value: CNH1607550_R1D083
 key: CNH1607878, value: CNH1607878_R2C
 key: cnh1605120, value: CNH1605120_R2C
 [createView] promer00_TEST_00
 [addModuleToView] - adding CRH1091033@nbg_script_developmet_iso
 [checkout file] M:\PROMER00_TEST_00\\LD_SubSystems_006\crh1091033_thorium_itp_pltf_sw\1551_crh1091033.cfg returns 1
 [substitute_001_modules] - found Project File  M:\PROMER00_TEST_00\LD_SubSystems_006\crh1091033_thorium_itp_pltf_sw\1551_crh1091033.cfg
 [substitute_001_modules] - changes for line 598 with cnh1607550 to CNH1607550_R1D083
 [substitute_001_modules] - changes for line 613 with cnh1605120 to CNH1605120_R2C
 [substitute_001_modules] - changes for line 730 with cnh1607878 to CNH1607878_R2C
 [substitute_001_modules] - changes for line 733 with cnh1607883 to CNH1607883_R2D006
 [checkin file] M:\PROMER00_TEST_00\LD_SubSystems_006\crh1091033_thorium_itp_pltf_sw\1551_crh1091033.cfg returns 1
 [cme_freezeModules] - CRH1091033 @ NBG_SCRIPT_DEVELOPMET_120418_1053 result: NBG_SCRIPT_DEVELOPMET_120418_1053
 [addModuleToView] - adding CRH1090921@nbg_script_developmet_iso
 [checkout file] M:\PROMER00_TEST_00\\LD_SubSystems_009\crh1090921_thorium\1551_crh1090921.cfg returns 1
 [substitute_001_modules] - found Project File  M:\PROMER00_TEST_00\LD_SubSystems_009\crh1090921_thorium\1551_crh1090921.cfg
 [substitute_001_modules] - changes for line 69 with CRH1091033 to NBG_SCRIPT_DEVELOPMET_120418_1053
 [substitute_001_modules] - changes for line 75 with cnh1607550 to CNH1607550_R1D083
 [checkin file] M:\PROMER00_TEST_00\LD_SubSystems_009\crh1090921_thorium\1551_crh1090921.cfg returns 1
 [cme_freezeModules] - CRH1090921 @ NBG_SCRIPT_DEVELOPMET_120418_1054 result: NBG_SCRIPT_DEVELOPMET_120418_1054
 NBG_SCRIPT_DEVELOPMET_120418_1054
 [deleteView] promer00_PROMER00_TEST_00
SUMMARY RESULT _plan_0001_:
CRH1090921@NBG_SCRIPT_DEVELOPMET_120418_1054
CRH1091033@NBG_SCRIPT_DEVELOPMET_120418_1053
>





