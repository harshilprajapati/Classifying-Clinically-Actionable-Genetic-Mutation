%% RBF Choosing best box constant and sigma
% MATLAB R2017b
% Bowen Song U04079758

%% preprocessing
function function_rbf_OVO(X_train_woSTOP,X_test_woSTOP,Y_train,Y_test,vocab,boxcon,rbf_sig,filename)
rmpath('libsvm-3.22/matlab');
X_train_processed = Norm_preprocessing(X_train_woSTOP,length(vocab));
disp("Preprocessing is done:")

%% Finding Best sigma and Box constant
classNames = unique(Y_train);
numClasses = length(classNames);
tot_iter = numClasses*(numClasses-1)/2;
inds = cell(tot_iter,1); % Preallocation
SVMModel = cell(tot_iter,1);
pair_i = [];
pair_j = [];
for i = 1:numClasses-1
    for j = i+1:numClasses
        pair_i = [pair_i ; i];
        pair_j = [pair_j ; j];
    end
end


svm_ccr = zeros(length(boxcon),length(rbf_sig),5);

for t_i = 1:tot_iter
    [X_train_1_2, Y_train_1_2] ...
        = ovo(pair_i(t_i),pair_j(t_i),X_train_processed,Y_train);
    for k = 1:length(rbf_sig)
        for j = 1:length(boxcon)
            kfold = cvpartition(length(Y_train_1_2),'KFold',5);
            for i = 1:5
                %             svms = svmtrain(X_train_1_2(training(kfold,i),:),Y_train_1_2(training(kfold,i),:),...
                %                 'boxconstraint',boxcon(j)*ones(kfold.TrainSize(i),1),...
                %                 'autoscale','false','kernel_function','linear');
                %             svm_ccr(j,i) = mean(svmclassify(svms,X_train_1_2(test(kfold,i),:))...
                %                 ==Y_train_1_2(test(kfold,i),:));
                svms = svmtrain(Y_train_1_2(training(kfold,i),:),X_train_1_2(training(kfold,i),:),...
                    sprintf('-c %f -t 2 -m inf -h 0 -g %f',boxcon(j),rbf_sig(k)));
                svm_ccr(j,k,i) = mean(Y_train_1_2(test(kfold,i),:)==...
                    svmpredict(Y_train_1_2(test(kfold,i),:),X_train_1_2(test(kfold,i),:),svms,''));
            end
        end
    end
    fprintf('class %d out of %d is done',t_i,tot_iter);
    cv_ccr = mean(svm_ccr,3);
    %% Selecting Best sigma and Box constant
    [boxcon_star_perf(t_i),boxcon_star_ind] = max(max(cv_ccr,[],2));
    [rbf_sig_star_perf(t_i),rbf_sig_star_ind] = max(max(cv_ccr));
    boxcon_star(t_i) = boxcon(boxcon_star_ind);
    rbf_sig_star(t_i) = rbf_sig(rbf_sig_star_ind);
end
%% actual Training with Star sigma and boxconstant
traintic = tic;

warning('off','all')
warning
svms = cell(tot_iter,1);
parfor j = 1:tot_iter
    [X_train_1_2, Y_train_1_2] ...
        = ovo(pair_i(j),pair_j(j),X_train_processed,Y_train);
    %     svms{j} = svmtrain(X_train_1_2,Y_train_1_2,'boxconstraint',boxcon_star(j),...
    %         'autoscale','false','kernel_function','Linear');
    svms{j} = svmtrain(Y_train_1_2,X_train_1_2,sprintf('-c %f -t 2 -g %f -m inf -h 0',boxcon_star(j),rbf_sig_star(j)));
    
end
traintime = toc(traintic);

X_test = Norm_preprocessing(X_test_woSTOP,length(vocab));

testtic = tic;
prediction_prob = zeros(length(Y_test),length(svms));
parfor i = 1:length(svms)
    %     prediction(:,i) = svmclassify(svms{i},X_test);
    [~,~,p] = svmpredict(Y_test, X_test, svms{i}, '-b 1');
    prediction_prob(:,i) = p(:,svms{i}.Label==1);    %# probability of class==k
end

prediction = mode(prediction_prob,2);
ccr = mean(prediction==Y_test);

testtime = toc(testtic);
disp('Linear_kfold')
display(ccr)
display(traintime)
display(testtime)
PreXtruth = confusionmat(prediction,Y_test);
% display(boxcon_star_perf)
% PreXtruth = confusionmat(prediction,Y_test);
% display(PreXtruth);
save(sprintf('%s.mat',filename))
rmpath('libsvm-3.22/matlab');
end

