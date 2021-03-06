/*************
 * PREP DATA
 ************/

// remove initial predictions from db creation
while(preds[0]==4){
    preds.shift()
    times.shift()
}

console.log(preds);
console.log(times);

//chart sizing and viewing variables
var timespan=times[times.length-1].clone().diff(times[0],'minutes', true),
    windowSelector=$("#timeWindow")[0],
    windowSize=parseInt(windowSelector.value),
    minperpx=windowSize/$("#chart-wrapper")[0].clientWidth,
    ht=200,
    wd=1530,
    canvasTag='<canvas id="chart" style="height:' + ht.toString() + '; width:' + wd.toString() + '"></canvas>',
    viewing=[Math.max(0,timespan-windowSize),timespan],
    raw_view=[0, parseInt($("#raw-window").val())];


//variables for datasets and plotting
var chart,
    nav,
    raw,
    dataset=[],
    dataset_n=[],
    dataset_r=[],
    dataset_rn=[],
    timepoints=[],
    chartColors = ['#0ec6e5','#ffde59','#ff5757','#000000'],
    chartColors_r = ['rgb(255, 255, 255)','#ffde59','#ff5757','#000000'];

//fill datasets
for (let i=0; i<preds.length;i++){
    // store timepoints at the end of each prediction
    timepoints.push(times[i+1].clone().diff(times[0],'minutes', true));
    //all data mode chart
    dataset.push({
        backgroundColor: chartColors[preds[i]],
        borderColor: chartColors[preds[i]],
        data: [times[i+1].clone().diff(times[i],'minutes', true)],
        order: 1
    });
    //all data mode navigation bar
    dataset_n.push({
        backgroundColor: chartColors[preds[i]],
        borderColor: chartColors[preds[i]],
        pointRadius: 0,
        data: [{
            x: times[i],
            y: 1
        }, {
            x:times[i+1],
            y:1
        }],
    });
    //data reduced mode chart
    dataset_r.push({
        backgroundColor: chartColors_r[preds[i]],
        borderColor: chartColors_r[preds[i]],
        data: [times[i+1].clone().diff(times[i],'minutes', true)],
    });
    //data reduced mode navigation
    dataset_rn.push({
        backgroundColor: chartColors_r[preds[i]],
        borderColor: chartColors_r[preds[i]],
        pointRadius: 0,
        data: [{
            x: times[i],
            y: 1
        }, {
            x:times[i+1],
            y:1
        }],
    });

}

// group together datasets
var datasets=[dataset, dataset_r],
    datasets_n=[dataset_n, dataset_rn];

/**
 * @param {Array} v array of length 2 indicating the left and right bound of the viewing window for the given chart
 * @param {Array} ds datasets to select from. if for the chart, pass the following for this argument: [{data: datasets[$('#dataView')[0].value]}]
 * @param {Array} tpts array of floats indicating the time of each data point relative to the first point in the chart
 * @param {Boolean} main indicates whether or not the data is being selected for the prediction display
 *  
 * function to select datasets that are displayed on the specified chart
 * used in the raw data viewer and the prediction display
 */
//TODO: might just be better off breaking this up into 2 functions
function selectData(v,ds,copy,tpts,main){
    var t=[];
    t[0]=tpts.filter(x=>x<=v[0])[tpts.filter(x=>x<=v[0]).length-1];
    if(isNaN(t[0])){
        t[0]=0;
    }
    var start=tpts.lastIndexOf(t[0])+1;

    t[1]=tpts.filter(x=>x>=v[1])[0];
    if(isNaN(t[1])){
        var end=tpts.length;
    } else{
        var end=tpts.indexOf(t[1])+1;
    }
    if(copy==null){
        copy=JSON.parse(JSON.stringify(ds));
        for (let i=0;i<ds.length;i++){
            copy[i].data=copy[i].data.slice(start,end);
        }
    }else{
        for (let i=0;i<ds.length;i++){
            copy[i]["data"]=ds[i].data.filter(function(el,ind){return ind>=start && ind<=end});
        }
    }
    if(main){
        //adjust the first and last entries based on what falls in range
        copy[0].data[0].data[0]-=v[0]-t[0];
        copy[0].data[copy[0].data.length-1].data[0]-=t[1]-v[1];
        return copy[0].data
    } else{
        return copy
    }
}

