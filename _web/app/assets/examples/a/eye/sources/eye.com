# Set the default tessellation to use 10 segments in each element direction.
# This command does not exist on older versions of cmgui. It is safe to ignore errors.
gfx define tessellation default minimum_divisions 10 refinement_factors 1;

#Example a/eye: Eye model
# This com file reads in all fitted components of the eye, and the datapoints of those that are digitsed.
# You can turn on and off the 3 layers of the eyeball, so you can see the inner layers (retina and choroid).

#Change the direction of the default light:
gfx modify light default dir 0 -0.5 -1

gfx create material sclera ambient 1 1 1 diffuse 1 1 1 emission 0 0 0 specular 0 0 0 alpha 0.6 shininess 0;
gfx create material cornea ambient 0.9 0.9 0.9 diffuse 0.9 0.9 0.7 emission 0 0 0 specular 0.1 0.1 0.1 alpha 0.2 shininess 0.2;
gfx create material lens ambient 0 0 0 specular 1.0 1.0 1.0 diffuse 0.4 0.4 0.6 shininess 0.9 alpha 0.3;
gfx create material optNrv ambient 0.4 0.7 0.5 diffuse 0.9 0.7 0.5 emission 0 0 0 specular 0.2 0.2 0.3 shininess 0.2;
gfx create material ciliaryBody ambient 0.4 0.14 0.11 diffuse 0.5 0.12 0.1 emission 0 0 0 specular 0.3 0.5 0.5 alpha 0.8 shininess 0.2;
gfx create material macula normal_mode ambient 1 1 1 diffuse 1 0.67 0.25 emission 0 0 0 specular 0.18 0.15 0.2 alpha 0.92 shininess 0.93;
gfx create material dgreen   diffuse 0.0 0.5 0.0 spec 0.4 0.4 0.5 shininess 0.5
gfx create material dblue    diffuse 0.0 0.1 1.0 spec 0.4 0.4 0.5 shininess 0.53
gfx cre mat yellow   diffuse 1.0 0.6 0.0

######################## 1) read in Skin Files ####
gfx read node $example/skin.exnode region skins
gfx read elem $example/skin.exelem region skins

gfx define field skins/skin_coordinatesA scale field coordinates scale_factors -0.02 -0.02 0.02
gfx define field skins/skin_coordinates offset field skin_coordinatesA offsets 365 850 -290

gfx modify g_element skins/final_skin general clear circle_discretization 6 default_coordinate skin_coordinates element_discretization "10*10*10" native_discretization none;

########### 2) read in fitted zonules ##################
gfx read node $example/zonules_trans2.exnode region zonules 
gfx read elem $example/zonules_trans2.exelem region zonules

gfx define faces egroup zonules;

gfx modify g_element zonules/zonules general clear circle_discretization 6 default_coordinate coordinates element_discretization "10*10*10" native_discretization none;

########### 3) read in fitted veins ##################
gfx read node $example/veins_angle_short.exnode region veins time -1
gfx read elem $example/veins_angle_short.exelem region veins

gfx read node $example/veins_angle_long.exnode region veins time 1 

########## create time fields to control sclera length ########## 
gfx define field length_time constant 0.0;

gfx define faces egroup veins;

gfx define field veins/length_time alias field /length_time
gfx define field veins/length_time_coordinates time_lookup field coordinates time length_time;
gfx modify g_element veins/veins general clear circle_discretization 6 default_coordinate length_time_coordinates element_discretization "10*10*10" native_discretization none;

########### 4) read in fitted arteries ##################
gfx read node $example/arteries_angle_short.exnode region arteries time -1
gfx read elem $example/arteries_angle_short.exelem region arteries

gfx read node $example/arteries_angle_long.exnode region arteries time 1 

gfx define faces egroup arteries;

gfx define field arteries/length_time alias field /length_time
gfx define field arteries/length_time_coordinates time_lookup field coordinates time length_time;
gfx modify g_element arteries/arteries general clear circle_discretization 6 default_coordinate length_time_coordinates element_discretization "10*10*10" native_discretization none;

########### 6) read in fitted retina ##################
gfx read node $example/retina_angle_short.exnode region retina time -1
gfx read elem $example/retina_angle_short.exelem region retina

gfx read node $example/retina_angle_long.exnode region retina time 1

## remove thos on top to generate a dent
gfx modify egroup retina/retina remove elements 9..16,225..240

gfx define field retina/xi_texture_coordinatesA_retina integration coordinate xi region retina seed_element 1;
gfx define field retina/xi_texture_coordinatesB_retina scale field xi_texture_coordinatesA_retina scale_factors 0.125 0.03333333 0.066666666;
gfx define field retina/xi_texture_coordinatesC_retina offset field xi_texture_coordinatesB_retina offsets 0.5 0.0 0.0;
gfx define field retina/xi_texture_coordinates_retina composite xi_texture_coordinatesC_retina.1 xi_texture_coordinatesC_retina.3 xi_texture_coordinatesC_retina.2;

