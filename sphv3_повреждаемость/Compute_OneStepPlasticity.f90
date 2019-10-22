subroutine OneStepPlasticity(F,s,Ci,thichness,Cauchy,PK1,mu0,k0,eta,mu,k,gammar,phi_n,phi_g,dt,YieldStress,YieldStress0,gammar0,betar,N,flag) 
!input F,Ci, s              
!output PK1
USE matrix

integer:: N,i,flag
real*8 :: F(3,3,N)
real*8 :: Cauchy(3,3,N)
real*8 :: Ci(3,3,N)
real*8 :: s(N)
real*8 :: thichness(N)
real*8 :: mu0
real*8 :: k0
real*8 :: phi_n(N)
real*8 :: phi_g(N)
real*8 :: phi(N)
real*8 :: dt
real*8 :: li

real*8 :: eta
real*8 :: YieldStress(N)
real*8 :: YieldStress0(N)
real*8 :: mu(N)
real*8 :: k(N)

real*8 :: gammar(N)
real*8 :: R
real*8 :: betar
real*8 :: gammar0

real*8 :: DrivingForce
real*8 :: MandellStress(3,3)
real*8 :: DrivingForce_tmp_dev(3,3)
real*8 :: DrivingForce_tmp_sqr(3,3)
real*8 :: PK1(3,3,N)
real*8 :: PK13x3(3,3)
real*8 :: PK1_trans_tmp(3,3)
    
real*8:: detFp
real*8 ::Fp(3,3)
real*8 :: invFp(3,3)
real*8 :: transinvFp(3,3)
real*8 :: trans_Fp(3,3)
    
real*8 ::Cp(3,3)
real*8 ::invCp(3,3)
real*8 ::Ci3x3(3,3)
    
real*8 :: Cip(3,3)
real*8 :: invCip(3,3)
real*8 :: multCCi(3,3)
real*8 :: sp,BRR,SRR,IRR,A_phi,dgrowth
real*8 :: C_iso(3,3)
real*8 :: dev_C_iso(3,3)
real*8 :: Stress2PK(3,3)
real*8:: devmultCCi(3,3)
real*8:: Kirchhoff(3,3)
real*8:: Kirchhoff1(3,3)
    BRR=50.0d0
    SRR=50.0d0
    IRR=40.0d0
    A_phi=0.05d0
    dgrowth =5.0d0

Couchy=0.0d0
PK1=0.0d0
    