/************************
 * CALLBACKS FOR THE CHART
*************************/

// prediction selection variables
var xhr,
    prediction,
    tot,
    left_px,
    selected="#f1f1f1";

var before;
var after;

/**
 * @param {chart-js-tooltip} tooltipItem 
 * @returns {Float} confidence score associated with the selected prediction
 * 
 * Callback function for tooltips in the chart. 
 * If the window size is too large an alert is displayed.
 * Otherwise it calls view to pull and plot data, and indexes
 * the array of seizure likelihoods to display.
 */
function tooltipCallback(tooltipItem){


    var t=timepoints.filter(x=>x<=viewing[0])[timepoints.filter(x=>x<=viewing[0]).length-1];
    prediction=tooltipItem.datasetIndex+timepoints.lastIndexOf(t)+1;
    if(windowSize<=5){
        view(tooltipItem.datasetIndex);
    } else{
        alert("Raw data viewing mode is only available for a window size of 5 minutes");
    }

    /**
     * 
     * @param {Integer} datasetIndex index of the selected dataset relative to the current viewing window
     * 
     * Pull and plot selected data
     * First determines the pulling paramaters 
     * then launches an async task to pull data
     * and finally plots the dataa.
     */
    async function view(datasetIndex){
    
        if(raw!=null){
            //replace the canvas tag for the raw data viewer
            console.log('replacing tag');
            $("#raw").get(0).outerHTML;
            $('#raw').remove();
        } else{
            $('#viewer-opt-container').css('border','3px solid #f1f1f1');
            $('#viewer-wrapper p').remove();
            $('#sliders').css('visibility','visible');
            // $('#gain').css('visibility','visible');
            // $('#raw-window').css('visibility','visible');
        }
        $("#viewer-wrapper").append('<div id="loader" class="loader"></div>');
        $("#viewer-wrapper").css('cursor','wait');
        var data=selectData(viewing,[{data: datasets[$('#dataView')[0].value]}],null,timepoints,true);
    
        //determine the location of the prediction sector box
        tot=0;
        for(let i=0; i<datasetIndex; i++){
            tot+=data[i].data[0];
        }
        left_px=100*(tot/windowSize);
        var width_px=100*(data[datasetIndex].data[0]/windowSize);
    
        $('#pred-selector').css('border','5px solid #545454');
        $('#pred-selector').css('display','block');
        $('#pred-selector').css('left',left_px.toString()+"%");
        $('#pred-selector').css('width',width_px.toString()+"%");
    
        // determine the the bounds of the data to be pulled
        var leftBound=moment.max(times[prediction], times[0].clone().add(viewing[0],'minutes', true));
        var rightBound=moment.min(times[prediction+1], times[0].clone().add((viewing[0])+windowSize,'minutes', true) );
    
        console.log(leftBound.format(leftBound._f+'.SSS'));
        console.log(rightBound.format(rightBound._f+'.SSS'));
    
        //launch an async task to fetch all the data for the selected prediction
        console.log('pulling data');
        await pull_plot();


        
        async function pull_plot() {
            /**
            * If there's an unfinished request abort it.
            * In either case send an ajax request to the server for data
            */

           //TODO: we might want to consider compressing and decompressing data to help with performance. 
           //It is a lot of data to be sending..
            if(xhr && xhr.readyState!=4){
                xhr.abort();
            } 
            xhr= $.ajax({
                url:'/pull-data' , 
                data:{bed, start: leftBound.format(leftBound._f+'.SSS'), end: rightBound.format(rightBound._f+'.SSS')},
                success: function(data){plotData(data);}
            });
        
        }

        /**
         * 
         * @param {JSON} raw_data each key corresponds to an array of EEG data for a different channl
         * 
         * Fill datasets and plot as a line chart
         * Each dataset should correspond to its own channel of EEG data
         */
        function plotData(raw_data) {
            var raw_times;
            console.log('data pulled');
            $("#loader").remove();
            $('#viewer-wrapper').append('<canvas id="raw" style="margin: auto; display: none;"></canvas>');
            $("#viewer-wrapper").css('cursor','');
            $("#raw").show();
            raw_times=raw_data.times.map( function callback(val) { return moment(val,'YYYY-MM-DD hh:mm:ss.SSS') });
            raw_times=raw_times.map(x=>x.clone().diff(raw_times[0],'seconds',true));
            var inc=0;
            var raw_datasets=[];
            var copy=[];
            function reformat(data, i, raw_times){
                return {x: raw_times[i], y: Math.exp(parseInt($("#gain").val()))*data}
            }
            for (const ch of Object.keys(raw_data.data)) {
                raw_datasets.push({
                    label: ch,
                    borderColor: "#545454",
                    fill: false,
                    pointRadius: 0,
                    lineTension: 0,
                    borderWidth: .25,
                    data: raw_data.data[ch].map(x=>x+inc).map(function (y,i) {return reformat(y, i, raw_times)})
                });
                copy.push({
                    label: ch,
                    borderColor: "#545454",
                    fill: false,
                    pointRadius: 0,
                    lineTension: 0,
                    borderWidth: .25,
                    data: []
                });
                inc+=75;
        
            }
            // create viewer  
            raw_view=[0, parseInt($("#raw-window").val())];
            var ctx3=$("#raw")[0].getContext('2d');
            console.log('rendering chart');
            raw = new Chart(ctx3, {
                type: 'line',
                data: {datasets: selectData(raw_view,raw_datasets,copy,raw_times,false)},
                options: {
                    events: [null],
                    responsive: true,
                    maintainAspectRatio: false,
                    animation: {duration: 0},
                    downsample: {enabled: true, threshold: 1000},
                    legend: {
                        display: true,
                        position: 'left',
                        align: 'center',
                        reverse: true,
                        labels: {
                            fontSize: Math.round(0.45*$("#viewer-wrapper").height()/raw_datasets.length),
                            boxWidth: 0,
                            padding: Math.round(0.35*$("#viewer-wrapper").height()/raw_datasets.length)
                        }
                    },
                    scales: {
                        yAxes: [{
                            type: "linear", 
                            display: false,
                            ticks: {
                                beginAtZero: true,
                                min: -200,
                                max: 1400,
                            },
                            gridlines: {
                                display: true,
                            }
                        }],
                        xAxes: [{
                            scaleLabel:{
                                display: true,
                                labelString:"Time (s)"
                            },
                            type: "linear",
                            position: 'bottom',
                            display: true,
                            ticks: {
                                min: raw_view[0],
                                max:raw_view[1],
                                maxRotation: 0,
                            },
                            gridlines: {
                                display: true,
                            }
        
                        }]
                    },
                }
            });

            var isDragging=false;
            var x;
            var view_start;
            var pausing=false;
            var pause;
            /**
             * Bind a function to the viewer that allows click and drag navigation
             * 
             * BUG TO FIX: after you scroll right it becomes difficult to return to 0
             */
            $("#raw").css('cursor','grab');
            $("#raw").bind("mousedown", function(e){
                $("#raw").css('cursor','grabbing');
                isDragging=true;
                x=e.offsetX;
                view_start=raw_view.slice(0,2);
            }).bind("mousemove", function(e){
                var sperpx=Math.max(raw_times[raw_times.length-1],raw_view[1])/$("#raw")[0].clientWidth;
                if (isDragging && !pausing){
                    var inBounds=(view_start[0]+(x-e.offsetX)*sperpx)>=0 &&
                                 (view_start[1]+(x-e.offsetX)*sperpx)<=raw_times[raw_times.length-1];
                    if(inBounds){
                        raw_view=view_start.map(a=>a+(x-e.offsetX)*sperpx);
                        raw.data.datasets=selectData(raw_view,raw_datasets,copy,raw_times,false);
                        raw.options.scales.xAxes[0].ticks.min=raw_view[0];
                        raw.options.scales.xAxes[0].ticks.max=raw_view[1];
                        raw.update({duration: 0});
                        pausing=true;
                        pause=setTimeout(function(){pausing=false},5);
                    }
                }
            }).bind("mouseup mouseleave", function(e){
                $("#raw").css('cursor','grab');
                isDragging=false;
            });
            /**
             * bind a function to the gain slider that updates the data set based 
             * on the selected value
             * 
             * TODO: make it so a number appears according to the gain
             * Also make it so this and the window dropdown only appear
             * when the chart appears
             */
            $("#gain").on("change input",function(){
                var gain=Math.exp(parseInt($(this).val()));
                raw_datasets.forEach(function(ch,i){
                    ch.data.forEach(function(t,j){
                        raw_datasets[i].data[j].y=raw_data.data[ch.label][j]*gain+i*75;
                    });
                });
                raw.data.datasets=selectData(raw_view,raw_datasets,copy,raw_times,false);
                raw.update({duration: 0});
            });
            /**
             * bind a functiom to the dropdown menu that updates the viewer depending on
             * the selected window
             * 
             * TODO: fix glitch when clicking new predictions
             */
            var wind=parseInt($("#raw-window").val());
            $("#raw-window").on("change", function(){
                var newwind=parseInt($(this).val());
                if(newwind<=raw_times[raw_times.length-1]){
                    wind=newwind;
                    var l=Math.max(0,Math.min(raw_view[0],raw_times[raw_times.length-1]-wind));
                    raw_view=[l,l+wind];
                    raw.data.datasets=selectData(raw_view,raw_datasets,copy,raw_times,false);
                    raw.options.scales.xAxes[0].ticks.min=raw_view[0];
                    raw.options.scales.xAxes[0].ticks.max=raw_view[1];
                    raw.update({duration: 0});
                }else{
                    $(this).val(wind.toString())
                    alert("Selected window is too large");
                }
            });
            window.onresize=function(){
                raw.options.legend.labels.fontSize=Math.round(0.45*$("#viewer-wrapper").height()/raw_datasets.length);
                raw.options.legend.labels.padding=Math.round(0.35*$("#viewer-wrapper").height()/raw_datasets.length);
                raw.update({duration: 0});
            }
        }
    }
    return conf[prediction].toString();
}