gfx define field retina/length_time alias field /length_time
gfx define field retina/length_time_coordinates time_lookup field coordinates time length_time;

gfx create texture photo_mapped_retina image $example/eye_photo_mapped_retina.tiff;
gfx create material photo_mapped_retina texture photo_mapped_retina diffuse 1 1 1 ambient 0.3 0.3 0.3 alpha 0.8 shininess 0.2;

gfx define faces egroup retina;

gfx modify g_element retina/retina general clear circle_discretization 6 default_coordinate length_time_coordinates element_discretization "10*10*10" native_discretization none;

########### 5) read in macula ##################
gfx create egroup macula region retina;

gfx modify egroup retina/macula add elements 9..16

gfx define faces egroup retina/macula;

gfx modify g_element retina/macula general clear circle_discretization 6 default_coordinate length_time_coordinates element_discretization "10*10*10" native_discretization none;

gfx set order region retina/macula before retina;

###### 9) read in fitted choroid ############
########## create 2 regions, choroid for pupil size, choroid_back for sclera_length #############

### this one has discritisation 4 for ciliary body + iris, so no. of elem remove are less
### it has total no. of elem 272, remo all elements to read in later in iris and ciliarybody
gfx read node $example/choroidDilate_fitted_fitted2.exnode region choroid time 0 
gfx read elem $example/choroidDilate_fitted_fitted2.exelem region choroid

gfx read node $example/choroidConstrict_fitted_fitted2.exnode region choroid time 1 

gfx modify egroup choroid/choroid_fitted remove elements 1..272

### this one is different to the one above, it has discritisation 5 for ciliary body + iris, so no. of elem remove are higher
### it has total no. of elem 288, remo 209..288 for front elements
gfx read node $example/choroid_angle_short.exnode region choroid_back time -1
gfx read elem $example/choroid_angle_short.exelem region choroid_back

gfx read node $example/choroid_angle_long.exnode region choroid_back time 1 

gfx modify egroup choroid_back/choroid2_fitted remove elements 209..288

########## create xi_texture coordinates for choroid_back region ############
gfx define field choroid_back/xi_texture_coordinatesA_choroid integration coordinate xi seed_element 1;
gfx define field choroid_back/xi_texture_coordinatesB_choroid scale field xi_texture_coordinatesA_choroid scale_factors 0.125 0.03333333 0.071428571;
gfx define field choroid_back/xi_texture_coordinatesC_choroid offset field xi_texture_coordinatesB_choroid  offsets 0.5 0.0 0.0;
gfx define field choroid_back/xi_texture_coordinates_choroid composite xi_texture_coordinatesC_choroid.1 xi_texture_coordinatesC_choroid.3 xi_texture_coordinatesC_choroid.2;

gfx define field choroid_back/length_time alias field /length_time
gfx define field choroid_back/length_time_coordinates time_lookup field coordinates time length_time;

########## draw the 2 groups ########## 
gfx define faces egroup choroid;

########## create texture for choroid ########## 
gfx create texture eye_photo_mapped_choroid image $example/eye_photo_mapped_choroid.tiff;
gfx create material eye_photo_mapped_choroid texture eye_photo_mapped_choroid diffuse 1 1 1 ambient 0.3 0.3 0.3 alpha 0.7;

########## display the choroid backend ########## 
gfx modify g_element choroid_back/choroid2_fitted general clear circle_discretization 6 default_coordinate length_time_coordinates element_discretization "10*10*10" native_discretization none;

########### 7) read in iris ##################
gfx create egroup iris region choroid;

gfx modify egroup choroid/iris add elements 241..272

gfx define field choroid/xi_texture_coordinatesA_iris integration coordinate xi seed_element 241;
gfx define field choroid/xi_texture_coordinatesB_iris scale field xi_texture_coordinatesA_iris scale_factors 0.125 0.03333333 0.5;
gfx define field choroid/xi_texture_coordinatesC_iris offset field xi_texture_coordinatesB_iris offsets 0.5 0.0 0.0;
gfx define field choroid/xi_texture_coordinates_iris composite xi_texture_coordinatesC_iris.1 xi_texture_coordinatesC_iris.3 xi_texture_coordinatesC_iris.2;

###### textures for iris color ########
gfx create texture photo_mapped_iris_brown image $example/eye_photo_mapped_irisbrown.tiff;
gfx create material photo_mapped_iris_brown texture photo_mapped_iris_brown diffuse 1 1 1 ambient 0.3 0.3 0.3;

gfx create texture photo_mapped_iris_blue image $example/eye_photo_mapped_irisblue.tiff;
gfx create material photo_mapped_iris_blue texture photo_mapped_iris_blue diffuse 1 1 1 ambient 0.3 0.3 0.3;

