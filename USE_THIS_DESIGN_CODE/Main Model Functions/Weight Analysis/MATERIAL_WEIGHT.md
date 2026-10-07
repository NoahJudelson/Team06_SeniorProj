# Component weight model

Edit `Component_Data` in
`Input Excel Sheets/Design Configurations/ZW_Snr_Proj_Initial_Design_Config.xlsx`.
Keep the existing column names and select the aircraft row in the main
script. Weights are lb, densities are lb/ft³, lengths and skin thicknesses
are ft, and wetted areas are ft². Wetted areas come from `Main_Input` in
the same workbook.

Positive entered component weights override estimates. Fuselage, wing,
and tail shells use `weight = 1.05 * density * wetted area * skin thickness`.
Missing or nonpositive thickness uses 2.5 mm converted to ft. Absent tails
contribute zero unless a measured weight is entered. Spar weight is
`N_wing_spar * W_wing_spar`, where `W_wing_spar` is the weight of one spar.
Bulkheads use `count * width * height * depth * density`, unless their total
weight is entered directly.

Empty weight sums the nose, shells, spars, bulkheads, ballast, and systems.
It excludes payload and the mission battery. `Read_Material_Weight.m`
returns this scalar to the main script; `sizing.m` uses it at the existing
empty-weight calculation and sizes the battery through the mission equations.

Set `WeightModelOn = 1` for Component or `0` for Raymer. Set
`WeightPlotsOn = 1` to show the breakdown and comparison plots; plotting
does not export files. The comparison evaluates Raymer at the converged
Component gross weight. It also doubles only estimated LWPLA shells;
measured components, spars, and bulkheads stay unchanged. These comparison
cases are empty-weight estimates, not separate converged sizing runs.