/********************************
 * FUNCTIONS TO CREATE THE CHARTS
 ********************************/

/**
 * 
 * @param {Array} dataset data to plot; array of dataset objects
 * @param {Integer} dur duration of the animation in ms
 * creating just the first chart (the focused in chart on top)
 */
function createChart1(dataset, dur){
    var ctx=$("#chart")[0].getContext('2d');
    chart = new Chart(ctx, {
        type: 'horizontalBar',
        data: {
            labels: ['Seizure Likelihood'],
            datasets: dataset
        },
        options: {
            events: ['dblclick'],
            responsive:true,
            maintainAspectRatio: false,
            animation: {
                duration: dur,
            },
            tooltips: {
                enabled: true,
                mode: 'dataset',
                position: 'average',
                callbacks:{
                    label: tooltipCallback,
                }
            },

            legend: {display: false},
            scales: {
                yAxes: [{display: false, stacked: true}],
                xAxes: [{
                    offset: false,
                    display: false,
                    stacked: true,
                    ticks:{ 
                        beginAtZero: true,
                        suggestedMax: windowSize,
                        padding: 0,
                        stepSize: 0.001
                    },
                }]
            }
        }
    });


    /**
     * Bind mouse move and mouseup/mouseleave functions to the canvas
     * element for the chart in order to enable click and drag navigation
     */

    var isDragging=false;
    var x;
    var view_start;
    var pausing=false;
    var pause;
    $("#chart").css('cursor','pointer');
    $("#chart").bind('mousemove', function(e) {
        if (e.buttons>0){
            //if clicked
            if(!isDragging){
                //if just clicked set dragging to true and log the x value and viewing window at the start
                isDragging=true;
                x=e.offsetX;
                view_start=viewing.slice(0,2);
                $("#chart").css('cursor','grabbing');
            } else if (!pausing && (view_start[0]+(x-e.offsetX)*minperpx)>=0 && (view_start[1]+(x-e.offsetX)*minperpx)<=timespan){
                //if already clicked and acceptable, update view based on mouse movement
                var prevl=viewing[0];
                viewing=view_start.map(a=>a+(x-e.offsetX)*minperpx);
                if (left_px!=null){
                    left_px+=100*(prevl-viewing[0])/windowSize;
                    $('#pred-selector').css('left',left_px.toString()+"%");
                 }
                updateAxis();
                chart.data.datasets=selectData(viewing,[{data: datasets[$('#dataView')[0].value]}],null,timepoints,true);
                chart.update({duration: 0});
                pausing=true;
                pause=setTimeout(function(){pausing=false},5);
            }
        } 
    }).bind('mouseup mouseleave', function(e){
        if(isDragging==true){
            //replace the canvas tag of the chart only if the mouseup event follows dragging
            //NOTE: this is necessary because tooltips disappear on chart.update()
            $("#chart").css('cursor','pointer');
            isDragging=false;
            updateAxis();
            $('#chart').remove();
            $('#chart-wrapper').append(canvasTag);
            createChart1(selectData(viewing,[{data: datasets[$('#dataView')[0].value]}],null,timepoints,true),0);
        }
    });
}

