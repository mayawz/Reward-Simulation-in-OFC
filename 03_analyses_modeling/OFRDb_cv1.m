% OFRDb_cv1

clear all; close all; clc
load('PAS_OFRbig.mat');
load('NNdecoCrossVal.mat');
ktrain=crosVal(1).ktrain;
ktest=crosVal(1).ktest;
%% parameters

saveWtEpo=200:50:1000;
inputNum                     =125;% using 125 cells' FR + 1 bias weight
hiddenNum                    =40;%
outputNum                    =5;
wtConstr                     =1/40;% constraint weight to improve learning
e                            =0.005;% learning rate: smaller is better
epochs                       =1000;
% re-initialize weights for each cross validation
DW1=rand(inputNum,hiddenNum-1)*0.02-0.01;  %weight between input units to hidden units
DW2=rand(hiddenNum,outputNum)*0.02-0.01;  %weight between hidden units to output units

% initialize log likelihood for each cross validation
CV1D.logL=zeros(length(ktrain),epochs);
%%
for i=1:epochs
    
    temp=ktrain(randperm(length(ktrain)));
    for v=1:length(ktrain)
        k=temp(v);
        
        % ######### Offer D #########
        for j=1:5 % 5 offer sizes
            order=randperm(5);
            output_desired=PAS(k).sz(order(j)).tarD;
            input_temp=PAS(k).sz(order(j)).frD;
            
            % ######### first, forward pass #########
            
            h_temp=zeros(1,hiddenNum);
            h_temp(end)=1; % biased weights
            
            for x=1:hiddenNum-1
                h_temp(1,x)=nansum(input_temp.*DW1(:,x)');
                h_temp(1,x)=logistic(h_temp(1,x));
            end
            
            clear x;
            
            %compute output unit
            output_temp=zeros(1,outputNum);
            
            for x=1:outputNum
                output_temp(1,x)=nansum(h_temp.*DW2(:,x)');
            end
            
            output_temp(1,:)=softmax(output_temp(1,:));
            clear x;
            
            if i > 1000
                CV1D.epoc(i).inst(v).sZ(j).OutPut=output_temp;
                CV1D.epoc(i).inst(v).sZ(j).OutTar=output_desired;
            end
            % ######### compute log likelihood #########
            
            tempDLogL(j)=nansum(output_desired.*log(output_temp(1,:)));
            
            % ######### second, back propagation #########
            %compute and update Weight between hidden unit and output
            for x=1:hiddenNum
                for y=1:outputNum
                    delta=0;
                    for z=1:outputNum
                        if z==y
                            delta=delta+output_desired(1,z)/output_temp(1,z)*output_temp(1,z)...
                                *(1-output_temp(1,y))*h_temp(1,x);
                        elseif z~=y
                            delta=delta+output_desired(1,z)/output_temp(1,z)*output_temp(1,z)...
                                *(0-output_temp(1,y))*h_temp(1,x);
                        end
                    end
                    
                    DW2(x,y)=DW2(x,y)+ wtConstr * e * delta;
                    clear delta;
                end
            end
            clear x y z;
            %compute and update Weight between input unit and hidden unit
            for x=1:inputNum
                for y=1:hiddenNum-1
                    delta=0;
                    for z=1:outputNum
                        delta=delta+(output_desired(z)-output_temp(1,z))*DW2(y,z);
                    end
                    delta=delta*h_temp(1,y)*(1-h_temp(1,y))*input_temp(1,x);
                    DW1(x,y)=DW1(x,y)+ wtConstr * e * delta;
                    clear delta;
                end
            end
            clear x y z;
        end % end of OD-size j
        
        
        % ######### save log likelihood #########
        
        CV1D.logL(v,i)=sum(tempDLogL);
        
        clear tempDLogL;
        
        disp('OFRDb_cv1')
        
        disp(['Epoch: ' num2str(i) '  Training instance: '  num2str(v)]);
        
        disp(['D logL = ' num2str(CV1D.logL(v,i))])
        
        
    end % end of training pattern k/v
    
    if ismember(i,saveWtEpo)
        CV1D.midWt(i/50).Wt1=DW1;
        CV1D.midWt(i/50).Wt2=DW2;
    end
    
    
    
end % end of epochs i

CV1D.Wt1=DW1;
CV1D.Wt2=DW2;

save('OFRDb_cv1.mat','CV1D')

%%
plot(mean(CV1D.logL(1:220),1))
