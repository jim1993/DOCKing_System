// This function compute the torque that should be generated by each thruster
// The solution is based on the Least Norm method that compute the smaller 
// solution of a underdetermined linear equation.
// Ba is the thrusters geometric configuration matrix and Controller_Torque 
// is the torque coming from the Controller.
// The Linear equation we are solving is:
// Ba*U = T_c;

function [Torques] = LeastNormTorque(Ba, Controller_Torque)
    
    Torque_Factor = Ba' / (Ba * Ba');
    Torques  = Torque_Factor * Controller_Torque;
    
endfunction