/**
 * 
 * @param {Array} dataset data for the first chart
 * @param {Array} dataset_n data for the navigation bar
 * @param {Integer} dur duration of animation
 * creating both the top chart and the navigation bar
 */
function createGraphs(dataset, dataset_n, dur){
    var ctx2=$("#nav")[0].getContext('2d');
    createChart1(dataset, dur);
    nav = new Chart(ctx2, {
        type: 'line',
        data: {datasets: dataset_n},
        options: {
            legend: {display: false},
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                yAxes: [{
                    type: "linear", 
                    display: false, 
                    ticks: {
                        beginAtZero: true,
                        suggestedMax: 1
                    }
                }],
                xAxes: [{
                    type: "time",
                    suggestedMin: times[0],
                    suggestedMax: times[times.length-1],
                    distribution: "linear",
                    ticks: {
                        maxRotation: 0,
                        autoSkip: true,
                        autoSkipPadding: 3,
                    }
                }]
            },
            annotation: {
                annotations: [{
                   type: 'box',
                   drawTime: 'afterDatasetsDraw',
                   xMin:times[0].clone().add(viewing[0],'minutes',true),
                   xMax:times[0].clone().add(viewing[1],'minutes', true),
                   yScaleID: 'y-axis-0',
                   xScaleID: 'x-axis-0',
                   yMin: 0,
                   yMax: 1,
                   borderColor: 'rgba(255,159,64,1)',
                   backgroundColor: 'rgba(255,159,64,0.2)',
                   borderWidth: 4,
    
                }]
            }
        }
    });

    /**
    * Bind a function to mousedown and mousemove events on the navigation bar
    * that updates the viewing window on the top chart according to where the user 
    * clicked or clicked and dragged their mouse to. Also update the location of 
    * the annotation box on the nav bar showing which data is being viewed
    */

    $("#nav").css('cursor','zoom-in')
    $("#nav").bind('mousedown mousemove',function(e){
        if(e.buttons>0){
            let distfromleft=e.clientX-16;
            let pct=distfromleft/($("#nav")[0].offsetWidth-40);
    
            let tl=times[0].clone().add(pct*timespan-(windowSize/2),'minutes', true);
            tl=moment.max(times[0], moment.min(tl , times[times.length-1].clone().subtract(windowSize, 'minutes', true)));
    
            nav.options.annotation.annotations=[{
                type: 'box',
                drawTime: 'afterDatasetsDraw',
                yScaleID: 'y-axis-0',
                xScaleID: 'x-axis-0',
                xMin: tl,
                xMax: tl.clone().add(windowSize,'minutes', true),
                yMin: 0,
                yMax: 1,
                borderColor: 'rgba(255,159,64,1)',
                backgroundColor: 'rgba(255,159,64,0.2)',
                borderWidth: 4,
             }];
             nav.update({duration: 0});
    
             var l=tl.clone().diff(times[0],'minutes', true);
             var prevl=viewing[0];
             viewing=[l, l+windowSize];
    
             $('#chart').remove();
             $('#chart-wrapper').append(canvasTag);
             createChart1(selectData(viewing,[{data: datasets[$('#dataView')[0].value]}],null,timepoints,true),0);
    
             if (left_px!=null){
                left_px+=100*(prevl-l)/windowSize;
                $('#pred-selector').css('left',left_px.toString()+"%");
             }
        }
    });
}


