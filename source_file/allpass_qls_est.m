SR = 48000;

T = readtable("spkr_response.csv");
measured_om = table2array(T(:,"Freq"))/SR*2;
measured_phase = table2array(T(:,"Phase"))/180*pi;

om = [0; measured_om(12:end-90,:); 1];
T_phase = [0; measured_phase(12:end-90,:); 0];


H = 1 * exp(-j * T_phase);

semilogx(om*SR/2, angle(H), '.', om*SR/2, abs(H), '.')

N = 128;
f = fdesign.arbmagnphase('N,F,H', N,om,H);
designmethods(f,'fir')

Hd = design(f,'allfir', SystemObject = true);

hfvt = fvtool(Hd{:});
legend(hfvt,'Equiripple Hd(1)', 'FIR Least-Squares Hd(2)','Frequency Sampling  Hd(3)', ...
    Location = 'NorthEast')
ax = hfvt.CurrentAxes; 
ax.NextPlot = 'add';
semilogx(ax,om,20*log10(abs(H)),'k--', 'LineWidth', 2)


hfvt(2) = fvtool(Hd{:}, Analysis = 'phase');
legend(hfvt(2),'Equiripple Hd(1)', 'FIR Least-Squares Hd(2)','Frequency Sampling Hd(3)')

ax = hfvt(2).CurrentAxes; 
ax.NextPlot = 'add';
plot(ax, om, unwrap(angle(H)),'k--', 'LineWidth', 2)

A = coeffs(Hd{2});
writestruct(A,'FIR_COEFFS.xml')