%% %% SVM Classifier for Text Document News 20 group
% MATLAB R2017b
% Bowen Song U04079758
% OVO
clear
close all
addpath('libsvm-3.22/matlab');
%% preprocessing
tic
Preprocessing_new20;
disp("Preprocessing is done:")
toc
X_train_woSTOP = X_train_woSTOP(ismember(Y_train_expand,[1,20]),:);
X_test_woSTOP = X_test_woSTOP(ismember(Y_test_expand,[1,20]),:);
Y_train = Y_train(ismember(Y_train,[1,20]));
Y_test = Y_test(ismember(Y_test,[1,20]));
Y_train(Y_train==20) =2;
Y_test(Y_test==20) =2;
%% use data with filtered stoped words
% preprocess Further with stop wrods technique

%% Training with OVO
tuning = 150; % tuning prarmeter for US new is suggested to be 150 at best

disp("X_train preperation time:")
% global alphaCust
global SA_n
tic
[X_train_processed,SA_n] = SA1_preprocessing(X_train_woSTOP,tuning,...
    length(vocab));
%X_train_processed = full(Norm_preprocessing(X_train_woSTOP,length(vocab)));
toc
classNames = unique(Y_train);
numClasses = length(classNames);
tot_iter = numClasses*(numClasses-1)/2;
inds = cell(tot_iter,1); % Preallocation
SVMModel = cell(tot_iter,1);
rng(1); % For reproducibility
pair_i = [];
pair_j = [];
for i = 1:numClasses-1
    for j = i+1:numClasses
        pair_i = [pair_i ; i];
        pair_j = [pair_j ; j];
    end
end
disp("Training time:")
traintic = tic;
for j = 1:tot_iter % parfor in the end
    tic
    [X_train_1_2, Y_train_1_2] ...
        = ovo(pair_i(j),pair_j(j),X_train_processed,Y_train);
    X_train_prime_1_2 = ~(X_train_1_2);
    K =  [ (1:size(X_train_1_2,1))' , sensing1kernal(X_train_1_2,X_train_prime_1_2) ];
%     SVMModel{j} = fitcsvm(X_train_1_2,Y_train_1_2,...
%         'KernelFunction','sensing2kernal');
    SVMModel{j} = svmtrain(Y_train_1_2,K,'-t 4');
    fprintf("predicting %d pair",j);
    toc
end
trainTime = toc(traintic);
%% Testing with star_tuning OVO
star_tuning = 1; % should be set to the best cv-CCR
[X_test_processed,SA_n] = SA1_preprocessing(X_test_woSTOP,tuning(star_tuning),length(vocab));
% X_test_processed = full(Norm_preprocessing(X_test_woSTOP,length(vocab)));
X_test_prime_processed = ~(X_test_processed);
disp("Testing time:")
n = size(X_test_processed,1);
decision = zeros(n,tot_iter);
tic
     KK =  [ (1:size(X_test_processed,1))' , sensing1kernal(X_test_processed,X_test_prime_processed) ];

for j = 1:tot_iter

    decision(:,j) = svmpredict(Y_test,KK,SVMModel{j}, '');
%     decision(:,j) = predict(SVMModel{j},X_test_processed);
    fprintf("predicting %d pair",j);

end
finaldecision = mode(decision,2);

testTime = toc;

disp("2 classes SASVM_OVO is done:")
OVOccr = mean(finaldecision==Y_test);
display(trainTime)
display(OVOccr)
display(testTime)
save('SASVM_OVO_fitc_2class.mat')
rmpath('libsvm-3.22/matlab');
