%This code generates instances of the figure types used in the project.

hold on
generic_time_vec = 1/(60*6)*[1:1:size(Ysmooth)];
goldTimes = generic_time_vec(find(TestLabels{index(i)}));
guessTimes = generic_time_vec(find(Ysmooth));
scatter(goldTimes,zeros([1,length(goldTimes)]),300+zeros([1,length(goldTimes)]),'filled','square')
scatter(guessTimes,zeros([1,length(guessTimes)]),'filled','square')
ylim([-0.05 0.05])
set(gca,'YTickLabel','')
xlabel('ICU Time (hours)')
legend('Ground Truth Seizures','Data Reduction System Attention')
title('Data Reduction System Highlights in a Single Patient')

hold on
x = [1:1:7];
y = [0.6392, 0.3064, 0.2296, 0.0438, 0.0044, 0.0987, 0.1026];
y2 = [1, 0.6468, 0.5079, 0.2798, 0.0159, 0.6825, 0.6865];
y3 = [0.0916, 0.1236, 0.1296, 0.374, 0.2105, 0.4052, 0.3918];
plot(x,(1-y)*100,'b', x, y2*100,'r', x, y3*100,'k')
legend('Data Removed (Percentage)','Window Based Recall (Percentage)', 'Precision (Percentage)','Location','SouthEast')
ylabel('Quantity')
xlabel('Number of Patient Clusters Used')
title('Data Reduction as a Function of Number of Clusters Used')

hold on
y = [0.0728, 0.1378, 0.8867, 0.2801, 0.4468, 0.7679, 0.7684, 0.3485, 0.734, 0.3616, 0.5159, 0.7671, 0.7563];
x = [0.4861, 0.3452, 1, 0.6596, 0.7111, 1, 0.9317, 0.6367, 0.9652, 0.5773, 0.8, 1, 1];
scatter(x*100,(1-y)*100,[90], 'filled')
ylabel('Data Reduced (Percentage)')
xlabel('Event Recall (Percentage)')
title('Relationship Between Recall and Data Reduced in Random Patient Sub-Samples')

hold on
x = [1:1:20];
y = [0.526, 0.512, 0.533, 0.56, 0.581, 0.598, 0.606, 0.605, 0.607, 0.604, 0.6065, 0.6, 0.601, 0.6, 0.595, 0.594, 0.608, 0.607,0.609,0.607];
plot(x,y,'b')
ylabel('Accuracy')
xlabel('Epochs')
title('Training Curve with Word-Level Embeddings')
ylim([0.4 0.7])

hold on
x = [1:1:20];
y = [0.526, 0.512, 0.533, 0.56, 0.581, 0.598, 0.606, 0.605, 0.607, 0.604, 0.6065, 0.6, 0.601, 0.6, 0.595, 0.594, 0.608, 0.607,0.609,0.607];
plot(x,y,'b')
ylabel('Accuracy')
xlabel('Epochs')
title('Training Curve with Word-Level Embeddings')
ylim([0.45 0.65])

hold on
x = [1:1:20];
y1 = [0.492, 0.503, 0.492, 0.492, 0.49, 0.495, 0.497, 0.498, 0.499 0.492, 0.489, 0.496, 0.499, 0.502, 0.492, 0.493, 0.542, 0.566, 0.58, 0.596]
y2 = [0.487, 0.49, 0.551, 0.572, 0.582, 0.593, 0.594, 0.58, 0.587, 0.594, 0.57, 0.559, 0.557, 0.55, 0.541, 0.541, 0.542, 0.551, 0.543, 0.54]
plot(x,y1,'b', x, y2,'r')
legend('LSTM','Bag of Words', 'Precision (Percentage)','Location','SouthEast')
ylabel('Question Accuracy')
xlabel('Question Accuracy')
title('Training Curve with Sentence-Level Embeddings')
ylim([0.45 0.65])
