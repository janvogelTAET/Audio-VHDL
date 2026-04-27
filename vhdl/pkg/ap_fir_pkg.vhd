-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing
-- Entity: ap_fir_pkg
-- Author : Waj
-------------------------------------------------------------------------------
-- Description:
-- FIR-specific constants, coefficient types, and static preset coefficients.
-- Notes:
-- * Coefficients are signed fixed-point Q1.15 (FIR_COEF_DW = 16).
-- * To avoid the Vivado warning "[Synth 8-5825] Expecting unsigned expression"
--   negative integer literals must be worked around, see C_FIR_LP9.
-- * As a workaround for Vivado not supporting unconstrained array types for 
--   simulation, a maximum array size is defined for the coefficient array, and 
--   coefficents of unused taps are defined as zero. In addition, the FIR 
--   component needs a generic for the number of taps to be used in a specific 
--   instance. :-(
-------------------------------------------------------------------------------
library ieee;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.ap_design_pkg.all;

-------------------------------------------------------------------------------
package ap_fir_pkg is

  -----------------------------------------------------------------------------
  -- FIR Configuration
  -----------------------------------------------------------------------------
  constant FIR_COEF_DW   : natural := 16;              -- Signed coefficient width
  constant FIR_COEF_FRAC : natural := FIR_COEF_DW - 1; -- Q1.(FIR_COEF_DW-1) fractional bits

  -- FIR filter coefficient array types
  type t_fir_coef  is array (natural range 127 downto 0) of signed(FIR_COEF_DW-1 downto 0);

  -----------------------------------------------------------------------------
  -- FIR Coefficient Presets
  -----------------------------------------------------------------------------
  -- Frequency notation:
  -- * fs = sampling frequency
  -- * fc = cutoff frequency
  -- * Normalized cutoff = fc/fs

  -- Preset LP9
  -- * Type: low-pass
  -- * Taps: 9
  -- * Source: user-provided `h_lp9`, quantized to Q1.15
  -- * Scaling: near-unity at DC (sum = 32766)
  constant C_FIR_LP9 : t_fir_coef := (
    8 => to_signed(655, FIR_COEF_DW),
    7 => to_signed(1638, FIR_COEF_DW),
    6 => to_signed(2949, FIR_COEF_DW),
    5 => to_signed(5243, FIR_COEF_DW),
    4 => to_signed(11796, FIR_COEF_DW),
    3 => to_signed(5243, FIR_COEF_DW),
    2 => to_signed(2949, FIR_COEF_DW),
    1 => to_signed(1638, FIR_COEF_DW),
    0 => to_signed(655, FIR_COEF_DW),
    others => to_signed(0, FIR_COEF_DW)
  );

  -- Preset HP9
  -- * Type: high-pass
  -- * Taps: 9
  -- * Source: user-provided `h_hp9`, quantized to Q1.15
  -- * Scaling: near-zero DC sum (sum = 2)
  constant C_FIR_HP9 : t_fir_coef := (
    8 => -to_signed(  655, FIR_COEF_DW),
    7 => -to_signed( 1638, FIR_COEF_DW),
    6 => -to_signed( 2949, FIR_COEF_DW),
    5 => -to_signed( 5243, FIR_COEF_DW),
    4 =>  to_signed(20972, FIR_COEF_DW),
    3 => -to_signed( 5243, FIR_COEF_DW),
    2 => -to_signed( 2949, FIR_COEF_DW),
    1 => -to_signed( 1638, FIR_COEF_DW),
    0 => -to_signed(  655, FIR_COEF_DW),
    others => to_signed(0, FIR_COEF_DW)
  );

  -- Preset LP63
  -- * Type: low-pass
  -- * Taps: 63
  -- * Source: user-provided `h_lp63_raw`, normalized, then quantized to Q1.15
  -- * Scaling: near-unity at DC (sum = 32769)
  constant C_FIR_LP63 : t_fir_coef := (
    62 => to_signed(    -7, FIR_COEF_DW),
    61 => to_signed(   -18, FIR_COEF_DW),
    60 => to_signed(   -29, FIR_COEF_DW),
    59 => to_signed(   -34, FIR_COEF_DW),
    58 => to_signed(   -27, FIR_COEF_DW),
    57 => to_signed(    -3, FIR_COEF_DW),
    56 => to_signed(    43, FIR_COEF_DW),
    55 => to_signed(   106, FIR_COEF_DW),
    54 => to_signed(   177, FIR_COEF_DW),
    53 => to_signed(   241, FIR_COEF_DW),
    52 => to_signed(   276, FIR_COEF_DW),
    51 => to_signed(   268, FIR_COEF_DW),
    50 => to_signed(   205, FIR_COEF_DW),
    49 => to_signed(    94, FIR_COEF_DW),
    48 => to_signed(   -50, FIR_COEF_DW),
    47 => to_signed(  -196, FIR_COEF_DW),
    46 => to_signed(  -306, FIR_COEF_DW),
    45 => to_signed(  -342, FIR_COEF_DW),
    44 => to_signed(  -272, FIR_COEF_DW),
    43 => to_signed(   -80, FIR_COEF_DW),
    42 => to_signed(   230, FIR_COEF_DW),
    41 => to_signed(   632, FIR_COEF_DW),
    40 => to_signed(  1079, FIR_COEF_DW),
    39 => to_signed(  1503, FIR_COEF_DW),
    38 => to_signed(  1838, FIR_COEF_DW),
    37 => to_signed(  2029, FIR_COEF_DW),
    36 => to_signed(  2049, FIR_COEF_DW),
    35 => to_signed(  1910, FIR_COEF_DW),
    34 => to_signed(  1658, FIR_COEF_DW),
    33 => to_signed(  1363, FIR_COEF_DW),
    32 => to_signed(  1101, FIR_COEF_DW),
    31 => to_signed(   942, FIR_COEF_DW),
    30 => to_signed(   942, FIR_COEF_DW),
    29 => to_signed(  1101, FIR_COEF_DW),
    28 => to_signed(  1363, FIR_COEF_DW),
    27 => to_signed(  1658, FIR_COEF_DW),
    26 => to_signed(  1910, FIR_COEF_DW),
    25 => to_signed(  2049, FIR_COEF_DW),
    24 => to_signed(  2029, FIR_COEF_DW),
    23 => to_signed(  1838, FIR_COEF_DW),
    22 => to_signed(  1503, FIR_COEF_DW),
    21 => to_signed(  1079, FIR_COEF_DW),
    20 => to_signed(   632, FIR_COEF_DW),
    19 => to_signed(   230, FIR_COEF_DW),
    18 => to_signed(   -80, FIR_COEF_DW),
    17 => to_signed(  -272, FIR_COEF_DW),
    16 => to_signed(  -342, FIR_COEF_DW),
    15 => to_signed(  -306, FIR_COEF_DW),
    14 => to_signed(  -196, FIR_COEF_DW),
    13 => to_signed(   -50, FIR_COEF_DW),
    12 => to_signed(    94, FIR_COEF_DW),
    11 => to_signed(   205, FIR_COEF_DW),
    10 => to_signed(   268, FIR_COEF_DW),
     9 => to_signed(   276, FIR_COEF_DW),
     8 => to_signed(   241, FIR_COEF_DW),
     7 => to_signed(   177, FIR_COEF_DW),
     6 => to_signed(   106, FIR_COEF_DW),
     5 => to_signed(    43, FIR_COEF_DW),
     4 => to_signed(    -3, FIR_COEF_DW),
     3 => to_signed(   -27, FIR_COEF_DW),
     2 => to_signed(   -34, FIR_COEF_DW),
     1 => to_signed(   -29, FIR_COEF_DW),
     0 => to_signed(   -18, FIR_COEF_DW),
     others => to_signed(0, FIR_COEF_DW)
  );

  -- Preset HP63
  -- * Type: high-pass
  -- * Taps: 63
  -- * Source: user-provided `h_lp63` -> spectral inversion -> quantized Q1.15
  -- * Scaling: near-zero DC sum (sum = -1)
  constant C_FIR_HP63 : t_fir_coef := (
    62 => to_signed(     7, FIR_COEF_DW),
    61 => to_signed(    18, FIR_COEF_DW),
    60 => to_signed(    29, FIR_COEF_DW),
    59 => to_signed(    34, FIR_COEF_DW),
    58 => to_signed(    27, FIR_COEF_DW),
    57 => to_signed(     3, FIR_COEF_DW),
    56 => to_signed(   -43, FIR_COEF_DW),
    55 => to_signed(  -106, FIR_COEF_DW),
    54 => to_signed(  -177, FIR_COEF_DW),
    53 => to_signed(  -241, FIR_COEF_DW),
    52 => to_signed(  -276, FIR_COEF_DW),
    51 => to_signed(  -268, FIR_COEF_DW),
    50 => to_signed(  -205, FIR_COEF_DW),
    49 => to_signed(   -94, FIR_COEF_DW),
    48 => to_signed(    50, FIR_COEF_DW),
    47 => to_signed(   196, FIR_COEF_DW),
    46 => to_signed(   306, FIR_COEF_DW),
    45 => to_signed(   342, FIR_COEF_DW),
    44 => to_signed(   272, FIR_COEF_DW),
    43 => to_signed(    80, FIR_COEF_DW),
    42 => to_signed(  -230, FIR_COEF_DW),
    41 => to_signed(  -632, FIR_COEF_DW),
    40 => to_signed( -1079, FIR_COEF_DW),
    39 => to_signed( -1503, FIR_COEF_DW),
    38 => to_signed( -1838, FIR_COEF_DW),
    37 => to_signed( -2029, FIR_COEF_DW),
    36 => to_signed( -2049, FIR_COEF_DW),
    35 => to_signed( -1910, FIR_COEF_DW),
    34 => to_signed( -1658, FIR_COEF_DW),
    33 => to_signed( -1363, FIR_COEF_DW),
    32 => to_signed( -1101, FIR_COEF_DW),
    31 => to_signed( 31826, FIR_COEF_DW),
    30 => to_signed(  -942, FIR_COEF_DW),
    29 => to_signed( -1101, FIR_COEF_DW),
    28 => to_signed( -1363, FIR_COEF_DW),
    27 => to_signed( -1658, FIR_COEF_DW),
    26 => to_signed( -1910, FIR_COEF_DW),
    25 => to_signed( -2049, FIR_COEF_DW),
    24 => to_signed( -2029, FIR_COEF_DW),
    23 => to_signed( -1838, FIR_COEF_DW),
    22 => to_signed( -1503, FIR_COEF_DW),
    21 => to_signed( -1079, FIR_COEF_DW),
    20 => to_signed(  -632, FIR_COEF_DW),
    19 => to_signed(  -230, FIR_COEF_DW),
    18 => to_signed(    80, FIR_COEF_DW),
    17 => to_signed(   272, FIR_COEF_DW),
    16 => to_signed(   342, FIR_COEF_DW),
    15 => to_signed(   306, FIR_COEF_DW),
    14 => to_signed(   196, FIR_COEF_DW),
    13 => to_signed(    50, FIR_COEF_DW),
    12 => to_signed(   -94, FIR_COEF_DW),
    11 => to_signed(  -205, FIR_COEF_DW),
    10 => to_signed(  -268, FIR_COEF_DW),
     9 => to_signed(  -276, FIR_COEF_DW),
     8 => to_signed(  -241, FIR_COEF_DW),
     7 => to_signed(  -177, FIR_COEF_DW),
     6 => to_signed(  -106, FIR_COEF_DW),
     5 => to_signed(   -43, FIR_COEF_DW),
     4 => to_signed(     3, FIR_COEF_DW),
     3 => to_signed(    27, FIR_COEF_DW),
     2 => to_signed(    34, FIR_COEF_DW),
     1 => to_signed(    29, FIR_COEF_DW),
     0 => to_signed(    18, FIR_COEF_DW),
     others => to_signed(0, FIR_COEF_DW)
  );

  -- Preset HP1K63
  -- * Type: high-pass
  -- * Taps: 63
  -- * Target (fs = 48 kHz): attenuate < 1 kHz, keep higher band near unity
  -- * Design: windowed-sinc high-pass, quantized Q1.15, zero-DC enforced
  -- * Scaling: exact zero DC sum (sum = 0), near-unity above ~2 kHz
  constant C_FIR_HP1K63 : t_fir_coef := (
    62 => to_signed(    22, FIR_COEF_DW),
    61 => to_signed(    21, FIR_COEF_DW),
    60 => to_signed(    21, FIR_COEF_DW),
    59 => to_signed(    20, FIR_COEF_DW),
    58 => to_signed(    18, FIR_COEF_DW),
    57 => to_signed(    15, FIR_COEF_DW),
    56 => to_signed(    10, FIR_COEF_DW),
    55 => to_signed(     0, FIR_COEF_DW),
    54 => to_signed(   -14, FIR_COEF_DW),
    53 => to_signed(   -34, FIR_COEF_DW),
    52 => to_signed(   -59, FIR_COEF_DW),
    51 => to_signed(   -93, FIR_COEF_DW),
    50 => to_signed(  -134, FIR_COEF_DW),
    49 => to_signed(  -184, FIR_COEF_DW),
    48 => to_signed(  -242, FIR_COEF_DW),
    47 => to_signed(  -309, FIR_COEF_DW),
    46 => to_signed(  -383, FIR_COEF_DW),
    45 => to_signed(  -464, FIR_COEF_DW),
    44 => to_signed(  -552, FIR_COEF_DW),
    43 => to_signed(  -644, FIR_COEF_DW),
    42 => to_signed(  -739, FIR_COEF_DW),
    41 => to_signed(  -835, FIR_COEF_DW),
    40 => to_signed(  -931, FIR_COEF_DW),
    39 => to_signed( -1024, FIR_COEF_DW),
    38 => to_signed( -1112, FIR_COEF_DW),
    37 => to_signed( -1194, FIR_COEF_DW),
    36 => to_signed( -1266, FIR_COEF_DW),
    35 => to_signed( -1328, FIR_COEF_DW),
    34 => to_signed( -1378, FIR_COEF_DW),
    33 => to_signed( -1415, FIR_COEF_DW),
    32 => to_signed( -1437, FIR_COEF_DW),
    31 => to_signed( 31288, FIR_COEF_DW),
    30 => to_signed( -1437, FIR_COEF_DW),
    29 => to_signed( -1415, FIR_COEF_DW),
    28 => to_signed( -1378, FIR_COEF_DW),
    27 => to_signed( -1328, FIR_COEF_DW),
    26 => to_signed( -1266, FIR_COEF_DW),
    25 => to_signed( -1194, FIR_COEF_DW),
    24 => to_signed( -1112, FIR_COEF_DW),
    23 => to_signed( -1024, FIR_COEF_DW),
    22 => to_signed(  -931, FIR_COEF_DW),
    21 => to_signed(  -835, FIR_COEF_DW),
    20 => to_signed(  -739, FIR_COEF_DW),
    19 => to_signed(  -644, FIR_COEF_DW),
    18 => to_signed(  -552, FIR_COEF_DW),
    17 => to_signed(  -464, FIR_COEF_DW),
    16 => to_signed(  -383, FIR_COEF_DW),
    15 => to_signed(  -309, FIR_COEF_DW),
    14 => to_signed(  -242, FIR_COEF_DW),
    13 => to_signed(  -184, FIR_COEF_DW),
    12 => to_signed(  -134, FIR_COEF_DW),
    11 => to_signed(   -93, FIR_COEF_DW),
    10 => to_signed(   -59, FIR_COEF_DW),
     9 => to_signed(   -34, FIR_COEF_DW),
     8 => to_signed(   -14, FIR_COEF_DW),
     7 => to_signed(     0, FIR_COEF_DW),
     6 => to_signed(    10, FIR_COEF_DW),
     5 => to_signed(    15, FIR_COEF_DW),
     4 => to_signed(    18, FIR_COEF_DW),
     3 => to_signed(    20, FIR_COEF_DW),
     2 => to_signed(    21, FIR_COEF_DW),
     1 => to_signed(    21, FIR_COEF_DW),
     0 => to_signed(    22, FIR_COEF_DW),
     others => to_signed(0, FIR_COEF_DW)
  );

  -- Preset BS2K4K9
  -- * Type: band-stop (demo)
  -- * Taps: 9
  -- * Target region (fs = 48 kHz): 2 kHz .. 4 kHz
  -- * Method: constrained least-squares (unity-sum and Q1.15 bounds)
  -- * Scaling: exact unity DC sum in Q1.15 (sum = 32767)
  constant C_FIR_BS2K4K9 : t_fir_coef := (
    8 => to_signed( 4356, FIR_COEF_DW),
    7 => to_signed( 1401, FIR_COEF_DW),
    6 => to_signed(-1150, FIR_COEF_DW),
    5 => to_signed(-2868, FIR_COEF_DW),
    4 => to_signed(29289, FIR_COEF_DW),
    3 => to_signed(-2868, FIR_COEF_DW),
    2 => to_signed(-1150, FIR_COEF_DW),
    1 => to_signed( 1401, FIR_COEF_DW),
    0 => to_signed( 4356, FIR_COEF_DW),
    others => to_signed(0, FIR_COEF_DW)
  );

  -- Preset BS2K4K63
  -- * Type: band-stop (demo)
  -- * Taps: 63
  -- * Target region (fs = 48 kHz): 2 kHz .. 4 kHz
  -- * Source: script/gen_fir_coeffs.py (notch), quantized to Q1.15
  -- * Scaling: exact unity DC sum in Q1.15 (sum = 32767)
  constant C_FIR_BS2K4K63 : t_fir_coef := (
    62 => to_signed(    39, FIR_COEF_DW),
    61 => to_signed(    29, FIR_COEF_DW),
    60 => to_signed(    15, FIR_COEF_DW),
    59 => to_signed(     0, FIR_COEF_DW),
    58 => to_signed(   -13, FIR_COEF_DW),
    57 => to_signed(   -20, FIR_COEF_DW),
    56 => to_signed(   -16, FIR_COEF_DW),
    55 => to_signed(     0, FIR_COEF_DW),
    54 => to_signed(    24, FIR_COEF_DW),
    53 => to_signed(    45, FIR_COEF_DW),
    52 => to_signed(    43, FIR_COEF_DW),
    51 => to_signed(     0, FIR_COEF_DW),
    50 => to_signed(   -97, FIR_COEF_DW),
    49 => to_signed(  -246, FIR_COEF_DW),
    48 => to_signed(  -423, FIR_COEF_DW),
    47 => to_signed(  -583, FIR_COEF_DW),
    46 => to_signed(  -668, FIR_COEF_DW),
    45 => to_signed(  -620, FIR_COEF_DW),
    44 => to_signed(  -399, FIR_COEF_DW),
    43 => to_signed(     0, FIR_COEF_DW),
    42 => to_signed(   534, FIR_COEF_DW),
    41 => to_signed(  1115, FIR_COEF_DW),
    40 => to_signed(  1624, FIR_COEF_DW),
    39 => to_signed(  1934, FIR_COEF_DW),
    38 => to_signed(  1941, FIR_COEF_DW),
    37 => to_signed(  1594, FIR_COEF_DW),
    36 => to_signed(   915, FIR_COEF_DW),
    35 => to_signed(     0, FIR_COEF_DW),
    34 => to_signed(  -996, FIR_COEF_DW),
    33 => to_signed( -1890, FIR_COEF_DW),
    32 => to_signed( -2508, FIR_COEF_DW),
    31 => to_signed( 30021, FIR_COEF_DW),
    30 => to_signed( -2508, FIR_COEF_DW),
    29 => to_signed( -1890, FIR_COEF_DW),
    28 => to_signed(  -996, FIR_COEF_DW),
    27 => to_signed(     0, FIR_COEF_DW),
    26 => to_signed(   915, FIR_COEF_DW),
    25 => to_signed(  1594, FIR_COEF_DW),
    24 => to_signed(  1941, FIR_COEF_DW),
    23 => to_signed(  1934, FIR_COEF_DW),
    22 => to_signed(  1624, FIR_COEF_DW),
    21 => to_signed(  1115, FIR_COEF_DW),
    20 => to_signed(   534, FIR_COEF_DW),
    19 => to_signed(     0, FIR_COEF_DW),
    18 => to_signed(  -399, FIR_COEF_DW),
    17 => to_signed(  -620, FIR_COEF_DW),
    16 => to_signed(  -668, FIR_COEF_DW),
    15 => to_signed(  -583, FIR_COEF_DW),
    14 => to_signed(  -423, FIR_COEF_DW),
    13 => to_signed(  -246, FIR_COEF_DW),
    12 => to_signed(   -97, FIR_COEF_DW),
    11 => to_signed(     0, FIR_COEF_DW),
    10 => to_signed(    43, FIR_COEF_DW),
     9 => to_signed(    45, FIR_COEF_DW),
     8 => to_signed(    24, FIR_COEF_DW),
     7 => to_signed(     0, FIR_COEF_DW),
     6 => to_signed(   -16, FIR_COEF_DW),
     5 => to_signed(   -20, FIR_COEF_DW),
     4 => to_signed(   -13, FIR_COEF_DW),
     3 => to_signed(     0, FIR_COEF_DW),
     2 => to_signed(    15, FIR_COEF_DW),
     1 => to_signed(    29, FIR_COEF_DW),
     0 => to_signed(    39, FIR_COEF_DW),
     others => to_signed(0, FIR_COEF_DW)
  );

  -- Preset BP3K63
  -- * Type: band-pass (aggressive)
  -- * Taps: 63
  -- * Target (fs = 48 kHz):
  --   - center frequency: 3.0 kHz
  --   - strong attenuation below ~2.0 kHz and above ~4.0 kHz
  -- * Design: constrained weighted least-squares, normalized to unity at 3 kHz
  -- * Scaling: DC rejection (sum = 0)
  constant C_FIR_BP3K63 : t_fir_coef := (
    62 => to_signed(   356, FIR_COEF_DW),
    61 => to_signed(   341, FIR_COEF_DW),
    60 => to_signed(   231, FIR_COEF_DW),
    59 => to_signed(    76, FIR_COEF_DW),
    58 => to_signed(  -146, FIR_COEF_DW),
    57 => to_signed(  -359, FIR_COEF_DW),
    56 => to_signed(  -566, FIR_COEF_DW),
    55 => to_signed(  -679, FIR_COEF_DW),
    54 => to_signed(  -710, FIR_COEF_DW),
    53 => to_signed(  -595, FIR_COEF_DW),
    52 => to_signed(  -381, FIR_COEF_DW),
    51 => to_signed(   -49, FIR_COEF_DW),
    50 => to_signed(   309, FIR_COEF_DW),
    49 => to_signed(   678, FIR_COEF_DW),
    48 => to_signed(   949, FIR_COEF_DW),
    47 => to_signed(  1111, FIR_COEF_DW),
    46 => to_signed(  1081, FIR_COEF_DW),
    45 => to_signed(   893, FIR_COEF_DW),
    44 => to_signed(   522, FIR_COEF_DW),
    43 => to_signed(    65, FIR_COEF_DW),
    42 => to_signed(  -453, FIR_COEF_DW),
    41 => to_signed(  -903, FIR_COEF_DW),
    40 => to_signed( -1250, FIR_COEF_DW),
    39 => to_signed( -1388, FIR_COEF_DW),
    38 => to_signed( -1329, FIR_COEF_DW),
    37 => to_signed( -1031, FIR_COEF_DW),
    36 => to_signed(  -581, FIR_COEF_DW),
    35 => to_signed(    -3, FIR_COEF_DW),
    34 => to_signed(   566, FIR_COEF_DW),
    33 => to_signed(  1077, FIR_COEF_DW),
    32 => to_signed(  1403, FIR_COEF_DW),
    31 => to_signed(  1532, FIR_COEF_DW),
    30 => to_signed(  1403, FIR_COEF_DW),
    29 => to_signed(  1077, FIR_COEF_DW),
    28 => to_signed(   566, FIR_COEF_DW),
    27 => to_signed(    -3, FIR_COEF_DW),
    26 => to_signed(  -581, FIR_COEF_DW),
    25 => to_signed( -1031, FIR_COEF_DW),
    24 => to_signed( -1329, FIR_COEF_DW),
    23 => to_signed( -1388, FIR_COEF_DW),
    22 => to_signed( -1250, FIR_COEF_DW),
    21 => to_signed(  -903, FIR_COEF_DW),
    20 => to_signed(  -453, FIR_COEF_DW),
    19 => to_signed(    65, FIR_COEF_DW),
    18 => to_signed(   522, FIR_COEF_DW),
    17 => to_signed(   893, FIR_COEF_DW),
    16 => to_signed(  1081, FIR_COEF_DW),
    15 => to_signed(  1111, FIR_COEF_DW),
    14 => to_signed(   949, FIR_COEF_DW),
    13 => to_signed(   678, FIR_COEF_DW),
    12 => to_signed(   309, FIR_COEF_DW),
    11 => to_signed(   -49, FIR_COEF_DW),
    10 => to_signed(  -381, FIR_COEF_DW),
     9 => to_signed(  -595, FIR_COEF_DW),
     8 => to_signed(  -710, FIR_COEF_DW),
     7 => to_signed(  -679, FIR_COEF_DW),
     6 => to_signed(  -566, FIR_COEF_DW),
     5 => to_signed(  -359, FIR_COEF_DW),
     4 => to_signed(  -146, FIR_COEF_DW),
     3 => to_signed(    76, FIR_COEF_DW),
     2 => to_signed(   231, FIR_COEF_DW),
     1 => to_signed(   341, FIR_COEF_DW),
     0 => to_signed(   356, FIR_COEF_DW),
     others => to_signed(0, FIR_COEF_DW)
  );

  -- Preset NOTCH5
  -- * Type: notch (band-stop)
  -- * Taps: 5
  -- * Notch center: fs/4 -> 12.0 kHz when fs = 48 kHz
  -- * Shape: simple symmetric notch with unity at DC and Nyquist
  -- * Scaling: unity -> 8192 + 0 + 16384 + 0 + 8192 = 32768
  constant C_FIR_NOTCH5 : t_fir_coef := (
    4 => to_signed(8192, FIR_COEF_DW),
    3 => to_signed(0, FIR_COEF_DW),
    2 => to_signed(16384, FIR_COEF_DW),
    1 => to_signed(0, FIR_COEF_DW),
    0 => to_signed(8192, FIR_COEF_DW),
    others => to_signed(0, FIR_COEF_DW)
  );

  -- Preset Comb21
  -- * Type: comb 
  -- * Taps: 21
  -- * Notch center: k*fs/(2*20)-> k*1.2 kHz when fs = 48 kHz
  -- * Shape: Comb filter with unity at DC and Nyquist
  -- * Scaling: unity -> 16384 + 19*0 + 16384 = 32768
  constant C_FIR_COMB21 : t_fir_coef := (
    0 | 20 => to_signed(16384, FIR_COEF_DW),
    others => to_signed(0, FIR_COEF_DW)
  );

  -----------------------------------------------------------------------------
  -- FIR utility functions
  -----------------------------------------------------------------------------
  --------------------------------- FIR output data width for full precision --
  function f_fir_out_dw(n_taps : natural) return natural;


end package ap_fir_pkg;
-------------------------------------------------------------------------------

package body ap_fir_pkg is
-------------------------------------------------------------------------------

  --------------------------------- FIR output data width for full precision --
  function f_fir_out_dw(n_taps : natural) return natural is
  begin
    return ADC_DW + FIR_COEF_DW + natural(ceil(log2(real(n_taps))));
  end f_fir_out_dw;

end package body ap_fir_pkg;