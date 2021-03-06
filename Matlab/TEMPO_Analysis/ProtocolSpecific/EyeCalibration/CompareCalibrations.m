function CompareCalibrations(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);

TEMPO_Defs;
ProtocolDefs;

global Eye_Data;

%check if calibration file exists, and read calibration params in from file
i = size(PATH,2) - 1;
while PATH(i) ~='\'	%Analysis directory is one branch below Raw Data Dir
    i = i - 1;
end   
PATHIN = [PATH(1:i) 'Analysis\Eye_Calibration\'];

run_loc = find(FILE == 'r');
file_root_name = FILE(1:run_loc-1);
linear_in_name = [PATHIN file_root_name '_linear_eye_calib.mat'];
nonlin_in_name = [PATHIN file_root_name '_nonlin_eye_calib.mat'];
if exist(linear_in_name)
    buff = sprintf('loading eye calibration data from %s', linear_in_name);
    disp(buff);
    Pars_linear = load(linear_in_name);
    %Note: Pars will be a structure, Pars.M is the loaded matrix
end
if exist(nonlin_in_name)
    buff = sprintf('loading eye calibration data from %s', nonlin_in_name);
    disp(buff);
    Pars_nonlin = load(nonlin_in_name);
end
    
lh = data.eye_positions(LEYE_H, :);
lv = data.eye_positions(LEYE_V, :);
rh = data.eye_positions(REYE_H, :);
rv = data.eye_positions(REYE_V, :);
fh = data.targ_params(TARG_XCTR, :, FP);
fv = data.targ_params(TARG_YCTR, :, FP);

%calculate calibrated positions according to LINEAR fit
[cllh, cllv] = ComputeCalibratedEyePosn(lh, lv, Pars_linear.M(:, LEYE_H)', Pars_linear.M(:, LEYE_V)' );
[clrh, clrv] = ComputeCalibratedEyePosn(rh, rv, Pars_linear.M(:, REYE_H)', Pars_linear.M(:, REYE_V)' );
%calculate calibrated positions according to NONLINEAR fit
[cnlh, cnlv] = ComputeCalibratedEyePosn_Nonlin(lh, lv, Pars_nonlin.M(:, LEYE_H)', Pars_nonlin.M(:, LEYE_V)' );
[cnrh, cnrv] = ComputeCalibratedEyePosn_Nonlin(rh, rv, Pars_nonlin.M(:, REYE_H)', Pars_nonlin.M(:, REYE_V)' );




figure;

% 1) plot RAW data
subplot (4,1,1);
hold on;

%plot the positions of the LEFT eye in blue, RIGHT eye in red, and fixation
plot(lh, lv, 'ro');
plot(rh, rv, 'bo');
plot(fh, fv, 'g+');

title (FILE);
hold off;

% 2) plot the positions according to LINEAR fit.

subplot(4,1,2);
hold on;

plot(cllh, cllv, 'ro');
plot(clrh, clrv, 'bo');

%plot the positions of the fixation point
fh = data.targ_params(TARG_XCTR, :, FP);
fv = data.targ_params(TARG_YCTR, :, FP);
plot(fh, fv, 'g+');

title('Linear Fit');
hold off;

% 3) plot the positions according to NONLINEAR fit.

subplot(4,1,3);
hold on;

plot(cnlh, cnlv, 'ro');
plot(cnrh, cnrv, 'bo');

%plot the positions of the fixation point
fh = data.targ_params(TARG_XCTR, :, FP);
fv = data.targ_params(TARG_YCTR, :, FP);
plot(fh, fv, 'g+');

title('Nonlinear Fit');
hold off;


% 4) Calculate and print sequential F-tests on the two fits for each eye.