/******************************************************************
 * LISTENERS TO UPDATE THE GRAPHS ACCORDING TO DIFFERENT SETTINGS
 *****************************************************************/

//update charts when the user changes the window size
windowSelector.addEventListener("change", function(){
    if (parseInt(windowSelector.value)<timespan){
        var prev=windowSize;
        windowSize=parseInt(windowSelector.value);
        minperpx=windowSize/$("#chart-wrapper")[0].clientWidth;
        var l=Math.max(0,Math.min(viewing[0],timespan-windowSize));
        viewing=[l,l+windowSize];

        $('#chart').remove();
        $('#chart-wrapper').append(canvasTag);
        createChart1(selectData(viewing,[{data: datasets[$('#dataView')[0].value]}],null,timepoints,true),0);

        nav.options.annotation.annotations=[{
            type: 'box',
            drawTime: 'afterDatasetsDraw',
            yScaleID: 'y-axis-0',
            xScaleID: 'x-axis-0',
            xMin: times[0].clone().add(viewing[0],'minutes', true),
            xMax: times[0].clone().add(viewing[1],'minutes', true),
            yMin: 0,
            yMax: 1,
            borderColor: 'rgba(255,159,64,1)',
            backgroundColor: 'rgba(255,159,64,0.2)',
            borderWidth: 4,
         }];
        nav.update({duration:0});  
    } else{
        $("#timeWindow").val(windowSize.toString());
        alert('window is too large for the recording length');
    }
});

