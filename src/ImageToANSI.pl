# TODOs
#
# * Commenting
# * Reenable warnings/strict :D

#use warnings;
#use strict;
use GD;
use open qw/:std :utf8/;

#################################################################
# usage()
#################################################################

sub usage {
    printf("Usage:\n");
    printf("perl ImageToANSI.pl IMAGE_FILE [options]:\n");
    printf("     [Options] - /q     (quiet mode)\n");
    printf("               - /c X   (columns (default X=80))\n");
    exit();
}

#################################################################
# parse_args()
#################################################################

sub parse_args {
    my ($ARGV) = @_;
    
    my $image;
    my $quiet_mode = 0;
    my $columns = 80;
    
    my $arg_num = 0;
    while ($arg_num <= $#ARGV) {
        if ($arg_num == 0) {
            $image = new GD::Image($ARGV[$arg_num]) or die;
        } else {
            if ($ARGV[$arg_num] eq "/q") {
                $quiet_mode = 1;
            } elsif ($ARGV[$arg_num] eq "/c") {
                $arg_num++;        
                if ($arg_num == $#ARGV + 1) {
                    printf("Expected additional integer parameter after '/c'\n");
                    usage();
                } else {
                    $columns = $ARGV[$arg_num];
                }
            } else {
              printf("Unknown parameter: %s\n", $ARGV[$arg_num]);
              usage();
            }
        }
        $arg_num++;
    }

    return ($image, $quiet_mode, $columns);
}

#################################################################
# rgb_to_int()
#################################################################

sub rgb_to_int {
    my ($r, $g, $b) = @_;
    return ($r << 16) + ($g << 8) + ($b << 0);
}

#################################################################
# int_to_rgb()
#################################################################

sub int_to_rgb {
    my ($rgb) = @_;
    
    my $r = $rgb >> 16;
    my $g = ($rgb >> 8) & 0xFF;
    my $b = $rgb & 0xFF;
    
    return ($r, $g, $b);
}

#################################################################
# win10_colors_dict()
#################################################################

# Taken from https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit
my %win10_colors_dict = ();
$win10_colors_dict{rgb_to_int( 12,  12,  12)} = 30; # Black
$win10_colors_dict{rgb_to_int(197,  15,  31)} = 31; # Red
$win10_colors_dict{rgb_to_int( 19, 161,  14)} = 32; # Green
$win10_colors_dict{rgb_to_int(193, 156,   0)} = 33; # Yellow
$win10_colors_dict{rgb_to_int(  0,  55, 218)} = 34; # Blue
$win10_colors_dict{rgb_to_int(136,  23, 152)} = 35; # Magenta
$win10_colors_dict{rgb_to_int( 58, 150, 221)} = 36; # Cyan
$win10_colors_dict{rgb_to_int(204, 204, 204)} = 37; # White
$win10_colors_dict{rgb_to_int(118, 118, 118)} = 90; # Bright black (Gray)
$win10_colors_dict{rgb_to_int(231,  72,  86)} = 91; # Bright red
$win10_colors_dict{rgb_to_int( 22, 198,  12)} = 92; # Bright green
$win10_colors_dict{rgb_to_int(249, 241, 165)} = 93; # Bright yellow
$win10_colors_dict{rgb_to_int( 59, 120, 255)} = 94; # Bright blue
$win10_colors_dict{rgb_to_int(180,   0, 158)} = 95; # Bright magenta
$win10_colors_dict{rgb_to_int( 97, 214, 214)} = 96; # Bright cyan
$win10_colors_dict{rgb_to_int(242, 242, 242)} = 97; # Bright white

#################################################################
# get_ansi_color()
#################################################################

sub get_ansi_color {
    my (($r1, $g1, $b1)) = @_;
    my $closest_color = (255 ** 2) + (255 ** 2) + (255 ** 2);
    my $closest_color_index = 0;
    
    foreach my $key (keys(%win10_colors_dict)) {
        my ($r2, $g2, $b2) = int_to_rgb($key);

        my $d = (($r2-$r1) ** 2) + (($g2-$g1) ** 2) + (($b2-$b1) ** 2);
        if ($d < $closest_color) {
            $closest_color = $d;
            $closest_color_index = $key;
        }        
    }

    return $win10_colors_dict{$closest_color_index};
}

#################################################################
# Start of actual program
#################################################################

# Check we have atleast one parameter
if ($#ARGV == -1) {
    usage();    
}

# Get the image file, quiet-mode and number of columns
my ($image, $quiet_mode, $columns) = parse_args($ARGV);

# Calculate the size of each block
my $width = $image->width;
my $height = $image->height;
my $block_size = $width / $columns;
if (!$quiet_mode) {
    printf("width = %d\n", $width);
    printf("height = %d\n", $height);
    printf("block_size = %f\n", $block_size);
}

# Create the array of ANSI block colors
my @block_colors;

# Percentage complete counter
my $pc_complete = 0;

for (my $y_block = 0; $y_block < ($height / $block_size); $y_block++) {
    for (my $x_block = 0; $x_block < $columns; $x_block++) {

        # Create a dictionary of RGB-to-frequency data
        my %colors_dict = ();  
        for (my $x = $x_block * $block_size; $x < (($x_block+1) * $block_size); $x++){
            for (my $y = $y_block * $block_size; $y < (($y_block + 1) * $block_size); $y++) {
                my $pixel_index = $image->getPixel($x, $y);
                my ($r, $g, $b) = $image->rgb($pixel_index);                
                my $rgb = rgb_to_int($r, $g, $b);
                                
                if (exists($colors_dict{$rgb})) {
                    # If color already exists in dictionary, increment..
                    $colors_dict{$rgb}++;   
                } else {
                    # ..otherwise just set to 1
                    $colors_dict{$rgb} = 1;
                }
            }
        }
        
        # Find the most popular color in the block
        my $mode_color = -1;
        my $mode_color_freq = -1;
        foreach my $key (keys(%colors_dict)) {
            if($colors_dict{$key} > $mode_color_freq) {
                $mode_color_freq = $colors_dict{$key};
                $mode_color = $key;           
            }
        }
        
        # Set the ANSI code for the block
        $block_colors[$x_block][$y_block] = get_ansi_color(int_to_rgb($mode_color));
    }
    
    # Display the percentage complete if not in quiet-mode
    if (!$quiet_mode) {
        $pc_complete = ($y_block / ($height / $block_size)) * 100;
        printf("%3d%\n", $pc_complete);
    }
}

if (!$quiet_mode) {
    printf("Complete!\n");
}

# Change the codepage so we can display 0x220 extended ASCII character for lower-block
system(sprintf("CHCP 65001 %s", $quiet_mode ? "> nul" : ""));

for (my $y_block = 0; $y_block < ($height / $block_size); $y_block += 2) {
    for (my $x_block = 0; $x_block < $columns; $x_block++) {
        printf("\x{1B}[%d;%dm\x{2584}",
            $block_colors[$x_block][$y_block+1],
            $block_colors[$x_block][$y_block]+10);
    }
    printf("\x{1B}[0m\n");
}

# Change the codepage back to default
system(sprintf("CHCP 437 %s", $quiet_mode ? "> nul" : ""));
