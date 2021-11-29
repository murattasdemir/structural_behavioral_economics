function  [y] = minimandGneezyLie(parameters)    
VCcontrol=diag([0.0022 0.0025 0.0022 0.0022 0.0023]);
moments = [0.33 0.49 0.65 0.37  0.5229]';
W = inv(VCcontrol);
mSimOpt=simGneezyLie(parameters);
mTemp=moments-mSimOpt;
y=mTemp'*W*mTemp;

end