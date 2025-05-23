/decl/sprite_accessory/marking/frame
	name = "FBP Department Stripe"
	icon_state = "single_stripe"
	body_parts = list(BP_CHEST)
	species_allowed = list(/decl/species/utility_frame::uid, /decl/species/positronic::uid)
	icon = 'mods/species/utility_frames/icons/markings.dmi'
	color_blend = ICON_MULTIPLY
	uid = "acc_marking_frame_stripe"

/decl/sprite_accessory/marking/frame/head_stripe
	name = "FBP Head Stripe"
	icon_state = "head_stripe"
	body_parts = list(BP_HEAD)
	uid = "acc_marking_frame_stripe_head"

/decl/sprite_accessory/marking/frame/double_stripe
	name = "FBP Department Stripes"
	icon_state = "double_stripe"
	uid = "acc_marking_frame_stripe_double"

/decl/sprite_accessory/marking/frame/shoulder_stripe
	name = "FBP Shoulder Markings"
	icon_state = "shoulder_stripe"
	uid = "acc_marking_frame_shoulder"

/decl/sprite_accessory/marking/frame/plating
	name = "FBP Body Plating"
	icon_state = "plating"
	body_parts = list(BP_GROIN, BP_CHEST)
	uid = "acc_marking_frame_plating"

/decl/sprite_accessory/marking/frame/barcode
	name = "FBP Matrix Barcode"
	icon_state = "barcode"
	body_parts = list(BP_CHEST)
	uid = "acc_marking_frame_barcode"

/decl/sprite_accessory/marking/frame/plating/legs
	name = "FBP Leg Plating"
	body_parts = list(BP_L_LEG, BP_R_LEG)
	uid = "acc_marking_frame_plating_leg"

/decl/sprite_accessory/marking/frame/plating/head
	name = "FBP Head Plating"
	body_parts = list(BP_HEAD)
	uid = "acc_marking_frame_plating_head"
