var r = 650,
    x = d3.scale.linear().range([0, r]),
    y = d3.scale.linear().range([0, r]),
    node,
    root;

var pack = d3.layout.pack()
    .size([r, r])
    .value(function(d) { return d.size; });

var graph = d3.select('#graph');
var w = graph[0][0].clientWidth;
var h = graph[0][0].clientHeight;
var vis = graph.insert('svg:svg')
    .attr('width', w)
    .attr('height', h)
    .append('svg:g')
    .attr('transform', 'translate(' + (w - r) / 2 + ',' + (h - r) / 2 + ')');

function zoom(d) {
    var k = r / d.r / 2;

    x.domain([d.x - d.r, d.x + d.r]);
    y.domain([d.y - d.r, d.y + d.r]);

    var t = vis.transition()
          .duration(d3.event.altKey ? 7500 : 750);

    t.selectAll('circle')
        .attr('cx', function(d) { return x(d.x); })
        .attr('cy', function(d) { return y(d.y); })
        .attr('r', function(d) { return k * d.r; });

    t.selectAll('text')
        .attr('x', function(d) { return x(d.x); })
        .text(function(d) { 
                if (d.url && d.url.length != 0 && k < 2) {
                    return '';
                }
                return d.name;
            })  
        .attr('y', function(d) { return y(d.y); })
        .style('opacity', function(d) { 
            if (k === 1 && d.name.indexOf('lines') != -1) {
                return 1;
            }
            else if (k === 1) {
                return 0;
            }
            else {
                return k * d.r > 20 ? 1 : 0; 
            }
        });

    node = d;
    d3.event.stopPropagation();
}

d3.json('data/resultOfAnalysisConverted.json', function(data) {
    node = root = data;

    var nodes = pack.nodes(root);

    vis.selectAll('circle')
    .data(nodes)
    .enter().append('svg:circle')
    .attr('class', function(d) { 
        return d.children ? 'parent' : 'child'; 
    })
    .attr('cx', function(d) { return d.x; })
    .attr('cy', function(d) { return d.y; })
    .attr('r', function(d) { return d.r; })
    .on('click', function(d) { return zoom(node === d ? root : d); });

    var t = vis.selectAll('text')
        .data(nodes)
        .enter();
        t.append('svg:text')
        .attr('class', function(d) { 
            if (d.name.indexOf('lines') != -1) {
                var prefix = d.children ? 'parent' : 'child';
                return prefix + ' lines';
            }
            else    
                return d.children ? 'parent' : 'child'; 
        })
        .attr('x', function(d) { return d.x; })
        .attr('y', function(d) { return d.y; })
        .attr('dy', '.35em')
        .attr('text-anchor', 'middle')
        .style('opacity', function(d) { 
            if (d.name.indexOf('lines') != -1)
                 return d.r > 20 ? 1 : 0;
            else   
                return 0;
        })
        .text(function(d) { return d.name; })
        .on('click', function(d) { 
            if (d.depth === 3) {
                $.get('codeReader.php', {'filePath': d.url }, function( data ) {
                    var res = $("#code").replaceWith('<pre class="brush: java" id="code">' + data + '</pre>');
                    $('#codeModal').modal('show');
                    $('#codeModal h4').html('File ' + d.name);
                    var url = d.url;
                    var replacedURL = url.replace(' ', '+');
                    $('#openInEclipseButton').attr('href', 'openineclipse://open?url=file://' + replacedURL + '&line=' + d.begin);
                    SyntaxHighlighter.defaults['highlight']  = d3.range(d.begin, d.end + 1);
                    SyntaxHighlighter.highlight();

                    $('#codeModal').on('shown.bs.modal', function() {
                        var $container = $(this);
                        var linePos = $('.number' + d.begin).first().position().top;

                        $container.animate({scrollTop: linePos}, 'fast');
                    });      
                });
            }
        });

    d3.select(window).on('click', function() { zoom(root); });
});

$.getJSON("data/resultOfAnalysisConvertedToPieChartFormat.json", function(dataJSON) {
    var chartConfig = {
        "size": {
            "canvasWidth": 1024,
            "pieOuterRadius": "90%"
        },
        "data": {
            "sortOrder": "value-desc",
        },
        "labels": {
            "outer": {
                "pieDistance": 32
            },
            "inner": {
                "hideWhenLessThanPercentage": 3
            },
            "mainLabel": {
                "fontSize": 11
            },
            "percentage": {
                "color": "#ffffff",
                "decimalPlaces": 0
            },
            "value": {
                "color": "#adadad",
                "fontSize": 11
            },
            "lines": {
                "enabled": true
            },
            "truncation": {
                "enabled": true
            }
        },
        "tooltips": {
            "enabled": true,
            "type": "caption",
            "styles": {
                backgroundColor: "lightblue",
                backgroundOpacity: 0.9,
                color: "#ffffcc",
            }
        },
        "effects": {
            "pullOutSegmentOnClick": {
                "effect": "linear",
                "speed": 400,
                "size": 8
            }
        },
        "misc": {
            "gradient": {
                "enabled": false,
                "percentage": 100
            }
        },
        "callbacks": {}
    };

    // set data
    chartConfig.data.content = dataJSON;

    // render chart
    var pie = new d3pie("pieChart", chartConfig);

    // render info table
    jQuery.each(dataJSON, function(i, duplicationClass) {
        $('#duplicationClassTable > tbody:last-child').append('<tr><td>' + duplicationClass.label + '</td><td>' + duplicationClass.caption + '</td><td>' + duplicationClass.value + '</td></tr>');
    });
});