% =================================================================
% This file replicates the beginning of the relevant voteSim file and then 
% outputs list of model implications for the tables
% Same parameters for voters and non-voters
%   Note: this code uses the version of the code written to allow non-selection 
%   parameters to vary across voters/non-voters, but in practice assigns them
%   to be the same
% Allows for a utility of talking about politics
% =================================================================

function [implications]= calc_implications_UTalk(parameters,sim_voters,L_setting,rand_set)

% =================================================================
% Set Parameters
% ================================================================

% =========================================
% =========================================
simSize=sim_voters; 
N=5.4; % Number of times asked in Congressional
N_P=10.1; % times asked in presidential

% Note: using the code that allows for non-selection parameters to vary
%   across voters and non-voters but parameters are forced to be the same

%vary across voters/non-voters
h0_v	=	parameters(1);
h0_nv	=	parameters(1);
r_v	=	parameters(2);
r_nv	=	parameters(2);
eta_v	=	parameters(3);
eta_nv	=	parameters(3);
mu_s_v	=	parameters(4);
mu_s_nv	=	parameters(4);
sigma_s_v	=	parameters(5);
sigma_s_nv	=	parameters(5);
S_svy_v	=	parameters(6);
S_svy_nv	=	parameters(6);
timeval_v	=	parameters(7);
timeval_nv	=	parameters(7);


%Don't vary across voters/non-voters
mu_sv	=	parameters(8);
mu_sn	=	parameters(9);
sigma_sv	=	parameters(10);
sigma_sn	=	parameters(11);
rho	=	parameters(12);

if L_setting == 'cons' 
    L=parameters(13);
end

if L_setting == 'dist' 
    L_lambda=parameters(13);
end

mu_eps = parameters(14);
sigma_eps = parameters(15);

% Include separate utility of talking for voters and non-voters
talking_v = parameters(16);
talking_nv = parameters(17);

% ==========================================================================
% Draw from random variables (distributions of sv, sn, eps)
% transform already set random components
% Determine who are voters and who are not
% =======================================================================

% order of rand_set: s eps sv sn

%%% Simulate epsilons ("other" reasons to vote)
eps = mu_eps + sigma_eps.*rand_set(:,2);

%%% Simulate sv and sn
sv = mu_sv + sigma_sv.*rand_set(:,3);
sn = mu_sn + sigma_sn.*rand_set(:,4);

% If L is a distribution, define values
if L_setting == 'dist' 
    %%% Simulate lying cost
    % This is an expoential distribution 
    L = -log(rand_set(:,5)) / L_lambda;
end

% ==========================================================================
% Vote or Not
% =======================================================================

% Net expected utility of voting (relative to not voting)
sigVal = (max(sv,sn-L) - max(sn,sv-L)); % net sig utility voter - non-voter (1 ask)
sigVal_x_N = N.*sigVal; % asked N times
utilityVoting = sigVal_x_N + eps; % net utility
voted = utilityVoting>0; % Vote if net utility > 0

% return a list of indices (e.g., 1, 3, 4) identifying voters and non-voters
voterIndex = find(voted==1);
nonvoterIndex = find(voted==0);

% share who turn out in the control group (no GOTV intervention)
Turnout_control = mean(voted);  

% Make vectors with voter and non-voter parameters based on 
% whether voted in the control experiment
h0 = voted.*h0_v + (1-voted).*h0_nv;
r = voted.*r_v + (1-voted).*r_nv;
eta = voted.*eta_v + (1-voted).*eta_nv;
S_svy = voted.*S_svy_v + (1-voted).*S_svy_nv;
timeval = voted.*timeval_v + (1-voted).*timeval_nv;


% net utility of voting if seen the GOTV flyer
sigVal_x_N_GOTV = (N+h0).*sigVal;
utilityVoting_GOTV = sigVal_x_N_GOTV + eps; 
voted_GOTV = utilityVoting_GOTV>0; 

% share who turn out with the GOTV intervention
% assume fraction r see the flyer and count as 1 more interaction
Turnout_GOTV = mean(voted_GOTV);

% =================================================================
% Lying if Asked Section - utility from being asked once
% ================================================================

% Utility from being asked includes utility from talking about voting 
% utilVotingQuestion= utility you get from being asked one 
%     time (max of lie or not lie)
wouldLieIfAsked = voted.*(sn-L>sv) + (1-voted).*(sv-L>sn);
utilVotingQuestion = voted.*max(sn-L,sv) + (1-voted).*max(sv-L,sn) ...
    + voted.*talking_v + (1-voted).*talking_nv;

% ================================================================
% GOTV N+1
Turnout_GOTV_Nplus1 = mean((N+1).*sigVal + eps > 0);

% Turnout at different values of N
for i=0:12 
voted_extra_N(i+1) = mean(i*sigVal + eps > 0);
end

%turnout with N and 2*N people asking
Turnout_N = mean(N.*sigVal + eps > 0);
Turnout_2N = mean((2*N).*sigVal + eps > 0);

% turnout with no asking
Turnout_0 = mean(eps > 0);

% ========================================================================
% Output vector
implications = zeros(29,1);
    
    % Ex-post means (voter and then non-voter)
    %epsilon
    implications(1) = mean([eps(voterIndex)]);
    implications(2) = mean([eps(nonvoterIndex)]);
    %s_v
    implications(3) = mean([sv(voterIndex)]);
    implications(4) = mean([sv(nonvoterIndex)]);
    %s_n
    implications(5) = mean([sn(voterIndex)]);
    implications(6) = mean([sn(nonvoterIndex)]);
    
    % Implications for Value of Voting to Tell Others
    %implied value of voting to tell others (v then nv)
    implications(7) = mean([sigVal_x_N(voterIndex)]);
    implications(8) = mean([sigVal_x_N(nonvoterIndex)]);
    % baseline turnout
    implications(9) = Turnout_control;
    % change in turnout if N=0
    implications(10) = (Turnout_0 - Turnout_control);
    % change in turnout if N=2N 
    implications(11) = (Turnout_2N - Turnout_control);
    
    % Implications for GOTV 
    % Assume GOTV is N+1
    % Utility of being asked about voting once (v then nv)
    implications(12) = mean([utilVotingQuestion(voterIndex)]);
    implications(13) = mean([utilVotingQuestion(nonvoterIndex)]);
    % implied GOTV effect on turnout
    implications(14) = (Turnout_GOTV_Nplus1 - Turnout_control);
    % Number of GOTV subjects to get one more vote
    implications(15) = 1/(Turnout_GOTV_Nplus1 - Turnout_control);
    % Utility cost to get one more vote 
    implications(16) = - implications(15)* mean([utilVotingQuestion]);
    
    %Figure 9
    % Implied turnout by number of times asked (N)
    for i=0:12 
    implications(17+i) = voted_extra_N(i+1);
    end

    % Add mean lying cost if L has a distribution
    % (total, voters, non-voters)
    if L_setting == 'dist' 
        implications(30) = mean([L]);
        implications(31) = mean([L(voterIndex)]);
        implications(32) = mean([L(nonvoterIndex)]);
    end
 
end