%calculate horizontal error on fits
%note: horizontal error is the major concern since horizontal components are used to compute vergence.
Eye_Data = [cllh' cllv' fh'];
linear_l_err = EyeCalib_Func(Pars_linear.M(:, LEYE_H));
clear Eye_Data; global Eye_Data;
Eye_Data = [clrh' clrv' fh'];
linear_r_err = EyeCalib_Func(Pars_linear.M(:, REYE_H));
clear Eye_Data; global Eye_Data;
Eye_Data = [cnlh' cnlv' fh'];
nonlin_l_err = EyeCalib_Func_NonLin(Pars_nonlin.M(:, LEYE_H));
clear Eye_Data; global Eye_Data;
Eye_Data = [cnrh' cnrv' fh'];
nonlin_r_err = EyeCalib_Func_NonLin(Pars_nonlin.M(:, REYE_H));
clear Eye_Data; 

%perform F-tests for both left and right eyes.
Npts = EndTrial - BegTrial + 1; %num trials in eye calibration run
Nfree_linear_fit_params = 3;    %offset and 2 gains
Nfree_nonlin_fit_params = 5;    %offset, 2 gains, and 2 second orders

Fseq_left  = ( (linear_l_err - nonlin_l_err) / (Nfree_nonlin_fit_params - Nfree_linear_fit_params) / ...
    (nonlin_l_err/(Npts - Nfree_nonlin_fit_params)));
Pseq_left  = 1 - fcdf(Fseq_left,  (Nfree_nonlin_fit_params-Nfree_linear_fit_params), (Npts-Nfree_nonlin_fit_params));
Fseq_right = ( (linear_r_err - nonlin_r_err) / (Nfree_nonlin_fit_params - Nfree_linear_fit_params) / ...
    (nonlin_r_err/(Npts - Nfree_nonlin_fit_params)));
Pseq_right = 1 - fcdf(Fseq_right, (Nfree_nonlin_fit_params-Nfree_linear_fit_params), (Npts-Nfree_nonlin_fit_params));

%print fitting parameters and F-test data.
subplot (4,1,4);
axis([0 100 0 100]);    axis('off');
xpos = -10; ypos = 100;
font_size = 8;  bump_size = 10;
ypos = ypos - bump_size;    ypos = ypos - bump_size;

line = sprintf('Linear Fit:');
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
line = sprintf('  LEYE_H calib = %5.3f + (%5.3f * LEYE_H) + (%5.3f * LEYE_V)', ...
    Pars_linear.M(1, LEYE_H), Pars_linear.M(2, LEYE_H), Pars_linear.M(3, LEYE_H));
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
line = sprintf('  REYE_H calib = %5.3f + (%5.3f * REYE_H) + (%5.3f * REYE_V)', ...
    Pars_linear.M(1, REYE_H), Pars_linear.M(2, REYE_H), Pars_linear.M(3, REYE_H));
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
line = sprintf('Nonlinear Fit:');
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
line = sprintf('  LEYE_H calib = %5.3f + (%5.3f * LEYE_H) + (%5.3f * LEYE_H^2) + (%5.3f * LEYE_V) + (%5.3f * LEYE_V^2)', ...
    Pars_nonlin .M(1, LEYE_H), Pars_nonlin.M(2, LEYE_H), Pars_nonlin.M(3, LEYE_H), Pars_nonlin.M(4, LEYE_H), Pars_nonlin.M(5, LEYE_H));
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
line = sprintf('  REYE_H calib = %5.3f + (%5.3f * REYE_H) + (%5.3f * REYE_H^2) + (%5.3f * REYE_V) + (%5.3f * REYE_V^2)', ...
    Pars_nonlin.M(1, REYE_H), Pars_nonlin.M(2, REYE_H), Pars_nonlin.M(3, REYE_H), Pars_nonlin.M(4, REYE_H), Pars_nonlin.M(5, REYE_H));
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size*2;
line = sprintf('Sequential F-test - Left eye');
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
line = sprintf('      F = %7.3f, P = %7.5f', Fseq_left, Pseq_left); 
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
line = sprintf('Sequential F-test - Right eye');
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
line = sprintf('      F = %7.3f, P = %7.5f', Fseq_right, Pseq_right); 
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
line = sprintf('Num linear params = %2d, Num nonlinear params = %2d, Num trials = %2d', Nfree_linear_fit_params, Nfree_nonlin_fit_params, Npts);
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;



return;