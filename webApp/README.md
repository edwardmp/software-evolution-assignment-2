# Software Evolution Assignment 2
## Web app: Visualizer

The web app uses the JSON data files generated by Rascal. Formatting of these files is not optimal so the JSON first needs to undergo a couple of conversion steps.

To run the conversion simply execute the `convertJSON.php` script, e.g. by running this from the commandline:

```
# php convertJSON.php
Conversion successful from input file /Users/Edward/eclipse/workspace/Assignment 2/visualizer/resultOfAnalysis.json.
Found and extracted 15 duplication classes.
Data written to files resultOfAnalysisConverted.json and resultOfAnalysisConvertedToPieChartFormat.json.
```

To serve the HTML and JSON files a webserver is needed, since local JSON files can not be accessed using the `file://` URI scheme.

Luckily, PHP nowadays features a built-in server. It can be started by issuing the following command:

```
php -S localhost:8000
```

The visualizer web app can now be viewed in your browser by going to [http://localhost:8000](http://localhost:8000).