do i=1,N
    Ci3x3=0.0d0
    Cp=0.0d0
    Kirchhoff=0.0d0
    Fp=0.0d0
    Fp(1:3,1:3)=F(1:3,1:3,i)
        
    detFp=(Fp(1,1)*Fp(2,2)-Fp(1,2)*Fp(2,1))*Fp(3,3)
        
    call trans(Fp,trans_Fp)
    call mymulty(trans_Fp,Fp,Cp)    ! now C = F' F
            
    C_iso=detFp**(-2.0/3.0)*Cp   ! isochoric part of current C
    Ci3x3(1:2,1:2)=Ci(1:2,1:2,i)     ! take old C_i
    Ci3x3(3,3)=1.0/(Ci(1,1,i)*Ci(2,2,i)-Ci(1,2,i)*Ci(2,1,i))
    Cip=Ci3x3;   ! C_i from the previous time step at the current point
        
    sp=s(i);

    call inv_matrix(Cp,invCp)
    call inv_matrix(Cip,invCip)            ! invCip = (old C_i)^(-1)
    call mymulty(C_iso,invCip,multCCi)    ! multCCi = C_iso * (old C_i)^(-1)
    call dev(multCCi,devmultCCi)
    call mymulty(mu(i)*invCp,devmultCCi,Stress2PK)   ! Stress2PK = trial 2nd PK
    call mymulty(Cp,Stress2PK,MandellStress)  ! MandellStress  =  C T^tilde
    call dev(MandellStress,DrivingForce_tmp_dev)    ! DrivingForce_tmp_dev = dev(C T^tilde)
    call mymulty(DrivingForce_tmp_dev,DrivingForce_tmp_dev,DrivingForce_tmp_sqr)   ! DrivingForce_tmp_sqr = (dev(C T^tilde))^2
       
    DrivingForce=sqrt((DrivingForce_tmp_sqr(1,1)+DrivingForce_tmp_sqr(2,2)+DrivingForce_tmp_sqr(3,3)))                             ! DrivingForce = sqrt(trace(  (  dev(C T^tilde)  )^2  ))
    R=gammar(i)/betar*(1.0d0-exp(-betar*sp))  ! trial isotropic hardening
    li=(DrivingForce-sqrt(2.0d0/3.0d0)*(YieldStress(i)+R))/eta
    if (li<0) then
        li=0
    end if                     ! Maccauley bracket
    ! update Ci
    if(li==0) then
        Ci3x3 = Ci3x3
        s(i)=sp
        Ci(1:3,1:3,i) = Ci3x3(1:3,1:3)

    else
    if(flag==1) then
        Ci3x3 = Ci3x3 + ((2.0d0*dt*mu(i)*li)/DrivingForce)*C_iso
        detCi3x3=(Ci3x3(1,1)*Ci3x3(2,2)-Ci3x3(1,2)*Ci3x3(2,1))*Ci3x3(3,3)
        Ci3x3 = (detCi3x3**(-1.0d0/3.0d0))*Ci3x3   ! C_i for the current time step
        Ci(1:3,1:3,i) = Ci3x3(1:3,1:3) !update
        s(i) = sp+ sqrt(2.0d0/3.0d0)*li*dt!update
        phi(i)=phi_g(i)+ phi_n(i)
        phi_g(i)=phi_g(i)+li*dgrowth*phi(i)*dt*exp(sqrt(3.0/2.0)*(MandellStress(1,1)+MandellStress(2,2)+MandellStress(3,3))/DrivingForce)*phi(i)
        phi_n(i)=phi_g(i)+dt*A_phi*li
        mu(i)=mu0*exp(-SRR*(phi(i)))
       k(i)=k0*exp(-BRR*(phi(i)))
        YieldStress(i)=YieldStress0(i)*exp(-IRR*(phi(i)))
        gammar(i)=gammar0*exp(-IRR*(phi(i)))
        end if
    end if

   
    
    Cp=0.0d0
    Kirchhoff=0.0d0
    Fp=0.0d0
        
    Fp(1:3,1:3)=F(1:3,1:3,i)
   
    detFp=(Fp(1,1)*Fp(2,2)-Fp(1,2)*Fp(2,1))*Fp(3,3)
    call trans(Fp,trans_Fp)
    call mymulty(trans_Fp,Fp,Cp)    ! now C = F' F
    Cip=Ci3x3;   ! C_i from the current time step at the current point
    call inv_matrix(Cip,invCip)            ! invCip = (new C_i)^(-1)
    call mymulty(C_iso,invCip,multCCi)    ! multCCi = C_iso * (new C_i)^(-1)
    call dev(multCCi,devmultCCi)
    call mymulty(mu(i)*invCp,devmultCCi,Stress2PK)   ! Stress2PK = current 2nd PK
    call mymulty(Stress2PK,trans_Fp,Kirchhoff1)
    call mymulty(Fp,Kirchhoff1,Kirchhoff)   ! now Kirchhoff is current Kirchhoff
        
    do alpha=1,3
        Kirchhoff(alpha,alpha)=Kirchhoff(alpha,alpha)+k(i)/10.0*(detFp**5-detFp**(-5))   ! Kirchhoff
    enddo
    
    call inv_matrix(Fp,invFp)
    call trans(invFp,transinvFp)
    
    
    call mymulty(Kirchhoff,transinvFp,PK13x3)
        
    PK1(1:3,1:3,i)=PK13x3(1:3,1:3)
   !PK1_trans_tmp(1:3,1:3)=PK1(1:3,1:3,i)   ! this way it works better :-)
         
   !do alpha=1,3
    !   do bbeta=1,3
      !    PK1(alpha,bbeta,i)=PK1(alpha,bbeta,i) 
     !   enddo
    !enddo
    
    Cauchy(1:3,1:3,i)=Kirchhoff(1:3,1:3)/detFp  

enddo 
      
return

end