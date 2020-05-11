#!/usr/bin/perl

#CST:xrisam00

#setencoding ISO-8859-2
use POSIX 'locale_h';
setlocale(LC_CTYPE,"cs_CZ.ISO8859-2") || print STDERR "unable to load locale";
#Parameters parsing and setting settings
use Getopt::Long;
Getopt::Long::Configure ("bundling");
#variables
use Cwd 'cwd';

use File::Basename;

###############################################################################
# variables
###############################################################################
my @LIST_OF_FILES;
my @SORTED_LIST_OF_FILES;
my @LIST_OF_DIRECTORIES;
my @LIST_OF_DEFINED_TYPES= ("int","double","float","char");
my $HELP="\nUsage:\n\t--help\t\t\tto print help\n\t--input=fileordir\tspecifies"
."input path\n\t--nosubdir\t\tsearch only in current dir\n\t--output=filename\t"
."output filename\n\t-k\t\t\tto count keywords\n\t-o\t\t\tcounts operators\n\t".
"-i\t\t\tcounts ID\n\t-w=pattern\t\tcounts pattern\n\t-c\t\t\tcounts comments ".
"characters\n\t-p\t\t\twrites only filenames withouth path\n".
"Note that parameters k,o,i,w,c can be combined only with help, p parameters\n";

my @KEYWORDS = ("auto","break","case","char","const","continue","default",
"doube","do","else","enum","extern","float","for","goto","if","inline","int",
"long","register","restrict","return","short","signed","sizeof","static",
"struct","switch","typedef","union","unisgned","void","volatile","_Bool",
"_Complex","_Imaginary");

my @OPERATORS = ("<<=",">>=","<<",">>","<=",">=","->","&=","^=","|=","==","!=",
"+=","-=","/=","%=","*=","++","--","&&","||","^","|","<",">","=",".","&","*",
"+","-","~","!","/","%");
my $TOTAL=0;
my $ACTUAL=0;
my $help=0;
my $input_path= '';
my $outputh_file='';
my $nosubdir=0;
my $comments=0;
my $keywords=0;
my $operators=0;
my $identificators=0;
my $patterns='';
my $nopath=0;
my $option = 0;
my @LINES;
my $line;
my $whole_file;
my $is_multiline_macro=0;
my $is_multiline_string=0;
my $is_multiline_oneline_comment=0;
my $is_comment=0;
my $is_multiline_typedef=0;
my $max_line_lenght=0;
my $left_side;
my $right_side;
my $index=0;
my $notice_next_line=0;
###############################################################################
#parsing command line arguments
###############################################################################

GetOptions(     'help+' => \$help,
                'input=s' => \$input_path,
                'nosubdir+' => \$nosubdir,
                'output=s' => \$output_file,
                '-','k+' => \$keywords,
                '-','o+' => \$operators,
                '-','i+' => \$identificators,
                '-','w=s' => \$patterns,
                '-','c+' => \$comments,
                '-','p+' => \$nopath
);
#chop first character of short parameter -w
if($patterns ne ''){
   substr $patterns, 0, 1, "";
}
#print help if asked to
if($help == 1){
  print $HELP;
  exit(0);
}
#check if there was any input path parameter
if($input_path eq ''){
   $input_path = cwd;
}
#check for validity of command line arguments
if($help > 1 || $nosubdir > 1 || $keywords > 1 || $operators > 1 ||
 $identificators > 1 || $nopath > 1){
  print STDERR 'invalid arguments\n';
  exit(1);
}
if(($input_path eq '') || ($nosubdir > 1) || ($output_file eq '') || ($keywords > 1) ||
($operators > 1) || ($identificators > 1) || ($nopath > 1) || ($comments > 1)){
  print STDERR 'invalid arguments1'.$HELP;
  exit(1);
}
my $tempik;
if($patterns eq ''){
   $tempik = 0;
}
else{
   $tempik = 1;
}
if(($comments + $identificators + $operators + $keywords + $tempik)ne 1 ){
  print STDERR 'invalid arguments2'.$HELP;
  exit(1);
}
###############################################################################
# validate input and output file/path
###############################################################################
#redirects STDOUT to file if needed by arguments
if($output_file ne ''){
  #returns OUTPUT_FILE_ERROR cannot redirect output
	open (STDOUT, '>', "$output_file") || exit(3);
}

