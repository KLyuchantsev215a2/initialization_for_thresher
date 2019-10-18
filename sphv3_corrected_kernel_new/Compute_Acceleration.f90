subroutine Compute_Acceleration(x,Ci,CN,CN_new,s,acc,PK1,PK1N,F,Fedge,Cauchy,x_init,thichness,tableN,cor_WN,nabla_W_0_1N,nabla_W_0_2N,table,cor_W,nabla_W_0_1,nabla_W_0_2,mu,k,eta,etaN,vol,YieldStress,betar,gammar,betas,gammas,rho_0,dt,N) 
  !input: 
  !     x     position vector
  !     Ci,s  internal varaibles of viscoplastic model
  !     CN    old right Cauchy-Green tensor for Newton fluid. Computed using SPH with h = h_N
  !const: table,x_init,cor_W,nabla_W_0_1,nabla_W_0_2,mu,k,eta,etaN,vol,YieldStress,betar,gammar,betas,gammas,rho_0,dt,N
  !ouputput: 
  !      acc   acceleration vector
  !   CN_new   current right Cauchy-Green tensor for Newton fluid. Computed using SPH with h = h_N
    
    IMPLICIT NONE
    integer :: N,i,j,alpha,flag
    real*8 :: dt
    real*8 :: mu
    real*8 :: k
    real*8 :: eta
    real*8 :: etaN
    real*8 :: YieldStress(N)
    real*8 :: vol
    real*8 :: betar
    real*8 :: gammar
    real*8 :: betas
    real*8 :: gammas
    real*8 :: rho_0
    real*8 :: s(N)
    real*8 :: Fedge(2)!edge Force=reaction force
    real*8 :: s_new(N)
    real*8 :: F(3,3,N)
    real*8 :: FN(3,3,N)
    real*8 :: Ci(3,3,N)
    real*8 :: CN(3,3,N)
    real*8 :: CN_New(3,3,N)
    real*8 :: thichness(N)
    real*8 :: Cauchy(3,3,N)
    real*8 :: PK1(3,3,N)
    real*8 :: PK1N(3,3,N)
    real*8 :: x(2,N)
    real*8 :: x_init(2,N)
    real*8 :: cor_W(N)
    real*8 :: nabla_W_0_1(N,N)
    real*8 :: nabla_W_0_2(N,N)
    real*8 :: cor_WN(N)
    real*8 :: nabla_W_0_1N(N,N)
    real*8 :: nabla_W_0_2N(N,N)
    real*8 :: acc(2,N)
    integer :: table(N,120)
    integer :: tableN(N,120)
    flag=1
    
    call Compute_F(x,x_init,thichness,F,vol,cor_W,nabla_W_0_1,nabla_W_0_2,N,table)
    
    call Compute_F(x,x_init,thichness,FN,vol,cor_WN,nabla_W_0_1N,nabla_W_0_2N,N,tableN)
    
    call  OneStepPlasticity(F,s,Ci,thichness,Cauchy,PK1,mu,k,eta,dt,YieldStress,gammar,betar,gammas,betas,N,flag)   
    
    call  Compute_Newton_Fluid(FN,CN,CN_new,PK1N,N,dt,etaN)
    Fedge=0.0d0
    acc=0.0d0
    
    do i=1,N
        do j=1,table(i,1)
                do alpha=1,2  
                    acc(alpha,i)=acc(alpha,i)-vol*(PK1(alpha,1,table(i,j+1)))*nabla_W_0_1(table(i,j+1),i)
                    acc(alpha,i)=acc(alpha,i)-vol*(PK1(alpha,2,table(i,j+1)))*nabla_W_0_2(table(i,j+1),i)
                enddo
        enddo
        
     do j=1,tableN(i,1)
                do alpha=1,2  
                    acc(alpha,i)=acc(alpha,i)-vol*(PK1N(alpha,1,table(i,j+1)))*nabla_W_0_1N(tableN(i,j+1),i)
                    acc(alpha,i)=acc(alpha,i)-vol*(PK1N(alpha,2,table(i,j+1)))*nabla_W_0_2N(tableN(i,j+1),i)
                enddo
        enddo
        
     !    if(x_init(2,i)>=1.44d0) then
       !             do alpha=1,2
       !             Fedge(alpha)=Fedge(alpha)-acc(alpha,i)*vol
      !              enddo
      !  endif
        
        do alpha=1,2
            acc(alpha,i)=acc(alpha,i)/rho_0
        enddo
    enddo
    return
end