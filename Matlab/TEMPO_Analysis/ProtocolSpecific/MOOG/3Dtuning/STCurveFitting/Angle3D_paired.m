function output=Angle3D_paired(Azi1,Azi2, Ele1,Ele2)
% function output=Angle3D_paired(Azi1,Azi2, Ele1,Ele2)
output=(180/pi) * acos( sin(Ele1*pi/180).* sin(Ele2*pi/180)  +  cos(Ele2*pi/180).* sin(Azi2*pi/180).* cos(Ele1*pi/180).* sin(Azi1*pi/180) + cos(Ele2*pi/180).* cos(Azi2*pi/180).* cos(Ele1*pi/180).* cos(Azi1*pi/180));            
