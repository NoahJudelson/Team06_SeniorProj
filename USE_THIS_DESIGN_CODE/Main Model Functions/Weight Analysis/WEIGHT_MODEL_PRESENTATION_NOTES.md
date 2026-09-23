# Component weight model: slide notes

## Slide bullets

- Added a component-based empty-weight option using the selected spreadsheet row.
- LWPLA fuselage, wing, and tail shell weights come from wetted area × skin thickness × material density × 1.05. Entered component weights override the shell estimates.
- Installed systems and ballast count toward empty weight; payload is added separately. Mission sizing then adds the required battery or fuel.
- The green component bar sizes the aircraft. The orange Raymer UAV Prop bar is the closest benchmark; the muted Homebuilt Composite bar adds context. Raymer estimates are evaluated once at the same gross takeoff weight.

## Brief speaker notes

The `Component_Data` row supplies material, thickness, measured weights, and systems weight; `Main_Input` supplies wetted areas. The code sums the structural shells and installed systems to get a fixed empty weight. It then iterates the mission until the gross takeoff weight covers empty weight, payload, and the mission battery or fuel. Raymer's empirical equations are evaluated afterward for context; they do not drive this component-model run. The slide plot shows the UAV Prop and Homebuilt Composite benchmarks; the comparison table retains every Raymer category.

For the current `JB_V1_FP` output, the component empty weight is **20 lb** to two significant figures: fuselage 3.6 lb, wing 7.0 lb, horizontal tail 1.4 lb, vertical tail 0.97 lb, and systems 7.3 lb. The current gross takeoff weight, **51 lb**, is 20.21 lb empty + 8.8 lb payload + 22.36 lb battery before rounding. The mission battery fraction is 43.5%; that is why gross weight is much higher than the green empty-weight bar. The arithmetic in the saved output balances, but the battery requirement depends on the mission and propulsion inputs and should be reviewed if 43.5% is unexpected.
