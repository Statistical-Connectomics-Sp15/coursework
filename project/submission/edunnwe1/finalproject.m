%% Original graph
load('mouse_visual.cortex_1-2.mat');
A = full(graph); %adjacency matrix
[X,Y] = find(A);
XY = [X Y]; %coordinates

%plot
% figure;gplot(A,XY,'black-o');
%% Redefine the graph
%first, disregard the nodes that are not fully characterized excitatory or inhibitory neurons
%and their associated edges
%these are nodes 2, 24, 25
blanks = [2 24 25];

ix = zeros(29,1);
ix(blanks) = 1;
ix = logical(ix);
A(:,ix) = 0;
A(ix,:) = 0;

[X,Y] = find(A);
XY = [X Y];
graph1 = sparse(A);

%create a new graph where the nodes are excitatory neurons. 
%attributes are the orientation preference of the neuron
%edges are whether the neuron share an inhibitory target

%the excitatory neurons are nodes 3-13. all else are inhibitory.
ex = (3:13);
inhib = find(~ismember((1:29),ex) & ~ismember((1:29),blanks));

%first, only consider connections between excitatory neurons and inhibitory
%neurons
IX = ~(ismember(XY(:,1),ex)& ismember(XY(:,2),ex));
XY1 = XY(IX,:);

%next, determine convergent input to a given inhibitory neuron.
inhib2 = XY1(ismember(XY1(:,2),inhib),2);
inhib1 = XY1(ismember(XY1(:,1),inhib),1);

[a b] = hist(inhib2,unique(inhib2));
[a1 b1] = hist(inhib1,unique(inhib1));

b = b(a > 1);
b1 = b1(a1 > 1);

A_new = zeros(13,13);
for i = 1:length(b)
   ix = XY1(:,2)==b(i);
   A_new(XY1(ix,1),XY1(ix,1)) = 1;
end

for i = 1:length(b1)
   ix = XY1(:,1)==b1(i);
   A_new(XY1(ix,2),XY1(ix,2)) = 1;
end

%do not permit self-loops
A_new(eye(size(A_new))~=0)=0;
[X, Y] = find(A_new);
XY_new = [X Y];


%% Set attributes (preferred orientation)
%set node attributes
attr = [180;180;180;45;135;180;112.5;90;180;135;112.5];
attr = [ex' attr];
clusters = unique(attr(:,2));
XY_clus = zeros(size(XY_new));

%set edge attributes (within or outside cluster)
for i = 1:length(clusters);
    ix = attr(attr(:,2)==clusters(i),1);
    XY_clus(ismember(XY_new,ix)) = clusters(i);
end
%%
% borrowed/adapted from jw hw5 code as a good way to visualize graphs
k = length(clusters);
VIS_SIG = (1.1^k)*(1/k);
e = 2*pi/k;
xy_seed = linspace(0+e,2*pi,k)';
xy = [];
cc = hsv(k);
h1 = figure;
hold all
for i = 1:k
    n_k = sum(attr(:,2)==clusters(i));
    s = xy_seed(i);
    [index, ~] = find(attr(:,2)==clusters(i));
    for j = 1:n_k
        i_j = index(j);
        xy(i_j,1) = cos(s)+normrnd(0,VIS_SIG);
        xy(i_j,2) = sin(s)+normrnd(0,VIS_SIG);
        plot(xy(i_j,1),xy(i_j,2),'.','color',cc(i,:),'MarkerSize',25)
    end
end
gplot(A_new(3:13,3:13),xy,'black-o')
title('redefined graph such that nodes are excitatory neurons including their dependencies')
print(h1,'-dpng','redefinedGraph')

%gplot(A_new,XY_new,'black-o');
%% Estimate p and q
same_diff = XY_clus(:,1) - XY_clus(:,2);
same_diff(same_diff ~=0) =1;
p = length(find(same_diff==0))/length(same_diff);
q = length(find(same_diff))/length(same_diff);
%% Test statistic: p-q
H_a = p-q
save('H_a.mat','H_a')
%% Permutation test
H_0 = zeros(1,10000);
for i = 1:10000;
    permute = randperm(length(A_new(:,1)));
    A_permu = triu(A_new(permute,:),1);
    A_perm = A_permu + tril(A_permu',-1);
    
    [X, Y] = find(A_perm);
    XY_perm = [X Y];
    
    XY_clus = zeros(size(XY_perm));
    %set edge attributes (within or outside cluster)
    for j = 1:length(clusters);
        ix = attr(attr(:,2)==clusters(j),1);
        XY_clus(ismember(XY_perm,ix)) = clusters(j);
    end
    
    same_diff = XY_clus(:,1) - XY_clus(:,2);
    same_diff(same_diff ~=0) =1;
    p = length(find(same_diff==0))/length(same_diff);
    q = length(find(same_diff))/length(same_diff);
    H_0(i) = p-q;
end
p_val = sum(H_0 <= H_a)/length(H_0) %less then because to be more less than is to be more extreme
save('p_val.mat','p_val')
%% Generalized likelihood test
%% Power analysis