gfx create texture photo_mapped_iris_grey image $example/eye_photo_mapped_irisgrey.tiff;
gfx create material photo_mapped_iris_grey texture photo_mapped_iris_grey diffuse 1 1 1 ambient 0.3 0.3 0.3;

gfx create texture photo_mapped_iris_lightbrown image $example/eye_photo_mapped_irislightbrown.tiff;
gfx create material photo_mapped_iris_lightbrown texture photo_mapped_iris_lightbrown diffuse 1 1 1 ambient 0.3 0.3 0.3;

gfx create texture photo_mapped_iris_lightbrown2 image $example/eye_photo_mapped_irislightbrown2.tiff;
gfx create material photo_mapped_iris_lightbrown2 texture photo_mapped_iris_lightbrown2 diffuse 1 1 1 ambient 0.3 0.3 0.3;

gfx create texture photo_mapped_iris_green image $example/eye_photo_mapped_irisgreen.tiff;
gfx create material photo_mapped_iris_green texture photo_mapped_iris_green diffuse 1 1 1 ambient 0.3 0.3 0.3;

########## create time fields to control pupil region ########## 
gfx define field pupil_time constant 0.5;

gfx define faces egroup choroid/iris;

gfx define field choroid/pupil_time alias field /pupil_time
gfx define field choroid/pupil_time_coordinates time_lookup field coordinates time pupil_time;
gfx modify g_element choroid/iris general clear circle_discretization 6 default_coordinate pupil_time_coordinates element_discretization "10*10*10" native_discretization none;

gfx set order region choroid/iris before choroid_fitted;

########### 8) read in ciliaryBody ##################
gfx create egroup ciliaryBody region choroid;

gfx modify egroup choroid/ciliaryBody add elements 209..240

gfx define faces egroup choroid/ciliaryBody;

gfx modify g_element choroid/ciliaryBody general clear circle_discretization 6 default_coordinate pupil_time_coordinates element_discretization "10*10*10" native_discretization none;

gfx set order region choroid/ciliaryBody before choroid_fitted;

########### 10) read in fitted Sclera ##################
gfx read node $example/sclera_angle_short.exnode region sclera time -1
gfx read elem $example/sclera_angle_short.exelem region sclera

gfx read node $example/sclera_angle_long.exnode region sclera time 1 

gfx modify egroup sclera/sclera remove elements 241..256;

gfx define faces egroup sclera;

gfx define field sclera/length_time alias field /length_time
gfx define field sclera/length_time_coordinates time_lookup field coordinates time length_time;
gfx modify g_element sclera/sclera general clear circle_discretization 6 default_coordinate length_time_coordinates element_discretization "10*10*10" native_discretization none;

########### 11) read in fitted Medial_Rectus ##################
gfx read node $example/medrect2.exnode region medrect
gfx read elem $example/medrect2.exelem region medrect

gfx define faces egroup medrect;

gfx modify g_element medrect/medrect general clear circle_discretization 6 default_coordinate coordinates element_discretization "10*10*10" native_discretization none;


########### 12) read in fitted Lateral_Rectus ##################
gfx read node $example/latrect2.exnode region latrect
gfx read elem $example/latrect2.exelem region latrect

gfx define faces egroup latrect;

gfx modify g_element latrect/latrect general clear circle_discretization 6 default_coordinate coordinates element_discretization "10*10*10" native_discretization none;

########### 13) read in fitted Inferior_Rectus ##################
gfx read node $example/infrec2.exnode region infrec
gfx read elem $example/infrec2.exelem region infrec

gfx define faces egroup infrec;

gfx modify g_element infrec/infrec general clear circle_discretization 6 default_coordinate coordinates element_discretization "10*10*10" native_discretization none;

########### 14) read in fitted Superior_Rectus ##################
gfx read node $example/suprec2.exnode region suprec
gfx read elem $example/suprec2.exelem region suprec

gfx define faces egroup suprec;

gfx modify g_element suprec/suprec general clear circle_discretization 6 default_coordinate coordinates element_discretization "10*10*10" native_discretization none;

########### 15) read in fitted Inferior_Oblique ##################
gfx read node $example/infobl2.exnode region infobl
gfx read elem $example/infobl2.exelem region infobl

gfx define faces egroup infobl;

gfx modify g_element infobl/infobl general clear circle_discretization 6 default_coordinate coordinates element_discretization "10*10*10" native_discretization none;

########### 16) read in fitted Superior_Oblique ##################
gfx read node $example/supobl2.exnode region supobl
gfx read elem $example/supobl2.exelem region supobl

gfx define faces egroup supobl;

gfx modify g_element supobl/supobl general clear circle_discretization 6 default_coordinate coordinates element_discretization "10*10*10" native_discretization none;

