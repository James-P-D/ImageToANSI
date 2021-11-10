# TODOs
#
# * Accept input as parameter
# * Percentage progress
# * Commenting
# * Reenable warnings/strict :D

#use warnings;
#use strict;
use GD;
use Term::ANSIColor;
use open qw/:std :utf8/;
use Encode;

sub rgb_to_int {
    my ($r, $g, $b) = @_;
    return ($r << 16) + ($g << 8) + ($b << 0);
}

sub int_to_rgb {
    my ($rgb) = @_;
    
    my $r = $rgb >> 16;
    my $g = ($rgb >> 8) & 0xFF;
    my $b = $rgb & 0xFF;
    
    return ($r, $g, $b);
}

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
    #printf("%d ", $win10_colors_dict{$closest_color_index});
    return $win10_colors_dict{$closest_color_index};
}



my $COLUMNS = 80;
 
#my $image = new GD::Image('line.png') or die;
#my $image = new GD::Image('steps.png') or die;
#my $image = new GD::Image('blocks.png') or die;
my $image = new GD::Image('homer.png') or die;
#my $image = new GD::Image('circle.png') or die;
#my $image = new GD::Image('white.png') or die;

#my $image = new GD::Image('square.png') or die;
#my $image = new GD::Image('mona_lisa.jpg') or die;
#my $image = new GD::Image('van_gogh.jpg') or die;
#my $image = new GD::Image('van_gogh2.jpg') or die;

my $width = $image->width;
my $height = $image->height;
printf("width = %d\n", $width);
printf("height = %d\n", $height);

my $block_size = $width / $COLUMNS;
printf("block_size = %f\n", $block_size);

my @block_colors;

for (my $y_block = 0; $y_block < ($height / $block_size); $y_block++) {
    for (my $x_block = 0; $x_block < $COLUMNS; $x_block++) {

        my %colors_dict = ();  
        for (my $x = $x_block * $block_size; $x < (($x_block+1) * $block_size); $x++){
            for (my $y = $y_block * $block_size; $y < (($y_block + 1) * $block_size); $y++) {
                my $pixel_index = $image->getPixel($x, $y);
                my ($r, $g, $b) = $image->rgb($pixel_index);                
                my $rgb = rgb_to_int($r, $g, $b);
                
                if (exists($colors_dict{$rgb})) {
                    $colors_dict{$rgb}++;   
                } else {
                    $colors_dict{$rgb} = 1;
                }
            }
        }
        my $mode_color = -1;
        my $mode_color_freq = -1;
        foreach my $key (keys(%colors_dict)) {
            #printf("%X, count = %d\n", $key, $colors_dict{$key});
            if($colors_dict{$key} > $mode_color_freq) {
                $mode_color_freq = $colors_dict{$key};
                $mode_color = $key;           
            }
        }
        
        $block_colors[$x_block][$y_block] = get_ansi_color(int_to_rgb($mode_color));
    }
}

system("CHCP 65001");

for (my $y_block = 0; $y_block < ($height / $block_size); $y_block+=2) {
    for (my $x_block = 0; $x_block < $COLUMNS; $x_block++) {
        printf("\x{1B}[%d;%dm\x{2584}",
            $block_colors[$x_block][$y_block+1],
            $block_colors[$x_block][$y_block]+10);
    }
    printf("\x{1B}[0m\n");
}

system("CHCP 437");