#chcek if input folder/file exists and is readable
if (!((-e $input_path) && (-r $input_path) )){
  print STDERR $input_path.'given argument is neither file or path';
  #return INPUT_FILE_ERROR does not exists
  exit(2);
} 

#if input is directory
if (-d $input_path) {
  #nonrecursively pass through given directory
  if($nosubdir eq 1){
    #if opening folder fails returns 2
    opendir ( DIR, $input_path ) || exit(2);
    #for each file in folder
    while( ($filename = readdir(DIR) )){
      #if it is a file
      if(-f $filename){
        #if filename ends with .c or .h
        if($filename =~ m/\.[ch]$/){
          #store filename for further processing
          push(@LIST_OF_FILES,$filename);
        }
      } 
    }
    closedir(DIR);
  }
  else{
    #add to list each file in given folder 
    #if opening folder fails returns 2
    opendir ( DIR, $input_path ) || exit(2);
    #for each file/subfolder in folder
    while( ($filename = readdir(DIR) )){
      #if filename is a subdirectory not pointing to itself and to upper folder
      if(-d $filename && $filename ne '.' && $filename ne '..'){
         #store full folder path for further processing
         push(@LIST_OF_DIRECTORIES,$input_path.'/'.$filename);
      }
      #if it is a file
      if(-f $filename){
        #if filename ends with .c or .h
        if($filename =~ m/\.[ch]$/){
          #store filename for further processing
          push(@LIST_OF_FILES,$filename);
        }
      }

    }
    closedir(DIR);  
    foreach $DIRECTORY(@LIST_OF_DIRECTORIES){
       opendir ( DIR, $DIRECTORY ) || exit(21);
       while(($filename = readdir(DIR))){
          $filename =$DIRECTORY.'/'.$filename;
          if(-d $filename && $filename ne $DIRECTORY.'/.' && $filename ne $DIRECTORY.'/..'){
             #store full folder path for further processing
             push(@LIST_OF_DIRECTORIES,$filename);
          }
          #if it is a file
          if(-f $filename){
             #if filename ends with .c or .h
             if($filename =~ m/\.[ch]$/){
                #store filename for further processing
                push(@LIST_OF_FILES,$filename);
             }
          }
       }
       closedir(DIR);
    }
  }
}
else{
  # if argument is file
  if(-f $input_path ){
    #if argument is set 
    if($nosubdir){
      #exit ARGUMENT_ERROR;
      exit(1);
    }
    #it is file
    else{
      #push to stack
      push(@LIST_OF_FILES,$input_path);
    }
  }
  else{
    #given filepath is nor file or folder
    #return INPUT_FILE_ERROR
    print STDERR $input_path." is neither file or directory";
    exit(2);
  }
}

###############################################################################
#sorting list of files
###############################################################################
#if nopath parameter is not set
if($nopath == 0){
   #sorting whole filepath
   @SORTED_LIST_OF_FILES = sort @LIST_OF_FILES;
}
#sorting by filenames only
else{
   @SORTED_LIST_OF_FILES = sort {(basename($a) <=> basename($b)) || $a cmp $b} @LIST_OF_FILES;
}

###############################################################################
# main program loop 
# manipulates with @LIST_OF_FILES and argument settings 
# pass through all lines of each file, counts what is needed
###############################################################################