########### 17)read in fitted Optic_Nerve ##################
gfx read node $example/opticNerve_long.exnode region opticNerve time 1
gfx read elem $example/opticNerve_long.exelem region opticNerve

gfx read node $example/opticNerve_short.exnode region opticNerve time -1

gfx define faces egroup opticNerve;

gfx define field opticNerve/length_time alias field /length_time
gfx define field opticNerve/length_time_coordinates time_lookup field coordinates time length_time;
gfx modify g_element opticNerve/opticNerve general clear circle_discretization 6 default_coordinate length_time_coordinates element_discretization "10*10*10" native_discretization none;

########### 18) read in fitted Bone ##################
gfx read node $example/fitted_orbit.exnode region bone
gfx read elem $example/fitted_orbit.exelem region bone

gfx modify g_element bone/fitted_orbit general clear circle_discretization 6 default_coordinate coordinates element_discretization "10*10*10" native_discretization none;

########### 19) read in fitted trochlea ##################
gfx read node $example/trochlea_moved.exnode region trochlea
gfx read elem $example/trochlea_moved.exelem region trochlea

gfx modify g_element trochlea/trochlea_moved general clear circle_discretization 6 default_coordinate coordinates element_discretization "10*10*10" native_discretization none;

########### 20-22) read in light rays ##################
#gfx read node $example/ray1_rounded.exnode region ray1 time 1
#gfx read elem $example/ray1_rounded.exelem region ray1

#gfx read node $example/ray1_flatten.exnode region ray1 time -1

#gfx modify g_element ray1/ray1 general clear circle_discretization 6 default_coordinate length_time_coordinates element_discretization "4*4*4" native_discretization none;
#gfx modify g_element ray1/ray1 node_points glyph sphere general size "0.3*0.3*0.3" centre 0,0,0 font default select_on material yellow selected_material default_selected;
#gfx modify g_element ray1/ray1 lines select_on material yellow selected_material default_selected;


#gfx read node $example/ray2_rounded.exnode region ray2 time 1
#gfx read elem $example/ray2_rounded.exelem region ray2

#gfx read node $example/ray2_flatten.exnode region ray2 time -1

#gfx modify g_element ray2/ray2 general clear circle_discretization 6 default_coordinate length_time_coordinates element_discretization "4*4*4" native_discretization none;
#gfx modify g_element ray2/ray2 node_points glyph sphere general size "0.3*0.3*0.3" centre 0,0,0 font default select_on material white selected_material default_selected;
#gfx modify g_element ray2/ray2 lines select_on material black selected_material default_selected;


#gfx read node $example/ray3_rounded.exnode region ray3 time 1
#gfx read elem $example/ray3_rounded.exelem region ray3

#gfx read node $example/ray3_flatten.exnode region ray3 time -1

#gfx modify g_element ray3/ray3 general clear circle_discretization 6 default_coordinate length_time_coordinates element_discretization "4*4*4" native_discretization none;
#gfx modify g_element ray3/ray3 node_points glyph sphere general size "0.3*0.3*0.3" centre 0,0,0 font default select_on material dgreen selected_material default_selected;
#gfx modify g_element ray3/ray3 lines select_on material dgreen selected_material default_selected;

########### 20) read in fitted Lens ##################
gfx read node $example/lens_fitted.exnode region lens 
gfx read elem $example/lens_fitted.exelem region lens

#gfx read node $example/lens_fitted_rounded.exnode region lens time 1
#gfx read elem $example/lens_fitted_rounded.exelem region lens

#gfx read node $example/lens_fitted_flatten.exnode region lens time -1

########## create time fields to control sclera length ########## 
gfx define field lens_time constant 0.0;

gfx define faces egroup lens;

gfx define field lens/lens_time alias field /lens_time
gfx define field lens/lens_time_coordinates time_lookup field coordinates time lens_time;
gfx modify g_element lens/lens general clear circle_discretization 6 default_coordinate lens_time_coordinates element_discretization "10*10*10" native_discretization none;

########### 21) read in fitted cornea ##################
gfx create egroup cornea region sclera;

gfx modify egroup sclera/cornea add elements 241..256;

gfx define faces egroup sclera/cornea;

gfx modify g_element sclera/cornea general clear circle_discretization 6 default_coordinate length_time_coordinates element_discretization "10*10*10" native_discretization none;

$is_delete='';

open comfile $example/surfaces_on.com exec;


#gfx modify window 1 view parallel eye_point 121.196 292.206 -119.226 interest_point 302.954 291.844 -131.73 up_vector 0.0652311 0.339285 0.938419 view_angle 16.0997 near_clipping_plane 1.82187 far_clipping_plane 651.075 relative_viewport ndc_placement -1 1 2 2 viewport_coordinates 0 0 1 1;

if ($TESTING) {
	open comfile example test_time_lookup.cmiss execute;
 }
