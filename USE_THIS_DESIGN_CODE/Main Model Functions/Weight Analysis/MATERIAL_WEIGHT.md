# Spreadsheet component weight model

`SD_MAIN_AIRCRAFT_DESIGN_CODE.m` uses the one aircraft row in `Component_Data`:

```matlab
[Weight_Data,Weight_Sensitivity] = Read_Material_Weight(Configuration_filename,config_row,component_row);
Design_Input.Material_Empty_lb(config_row) = Weight_Data.W_empty;
Design_Input.Material_Empty_2x_lb(config_row) = Weight_Sensitivity.W_empty_2x;
```

Both row numbers are 1, meaning Excel row 2. `Main_Input` supplies wetted
areas, `Airfoil_Data` supplies the matching configuration label, and
`Component_Data` supplies materials, densities, thicknesses and direct weights.
Mission sizing uses only the nominal empty weight; the 2× case is for the
comparison plot.

## Weight equations

- Fuselage, wing and tails: `1.05 * density * wetted area * skin thickness`.
  A positive entered component weight overrides this estimate. Missing or
  nonpositive skin thickness uses the existing 2.5 mm default.
- Solid bulkheads: `N_bulkhead * Width_bulkhead * Height_bulkhead *
  Depth_bulkhead * rho_LW_balsa`. The three dimensions in ft describe one
  rectangular prism. Positive `W_bulkhead` overrides this estimate.
- Wing spars: `N_wing_spar * W_wing_spar`. Enter the weight of one 1 m spar
  in `W_wing_spar` and its count in `N_wing_spar`. The current inputs are
  `2 * 0.293 = 0.586 lb` total.
- Empty weight sums shells, spar, bulkheads, systems and ballast. Payload is
  reported separately, and the mission battery is sized later.
- The 2× case adds the nominal weight of each analytically estimated LWPLA
  shell; measured components, spar and bulkheads do not increase.

All weights are lb, densities lb/ft³, areas ft² and thicknesses ft. No CG
inputs or calculations are used by this weight path.

## Spar and bulkhead inputs in the current workbook

| Column | Input | Current example |
| --- | --- | ---: |
| T | `Bulkhead_Mat` | `rho_LW_balsa` |
| Z | `W_wing_spar`, lb per spar | 0.293 |
| AA | `W_bulkhead` override, lb | 0 |
| AB | `rho_LW_balsa`, lb/ft³ | 5.5 |
| AC | `N_bulkhead` | 4 |
| AD | `Width_bulkhead`, ft | 0.30 |
| AE | `Height_bulkhead`, ft | 0.35 |
| AF | `Depth_bulkhead`, ft | 0.01 |
| AG | `N_wing_spar` | 2 |

`test_material_weight` checks the shell equation, spar addition, bulkhead
estimate and override, and 2× sensitivity exclusions.