my $index0=0;
foreach $filename(@SORTED_LIST_OF_FILES){
   open($FILE,$filename) || exit(2);
   #reading input
   @LINES = <$FILE>;
   close($FILE);
###############################################################################
#transform quoted sequences to upper case
###############################################################################
   #create one string from an array
   $whole_file = join ("\n",@LINES);
   #replace every quoted string with uppercase quoted string
   $whole_file =~ s/(\"[\w\s\d]*?\")/uc($1)/ge;
   #convert file string to an array dellimited by newline character \n
   @LINES = split(/\n/, $whole_file);
###############################################################################
# remove macros
###############################################################################
   $index = 0;
   if($patterns eq ''){
      foreach $line(@LINES){
         #search for any macro
         if($line =~ m/^#[\s]*?(define|if|ifdef|ifndef|elif|else|endif|undef|pragma|line|error|include)/){
            #if found macro continues on next line
            if($line =~ m/\\[^\S\n]*?$/){
               #notice it
               $is_multiline_macro = 1;
            }
            else {
               $is_multiline_macro = 0;
            }
            #delete line of a macro
            delete $LINES[$index];
         }
         else{
            #if previous line was multiline macro
            if($is_multiline_macro eq 1){
               #find out whether macro continues
               if($line =~ m/\\[^\S\n]*?$/){
                  #notice it
                  $is_multiline_macro = 1;
               }
               else{
                  $is_multiline_macro = 0;
               }
               #delete continuing macro
               delete $LINES[$index];
            }
         }
         $index++;
      }
   }
###############################################################################
# count comments
###############################################################################
   if($comments eq 1){
      foreach $line(@LINES){
         #replace string literal with string with the same length full of spaces
         $line =~ s/(\"[^\n]*?[^\\]*\")/"[ ]{".length($1)."}"/ge;
      }
      #concatenate lines to one string
      $whole_file = join ("\n",@LINES);
      #count block comments and substitue them with single space
      while($whole_file =~ s/\/\*.*?\*\// /gs){
         $ACTUAL = $ACTUAL + length($&);
      }
      #split back to an array
      @LINES = split(/\n/, $whole_file);
      #count line comments and substitue them with single space
      foreach $line(@LINES){
         #if on that line continues line comment
         if($is_comment eq 1){
            #if comment doesnt continue on next line
            if($line != /[\\]$/){
               $is_comment = 0;
            }
            $ACTUAL = $ACTUAL + length($line);
         }
         # if line contains line comment
         if($line =~ /\/\//){
            #if line comment continues on next line
            if($line =~ /[\\]$/){
               $is_comment = 1;
               #count length of comment
               $line =~ /\/\/.*$/;
               $ACTUAL = $ACTUAL + length($&);
            }
            else{
               #count length of comment
               $line =~ /\/\/.*$/;
               $ACTUAL = $ACTUAL + length($&);
            }
         }
      }
   }
###############################################################################
# count operators
###############################################################################
   elsif($operators eq 1){
   ############################################################################
   # delete string literals
   ############################################################################
   #delete oneline string literals
   foreach $line(@LINES){
      #delete empty string literal
      $line =~ s/\"\"/ /g;
      #delete character string literals
      $line =~ s/\".*?[^\\]\"/ /g;
      #delete wide string literals
      $line =~ s/L\".*?[^\\]\"/ /g;
   }
   #delete multiline string litrals
   foreach $line(@LINES){
      if($is_multiline_string eq 1){
         #if line doesnt contain not backlashed quote
         if($line !~ m/^[^\\]*?\"/){
            # if line doesnt contain backlash at the end of string
            if($line !~ m/\\[\s]*?$/){
               $is_multiline_string = 0;
            }
            else{
               #syntax error
               exit(123);
            }
         }
         #string literal ends at that line
         else{
            #delete end part of multiline string literal
            $line =~ s/^(.*?|[^\\])\"/ /;
         }
      }
      #if there is some multiline literal
      if($line =~ /\([^\\]*?\".*?\\$/ ){
         #if in string literal was any backlashed quote delete it
         while($line =~ s/\".*?\\$/\\/){}
         #delete remaining backlash
         $line =~ s/\\$/ /;
         #set string literal context
         $is_multiline_string = 1;
      }
   }
   ############################################################################
   # delete comments
   ############################################################################
   #delete block comments
   foreach $line(@LINES){
      if($is_comment eq 1){
         #if line contains ending sequence of block comment
         if($line =~ m/\*\//){
            #if one block ends here but anoher starts
            if($line =~ m/\/\*.*?\/\*.*?\*\//){
               #delete ending of first one
               $line =~ s/^.*?\*\// /;
               #delete new one
               $line =~ s/\/\*.*?\*\// /;
            }
            else{
               #delete ending of block comment
               $line =~ s/^.*?\*\// /;
            }
            $is_comment = 0;
         }
         #no occurence of ending of block comment
         else{
            #delete whole line
            $line = ' ';
         }
      }
      #if block comment starts on that line
      if($line =~ m/\/\*/){
         #if comment ends on that line
         if($line =~ m/\/\*.*?\*\//){
            #delete it
            $line =~ s/\/\*.*?\*\// /;
         }
         #comment continues on next line
         else{
            $is_comment = 1;
            #delete it
            $line =~ s/\/\*.*?$/ /;
         }
      }
   }
   #delete line comments
   foreach $line(@LINES){
      #if multiline online comment context is set
      if($is_multiline_oneline_comment eq 1){
         #if multiline comment ends on that line
         if($line !~ m/\\[\s]*?$/){
            $is_multiline_oneline_comment = 0;
         }
         #delete line comment
         $line =~ s/\/\/.*?$/ /
      }
      #if line contains line comments
      if($line =~ m/\/\//){
         #if //-like comment continues on next line
         if($line =~ m/\\[\s]*?$/){
            $is_multiline_oneline_comment = 1;
         }
         #delete line comment
         $line =~ s/\/\/.*?$/ /
      }

   }
   ###########################################################################
   #search for user defined types
   ###########################################################################
   foreach $line(@LINES){
      #search for typedef occurance
      if($line =~ /typedef/){
         #if typedef ends on that line
         if($line =~ /;[\s]*$/){
            #store every user definend type
            while($line =~ s/(typedef[ ]+)([a-zA-Z][a-zA-Z0-9]*?)([;,])/
                           $1.$3.$'/ge){
               push(@LIST_OF_DEFINED_TYPES,$2);
            }
         }
         else{$is_multiline_typedef = 1;}
      }
      #if we expect on next line name of new type
      if($notice_next_line eq 1){
         $line =~ /([a-zA-Z][a-zA-Z0-9]*)/;
         #store it
         push(@LIST_OF_DEFINED_TYPES,$1);
      }
      if($is_multiline_typedef eq 1){
         #if multiline typedef ends here
         if($line =~ /[}]/){
            #if on that line is name of new type
            if($line =~ /([a-zA-Z][a-zA-Z0-9])*[\s]*;[\s]*$/){
               push(@LIST_OF_DEFINED_TYPES,$1);
            }
            #on next line will be named new type
            else{
               $notice_next_line = 1;
            }
            $is_multiline_typedef = 0;
         }
      }
   }
   #delete each definition of pointer
   foreach $line(@LINES){
      foreach $type(@LIST_OF_DEFINED_TYPES){
         #if line contains definition of new variable
         if($line =~ /^[\s]*($type)[\s]*\*/){
            #delete all stars on that line
            $line =~ s/$type."[\s]*\*"/ /e;
         }
      }
   }
   #delete all occurences of ...
   foreach $line(@LINES){
      while ($line =~ s/\.\.\.//g){}
   }
   foreach $line(@LINES){
      foreach $operatorzzz(@OPERATORS){
         while($line =~ s/\Q$operatorzzz\E//g){
         print STDERR $&."\n";
            $ACTUAL++;
         }
      }
   }
   }
###############################################################################
# count identifiers
###############################################################################
   elsif($identificators eq 1){
   ############################################################################
   # delete string literals
   ############################################################################
   #delete oneline string literals
   foreach $line(@LINES){
      #delete empty string literal
      $line =~ s/\"\"/ /g;
      #delete character string literals
      $line =~ s/\".*?[^\\]\"/ /g;
      #delete wide string literals
      $line =~ s/L\".*?[^\\]\"/ /g;
   }
   #delete multiline string litrals
   foreach $line(@LINES){
      if($is_multiline_string eq 1){
         #if line doesnt contain not backlashed quote
         if($line !~ m/^[^\\]*?\"/){
            # if line doesnt contain backlash at the end of string
            if($line !~ m/\\[\s]*?$/){
               $is_multiline_string = 0;
            }
            else{
               #syntax error
               exit(123);
            }
         }
         #string literal ends at that line
         else{
            #delete end part of multiline string literal
            $line =~ s/^(.*?|[^\\])\"/ /;
         }
      }
      #if there is some multiline literal
      if($line =~ /\([^\\]*?\".*?\\$/ ){
         #if in string literal was any backlashed quote delete it
         while($line =~ s/\".*?\\$/\\/){}
         #delete remaining backlash
         $line =~ s/\\$/ /;
         #set string literal context
         $is_multiline_string = 1;
      }
   }
   ############################################################################
   # delete comments
   ############################################################################
   #delete block comments
   foreach $line(@LINES){
      if($is_comment eq 1){
         #if line contains ending sequence of block comment
         if($line =~ m/\*\//){
            #if one block ends here but anoher starts
            if($line =~ m/\/\*.*?\/\*.*?\*\//){
               #delete ending of first one
               $line =~ s/^.*?\*\// /;
               #delete new one
               $line =~ s/\/\*.*?\*\// /;
            }
            else{
               #delete ending of block comment
               $line =~ s/^.*?\*\// /;
            }
            $is_comment = 0;
         }
         #no occurence of ending of block comment
         else{
            #delete whole line
            $line = ' ';
         }
      }
      #if block comment starts on that line
      if($line =~ m/\/\*/){
         #if comment ends on that line
         if($line =~ m/\/\*.*?\*\//){
            #delete it
            $line =~ s/\/\*.*?\*\// /;
         }
         #comment continues on next line
         else{
            $is_comment = 1;
            #delete it
            $line =~ s/\/\*.*?$/ /;
         }
      }
   }
   #delete line comments
   foreach $line(@LINES){
      #if multiline online comment context is set
      if($is_multiline_oneline_comment eq 1){
         #if multiline comment ends on that line
         if($line !~ m/\\[\s]*?$/){
            $is_multiline_oneline_comment = 0;
         }
         #delete line comment
         $line =~ s/\/\/.*?$/ /
      }
      #if line contains line comments
      if($line =~ m/\/\//){
         #if //-like comment continues on next line
         if($line =~ m/\\[\s]*?$/){
            $is_multiline_oneline_comment = 1;
         }
         #delete line comment
         $line =~ s/\/\/.*?$/ /
      }

   }
   ############################################################################
   # delete keywords
   ############################################################################
   foreach $line(@LINES){
      foreach $keyword(@KEYWORDS){
         #search for keyword and delete it
         while($line =~ s/\b$keyword\b/ /g){}
      }
   }
   ############################################################################
   # delete operators
   ############################################################################
   foreach $line(@LINES){
      foreach $operator(@OPERATORS){
            while($line =~ s/\Q$operator\E/ /g){}
      }
   }
   #delete constants
   foreach $line(@LINES){
      #delete numeric constants
      $line =~ s/[\b();,][\d]+?[\b();,]/ /g;
      #delete character literal
      $line =~ s/['].[']/ /g;
   }
   ############################################################################
   # count identifiers
   ############################################################################
   foreach $line(@LINES){
      while($line =~ /[_a-zA-Z][_a-zA-Z0-9]*/g){
         $ACTUAL++;
      }
   }
   }

###############################################################################
# count keywords
###############################################################################
   elsif($keywords eq 1){
   ############################################################################
   # delete string literals
   ############################################################################
   #delete oneline string literals
   foreach $line(@LINES){
      #delete empty string literal
      $line =~ s/\"\"/ /g;
      #delete character string literals
      $line =~ s/\".*?[^\\]\"/ /g;
      #delete wide string literals
      $line =~ s/L\".*?[^\\]\"/ /g;
   }
   #delete multiline string litrals
   foreach $line(@LINES){
      if($is_multiline_string eq 1){
         #if line doesnt contain not backlashed quote
         if($line !~ m/^[^\\]*?\"/){
            # if line doesnt contain backlash at the end of string
            if($line !~ m/\\[\s]*?$/){
               $is_multiline_string = 0;
            }
            else{
               #syntax error
               exit(123);
            }
         }
         #string literal ends at that line
         else{
            #delete end part of multiline string literal
            $line =~ s/^(.*?|[^\\])\"/ /;
         }
      }
      #if there is some multiline literal
      if($line =~ /\([^\\]*?\".*?\\$/ ){
         #if in string literal was any backlashed quote delete it
         while($line =~ s/\".*?\\$/\\/){}
         #delete remaining backlash
         $line =~ s/\\$/ /;
         #set string literal context
         $is_multiline_string = 1;
      }
   }
   ############################################################################
   # delete comments
   ############################################################################
   #delete block comments
   foreach $line(@LINES){
      if($is_comment eq 1){
         #if line contains ending sequence of block comment
         if($line =~ m/\*\//){
            #if one block ends here but anoher starts
            if($line =~ m/\/\*.*?\/\*.*?\*\//){
               #delete ending of first one
               $line =~ s/^.*?\*\// /;
               #delete new one
               $line =~ s/\/\*.*?\*\// /;
            }
            else{
               #delete ending of block comment
               $line =~ s/^.*?\*\// /;
            }
            $is_comment = 0;
         }
         #no occurence of ending of block comment
         else{
            #delete whole line
            $line = ' ';
         }
      }
      #if block comment starts on that line
      if($line =~ m/\/\*/){
         #if comment ends on that line
         if($line =~ m/\/\*.*?\*\//){
            #delete it
            $line =~ s/\/\*.*?\*\// /;
         }
         #comment continues on next line
         else{
            $is_comment = 1;
            #delete it
            $line =~ s/\/\*.*?$/ /;
         }
      }
   }
   #delete line comments
   foreach $line(@LINES){
      #if multiline online comment context is set
      if($is_multiline_oneline_comment eq 1){
         #if multiline comment ends on that line
         if($line !~ m/\\[\s]*?$/){
            $is_multiline_oneline_comment = 0;
         }
         #delete line comment
         $line =~ s/\/\/.*?$/ /
      }
      #if line contains line comments
      if($line =~ m/\/\//){
         #if //-like comment continues on next line
         if($line =~ m/\\[\s]*?$/){
            $is_multiline_oneline_comment = 1;
         }
         #delete line comment
         $line =~ s/\/\/.*?$/ /
      }
      
   }
   #count occurence of keywords and replace each occurene with single space
   foreach $line(@LINES){
      foreach $keyword(@KEYWORDS){
         #search for keyword
         while($line =~ /\b$keyword\b/g){
            $ACTUAL++;
         }
      }
   }
   }
###############################################################################
# count pattern
###############################################################################
   else{
      foreach $line(@LINES){
          #search for patterns
          while($line =~ /\Q$patterns\E/g){
             $ACTUAL++;
          }
      }
   }
###############################################################################
# end counting
###############################################################################
# add to filepath counted variable
   $SORTED_LIST_OF_FILES[$index0] = $SORTED_LIST_OF_FILES[$index0].' '.$ACTUAL;
   $TOTAL = $TOTAL + $ACTUAL;
   $ACTUAL = 0;
   $index0++;
   $is_multiline_macro=0;
   $is_multiline_string=0;
   $is_multiline_oneline_comment=0;
   $is_comment=0;

}
###############################################################################
# end loop through list of files
###############################################################################
###############################################################################
# find longest line
###############################################################################
foreach $line(@SORTED_LIST_OF_FILES){
   #count max length of full string
   if($nopath eq 0){
      if($max_line_length < length($line)){
         $max_line_length = length($line);
      }
   }
   #count max length of filename and counted value
   else{
      #split line to filename and data
      $line =~ m/[ ][\d]*$/;
      $right_side = $&;
      $left_side = $`;
      if($max_line_length < (length(basename($left_side))+length($right_side))){
         $max_line_length =length(basename($left_side))+length($right_side);
      }
   }
}
if($max_line_length < (length('CELKEM ')+length($TOTAL))){
   $max_line_length = (length('CELKEM ')+length($TOTAL));
}

###############################################################################
# add required spaces
###############################################################################
my $j =0;
my $dif_len =0;
foreach $line(@SORTED_LIST_OF_FILES){
   #nopath is set
   if($nopath eq 1){
      #split line to filename and data
      $line =~ m/[ ][\d]*$/;
      #right side contains single space and numeric value representing data
      $right_side = $&;
      #left side contains filename
      $left_side = basename($`);
      #eval how much additional spaces are required
      $dif_len = $max_line_length - (length($left_side)+length($right_side));
      #add required number of spaces
      for($i=0;$i<$dif_len;$i++){
         $left_side = $left_side.' ';
      }
      #replace original value with new one
      $SORTED_LIST_OF_FILES[$j]=$left_side.$right_side;
   }
   #nopath is not set
   else{
      #split line to filename and data
      $line =~ m/[ ][\d]*$/;
      #right side contains single space and numeric value representing data
      $right_side = $&;
      #left side contains filename+path
      $left_side = $`;
      #eval how much additional spaces are required
      $dif_len = $max_line_length - (length($left_side)+length($right_side));
      #add required number of spaces
      for($i=0;$i<$dif_len;$i++){
         $left_side = $left_side.' ';
      }
      #replace original value with new one
      $SORTED_LIST_OF_FILES[$j]=$left_side.$right_side;
   }
   $j++;
}

###############################################################################
# output to file
###############################################################################
foreach $line(@SORTED_LIST_OF_FILES){
   #print result
   print $line."\n";
}
#print total statistics
$line = 'CELKEM ';
for($i=0;i<($max_line_length - (length($line)+length($TOTAL)));$i++){
   $line = $line.' ';
}
print $line.$TOTAL."\n";
