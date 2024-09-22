% Eb_cv1

clear all; close all; clc
load('PAS_RWDbig.mat');
load('NNdecoCrossVal.mat');
ktrain=crosVal(1).ktrain;
ktest=crosVal(1).ktest;
%% parameters

saveWtEpo=200:50:1500;
inputNum                     =125;% using 125 cells' FR
hiddenNum                    =40;%
outputNum                    =5;
wtConstr                     =1/40;% constraint weight to improve learning
e                            =0.005;% learning rate: smaller is better
epochs                       =1500;
% re-initialize weights for each cross validation
EW1=rand(inputNum,hiddenNum-1)*0.02-0.01;  %weight between input units to hidden units
EW2=rand(hiddenNum,outputNum)*0.02-0.01;  %weight between hidden units to output units

% initialize log likelihood for each cross validation
CV1E.logL=zeros(length(ktrain),epochs);
%%
for i=1:epochs
    
    temp=ktrain(randperm(length(ktrain)));
    for v=1:length(ktrain)
        k=temp(v);
        
        
        % ######### offer E #########
        for j=1:5 % 5 offer sizes
            order=randperm(5);
            output_desired=PAS(k).sz(order(j)).tarE;
            input_temp=PAS(k).sz(order(j)).frE;
            % ######### first, forward pass #########
            
            h_temp=zeros(1,hiddenNum);
            h_temp(end)=1; % biased weights
            
            for x=1:hiddenNum-1
                h_temp(1,x)=nansum(input_temp.*EW1(:,x)');
                h_temp(1,x)=logistic(h_temp(1,x));
            end
            
            clear x;
            
            %compute output unit
            output_temp=zeros(1,outputNum);
            
            for x=1:outputNum
                output_temp(1,x)=nansum(h_temp.*EW2(:,x)');
            end
            
            output_temp(1,:)=softmax(output_temp(1,:));
            clear x;
            
            if i > 1000
                CV1E.epoc(i).inst(v).sZ(j).OutPut=output_temp;
                CV1E.epoc(i).inst(v).sZ(j).OutTar=output_desired;
            end
            
            % ######### compute log likelihood #########
            
            tempELogL(j)=nansum(output_desired.*log(output_temp(1,:)));
            
            
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
                    
                    EW2(x,y)=EW2(x,y)+ wtConstr * e * delta;
                    clear delta;
                end
            end
            clear x y z;
            %compute and update Weight between input unit and hidden unit
            for x=1:inputNum
                for y=1:hiddenNum-1
                    delta=0;
                    for z=1:outputNum
                        delta=delta+(output_desired(z)-output_temp(1,z))*EW2(y,z);
                    end
                    delta=delta*h_temp(1,y)*(1-h_temp(1,y))*input_temp(1,x);
                    EW1(x,y)=EW1(x,y)+ wtConstr * e * delta;
                    clear delta;
                end
            end
            clear x y z;
        end % end of OE-size j
        
        % ######### save log likelihood #########
                
        CV1E.logL(v,i)=nansum(tempELogL);

        clear tempELogL;
        
        disp('Eb_cv1')
        
        disp(['Epoch: ' num2str(i) '  Training instance: '  num2str(v)]);
                
        disp(['E logL = '  num2str(CV1E.logL(v,i))])
        
        
        
    end % end of training pattern k/v
    
    if ismember(i,saveWtEpo)
        CV1E.midWt(i/50).Wt1=EW1;
        CV1E.midWt(i/50).Wt2=EW2;
    end
    
end % end of epochs i

CV1E.Wt1=EW1;
CV1E.Wt2=EW2;

save('Eb_cv1.mat','CV1E')

%%
plot(mean(CV1E.logL(1:220),1))





