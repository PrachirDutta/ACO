function W=fitnessfunc(x)


    global NFE;
    if isempty(NFE)
        NFE=0;
    end
    
    NFE=NFE+1;
%-----------------------------------------------------
global Kp
global Tw
global T1
global T2
global T3
global T4
%--------------------------------------
global Kp1
global Tw1
global T11
global T21
global T31
global T41
%-------------------------------------
global Kp2
global Tw2
global T12
global T22
global T32
global T42
%-------------------------------------


Kp=(x(1));
Tw=(x(2));
T1=(x(3));
T2=(x(4));
T3=(x(5));
T4=(x(6));
%-------------------------------------------------------
Kp1=(x(7));
Tw1=(x(8));
T11=(x(9));
T21=(x(10));
T31=(x(11));
T41=(x(12));

%------------------------------------------

Kp2=(x(13));
Tw2=(x(14));
T12=(x(15));
T22=(x(16));
T32=(x(17));
T42=(x(18));

%------------------------------------------

sim('SSSC_PODcontrol');
Dw1=abs(DW1);
Dw2=abs(DW2);


W=Dw1(end)+Dw2(end);



end