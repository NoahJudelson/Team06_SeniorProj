# Component weight model

Edit `Component_Data` in
`Input Excel Sheets/Design Configurations/ZW_Snr_Proj_Initial_Design_Config.xlsx`.
Select aircraft rows in `SD_MAIN_AIRCRAFT_DESIGN_CODE.m`. Wetted areas come
from `Main_Input`. Units: lb, ft, ft², and lb/ft³.

Shell weight is `1.05 * density * wetted area * thickness`; unusable thickness
defaults to 2.5 mm converted to ft. Positive measured weights override
estimates; absent tails contribute zero unless measured. Spar weight is
`count * weight per spar`. Bulkhead weight is
`count * width * height * depth * density` unless measured.

Empty weight includes nose, shells, spars, bulkheads, ballast, and
`W_systems` (include propulsion and avionics once here). Payload, crew,
battery, and fuel are separate sizing terms.

`Read_Material_Weight.m` returns scalar `W_empty` to the main script;
`sizing.m` uses it throughout the gross-weight iteration.

Set `WeightModelOn = 1` for Component or `0` for Raymer.
`WeightPlotsOn = 1` shows the breakdown and two-bar comparison.
Raymer is evaluated at converged Component gross weight for comparison only.