//recreate the graphs when the data viewing mode is changed or when the window size is changed
$('#dataView')[0].addEventListener("change",function(){
    $('#chart').remove();
    $('#nav').remove();
    $('#chart-wrapper').append(canvasTag);
    $('#nav-wrapper').append('<canvas id="nav" style="height:80; width:1600;"></canvas>');
    createGraphs(selectData(viewing,[{data: datasets[$('#dataView')[0].value]}],null,timepoints,true),datasets_n[$('#dataView')[0].value], 0);
});

/*****************************
 *  DATA NAVIGATION FEATURES
 ****************************/

function updateAxis(){
    /**
     * Update the annotation box in the navigation bar
     * when a user scrolls through the data
    */
    nav.options.annotation.annotations=[{
        type: 'box',
        drawTime: 'afterDatasetsDraw',
        yScaleID: 'y-axis-0',
        xScaleID: 'x-axis-0',
        xMin: times[0].clone().add(viewing[0],'minutes', true),
        xMax: times[0].clone().add(viewing[1],'minutes', true),
        yMin: 0,
        yMax: 1,
        borderColor: 'rgba(255,159,64,1)',
        backgroundColor: 'rgba(255,159,64,0.2)',
        borderWidth: 4,
     }];
     nav.update({duration: 0});
}

var pressed;
/**
 * 
 * @param {String} direction direction of button
 * Bind mouse down and mouseup/mouseleave functions to 
 * the buttons for incrementing the viewing window
 */
function bindButton(direction){
    $("#"+direction).mousedown(function(e){ 
        pressed= setInterval( function() { increment(); }, 10);
    }).bind('mouseup mouseleave', function(e){
        clearInterval(pressed); 
        $('#chart').remove();
        $('#chart-wrapper').append(canvasTag);
        createChart1(selectData(viewing,[{data: datasets[$('#dataView')[0].value]}],null,timepoints,true),0);
    });

    //increment the viewing window according to the direction of the button pressed
    function increment(){
        var inc=0.03;
        if(direction=='left'){
            if(viewing[0]-inc>0){
                viewing=viewing.map(x=>x-inc);
                updateAxis();
                chart.data.datasets=selectData(viewing,[{data: datasets[$('#dataView')[0].value]}],null,timepoints,true);
                chart.update({duration: 0});
    
                if(left_px!=null){
                    left_px+=100*(inc/windowSize);
                    $('#pred-selector').css('left',left_px.toString()+"%");
                }
            }
        } else {
            if(viewing[1]+inc<timespan){
                viewing=viewing.map(x=>x+inc);
                updateAxis();
                chart.data.datasets=selectData(viewing,[{data: datasets[$('#dataView')[0].value]}],null,timepoints,true);
                chart.update({duration: 0});
                
                if(left_px!=null){
                    left_px-=100*(inc/windowSize);
                    $('#pred-selector').css('left',left_px.toString()+"%");
                }
            }
        }
    
    }

}


/**********************************
 * BIND CALLBACKS AND CREATE CHARTS
 **********************************/
bindButton('left');
bindButton('right')
createGraphs(selectData(viewing,[{data: datasets[$('#dataView')[0].value]}],null,timepoints,true), dataset_n, 500);
