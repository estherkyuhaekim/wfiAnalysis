function plotActivityVsContrast_beh_NA(type, Animal, expID)
%% load analyzed individual session's dataset and compile them
%input = type = 'miss', 'hit', 'FA', 'CR' or 'LL', character vector
% Animal = 'M230130_2', character vector
% expID = {'26-Feb-2023_3', '27-Feb-2023'}; only need to put in the last date, cell array
% EK 23
% NA 5/30/23 - change to type input

addpath(genpath('Y:\haider\Data\analyzedData\EKK\WFI\Codes\Analysis_EK'))
addpath(genpath("Y:\haider\Code\behaviorAnalysis"));
fPath = 'Y:\haider\Data\analyzedData\EKK\WFI';
prev_path = [fPath filesep Animal filesep 'behavior'];
list = cd(prev_path);
list = ls(list);
gratings = 2; % 0 if barmapping, 1 if passive grating, 2 if active (behavior)
nrLocs = 2; % 2 for gratings (binoc/monoc)
%% compile data

explist = []; %list of all dates for the animal (not just new ones given as input)
for i = 1:height(list)
    if double(list(i,1)) >= 48 && double(list(i,1) <=57) %makes sure it's only the dates
        explist = [explist; {list(i,:)}];
    end
end

try %load previously compiled data or add on new dates if necessary
    load([prev_path '\' expID{end} '\compiled analyzed data.mat'])
    comp = analyzed_comp;
    newExpNr = height(comp);

    nrSessions = zeros(height(analyzed_comp),1);
    for exp = 1: height(analyzed_comp)
        
        for sessNr = 1:width(analyzed_comp)
            if ~isempty(analyzed_comp(exp, sessNr).whole)
                nrSessions(exp) = nrSessions(exp) + 1;
            end
        end
    end
catch
    [comp, nrSess, newExpNr] = compileAnalyzedData_NA (fPath, Animal, expID, gratings);
end

for exp = 1:size(comp,1)
    for s = 1: size(comp,2)
        if ~isempty(comp(exp,s).whole)
            cont(exp) = length(comp(exp,s).whole.contrasts)/2; % assumes monoc cont nr = binoc cont nr in a session
            idx = find(comp(exp,s).whole.contrasts == 0, 1, 'last');
            bcontrasts{exp,s} = comp(exp,s).whole.contrasts(1:idx-1);
            mcontrasts{exp,s} = comp(exp,s).whole.contrasts(idx:end);
        end
    end
end
b_nrcont = cellfun(@(x) max(length(x)), bcontrasts);
m_nrcont = cellfun(@(x) max(length(x)), mcontrasts);

%%
temp = cell(1,nrLocs); % exp x location
temp_gr = cell(height(comp),nrLocs); % exp x location
data = cell(size(comp,1),nrLocs); % exp x location
for exp = 1: size(comp,1) % experiments
    %%
    for s = 1: size(comp,2)% sessions

        if gratings == 2 % sort binoc and monoc to cell
            if ~isempty(comp(exp,s).(type))
                if b_nrcont(exp,s) ~= max(max(b_nrcont)) % fill NAN for full contrast case
                    idxb = unique(cell2mat(bcontrasts(max(max(b_nrcont))== b_nrcont)))';
                    idxb1 = unique(cell2mat(bcontrasts(min(b_nrcont(b_nrcont>0))== b_nrcont)));
                    idx = ismember(idxb, idxb1);
                    comp(exp,s).(type).avgTempTrace.binoc(b_nrcont(exp,s)+1: max(max(b_nrcont)), :) = NaN;
                    comp(exp,s).(type).avgTempTrace.binoc(idx, :) = comp(exp, s).(type).avgTempTrace.binoc(1:b_nrcont(exp,s),:);
                    comp(exp,s).(type).avgTempTrace.binoc(idx==0, :) = NaN;
                end
                if m_nrcont(exp,s) ~= max(max(m_nrcont)) % fill NAN for full contrast case
                    idxm = unique(cell2mat(mcontrasts(max(max(m_nrcont))== m_nrcont)))';
                    idxm1 = unique(cell2mat(mcontrasts(min(m_nrcont(m_nrcont>0))== m_nrcont)));
                    idx = ismember(idxb, idxb1);
                    comp(exp,s).(type).avgTempTrace.monoc(m_nrcont(exp,s)+1: max(max(m_nrcont)), :) = NaN;
                    comp(exp,s).(type).avgTempTrace.monoc(idx, :) = comp(exp, s).(type).avgTempTrace.monoc(1:m_nrcont(exp,s),:);
                    comp(exp,s).(type).avgTempTrace.monoc(idx==0, :) = NaN;
                end
                %3d cell array; cont x timpoints x session; cell size: exp x location
                if ~isempty(comp(exp,s).(type))
                    temp_gr{exp,1} = cat(3, temp_gr{exp,1}, comp(exp,s).(type).avgTempTrace.binoc); % concatenate across sessions
                    temp_gr{exp,2} = cat(3, temp_gr{exp,2}, comp(exp,s).(type).avgTempTrace.monoc);
                end
            end
        end
    end
end
temp = temp_gr;

%% mean df/f vs contrast across sessions

avg_sessions = cellfun(@(x) nanmean(x, 3), temp, 'UniformOutput', false);
std_sessions =  cellfun(@(x) nanstd(x, 0, 3), temp, 'UniformOutput', false);

%%

%[mean, std] = getAvgTraceAcrossStimLocs(avg_animal, contrasts, fr, plot);

nrContrasts = [max(max(b_nrcont)) max(max(m_nrcont))];
for exp = 1: size(avg_sessions,1)
    for j = 1: size(avg_sessions, 2) % locations
        for i = 1:nrContrasts(j)
            [peak_value{exp}(i,j), peak_index] = getPeakPostStim(avg_sessions{exp,j}(i,:), 15, 1, 2);
            std_sessions_peak{exp}(i,j) = std_sessions{exp,j}(i, peak_index);
        end
    end
end

dir = [fPath filesep Animal filesep 'behavior'];
i = 1;
for exp = 1: newExpNr%:length(avg_sessions)
    f = plotDffVsContrast (idxb, idxm, peak_value{exp}, std_sessions_peak{exp}, explist{i,:});
    cd([dir filesep explist{i,:}])
    savefig(f, 'meandff_over_contrasts_sessions.fig')
    saveas(f, 'meandff_over_contrasts_sessions.png')
    i = i+1;
end


%% across days

avg_exp = cell(1,size(avg_sessions,2));
for exp =1: size(avg_sessions,1)
    for i = 1: size(avg_sessions,2) % locations
        avg_exp{1,i} = cat(3, avg_exp{1,i}, temp{exp,i}); % concatenate over sessions
    end
end

avg_days = cellfun(@(x) nanmean(x, 3), avg_exp, 'UniformOutput', false);
std_days =  cellfun(@(x) nanstd(x, 0, 3), avg_exp, 'UniformOutput', false);

for j = 1: size(avg_days, 2) % locations
    for i = 1:nrContrasts(j)
        [peak_value_days(i,j), peak_index] = getPeakPostStim(avg_days{j}(i,:), 15, 1, 2);
        std_days_peak(i,j) = std_days{j}(i, peak_index);
        % sem_days(i,j) = std_days{j}(i, peak_index)/sqrt(length(std_days{j}(i, peak_index)));
    end
end

dir = [fPath filesep Animal filesep 'behavior'];
plotDffVsContrast (idxb, idxm, peak_value_days, std_days_peak, []);
sgtitle(['Average Response Activity Across Days - ' Animal]);
cd([dir])
savefig(gcf, 'meandff_over_contrasts_days.fig')
saveas(gcf, 'meandff_over_contrasts_days.png')

% yLim = [min(min(peak_value_days))-max(max(std_days_peak)) max(max(peak_value_days))+max(max(std_days_peak))]; % Define the y-axis limit
% ax = findobj(f,'type','axes'); % Find all axes handles in the figure
% set(ax,'ylim',yLim);
if exist(['compiled ROI traces_days_' type '.mat'])
    prev = load(['compiled ROI traces_days_' type '.mat'], 'expID');
    expID = [prev.expID expID];
end
save(['compiled ROI traces_days_' type '.mat'], 'avg_exp', 'avg_days', 'std_days', 'expID', 'idxm', 'idxb')
end
