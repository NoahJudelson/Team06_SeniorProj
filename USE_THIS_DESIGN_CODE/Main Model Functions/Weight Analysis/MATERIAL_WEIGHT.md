# Selected-row material weight model

The spreadsheet section of `MAIN_AIRCRAFT_DESIGN_CODE.m` now runs:

```matlab
[Weight_Data,CG_Data] = Read_Material_Weight(Configuration_filename,config_row);
Design_Input.Material_Empty_lb = nan(height(Design_Input),1);
Design_Input.Material_Empty_lb(config_row) = Weight_Data.W_empty;
```

`config_row` is the aircraft data row, excluding the header. For example, 2
means Excel row 3. The SAME row must describe the same configuration in
`Main_Input`, `Airfoil_Data`, and `Component_Data`. Only this row is calculated;
other component rows may remain unfinished. The output tables each have one row.

`sizing.m` reads `Design_Input.Material_Empty_lb(Config_Row)` and uses:

```matlab
We = materialEmptyWeight;
We_W0 = We/W0_guess;
```

This path bypasses Raymer. Other drivers without the material-weight assignment
still use Raymer. `sizing_VSP.m` supports the same assignment, but its driver
currently defines geometry manually; ensure the workbook geometry matches before
attaching a weight to the corresponding VSP configuration. The demo and VSP
driver inputs were not changed by this simplification.

## Equations and units

The implementation follows the supplied Weight function with explicit sections:

- Fuselage: `density * Swet_f * Thick_f * 1.05`.
- Wing: `density * Sref_w * Airfoil.Thick_w * MAC_w * 1.05`.
- Tails: `density * Sref * MAC * Airfoil.Thick * 1.05`.
- Measured component weights override those estimates and receive no 1.05 factor.
- Empty weight sums airframe, ballast, and installed systems, excluding payload.
- Loaded weight adds payload; CG is `sum(weight * x) / sum(weight)`.

All weights are lb, distances ft, areas ft^2, and densities lb/ft^3.
Airfoil thicknesses are dimensionless thickness/chord ratios. No gravity or
metric conversion factor is needed. The earlier area-density feature was removed.
The existing second horizontal tail and systems entries are retained so their
weights remain accounted for.

## Component_Data inputs

Use the single Component_Data tab. No additional tab is required.

| Inputs | What to enter |
| --- | --- |
| `W_nose`, `W_fuse`, `W_wing`, `W_h1`, `W_h2`, `W_v1`, `W_v2` | Measured lb; zero selects an estimate. Zero nose weight is included in the fuselage estimate. |
| Matching `Xcg_*` columns | Position in ft from the nose; zero selects geometric CG for fuselage, wing, and tails. |
| `W_pay`, `Xcg_pay` | Payload weight and its x position. |
| `W_ballast`, `Xcg_ballast` | Ballast weight and its x position. |
| `W_systems`, `Xcg_systems` | Other installed equipment weight and its combined x position. |
| `Fuse_Mat`, `Wing_Mat`, tail `*_Mat` | Exact density column name, such as `rho_LWPLA`. |
| `rho_LWPLA`, `rho_bulk` | Bulk density in lb/ft^3 on the same row. |
| `Thick_f` | Fuselage thickness in ft. |
| `X_LE_wing`, tail `X_LE_*` | Root leading-edge x position in ft for geometric CG. |

Enter zeros for absent components. A zero-area, zero-weight tail is skipped.
Keep mission payload arguments consistent with the component payload. Mission
sizing adds fuel or propulsion battery separately; exclude these from empty
weight. The reported loaded CG includes the component payload, not mission
fuel/battery or crew.

`test_material_weight` checks the equations and confirms that selecting row 2
works with an unfinished row 1. Its synthetic values are not aircraft inputs.
