<?php

define('RASCAL_ANALYSIS_RESULT_LOCATION', sprintf("%s/%s", dirname(__DIR__), "visualizer/resultOfAnalysis.json"));
define('RESULT_OF_ANALYSIS_CONVERTED_PACK_HIERARCHY_LOCATION', "resultOfAnalysisConverted.json");
define('RESULT_OF_ANALYSIS_CONVERTED_PIE_CHART_LOCATION', "resultOfAnalysisConvertedToPieChartFormat.json");

$analysisResultJSONFileContents = file_get_contents(RASCAL_ANALYSIS_RESULT_LOCATION);

function convertJSON($analysisResultJSONFileContents)
{
    // convert JSON to PHP array
    $jsonAsArray = json_decode($analysisResultJSONFileContents);
    $allDuplicationClasses = $jsonAsArray[1];

    $convertedDataArray = array();
    $duplicationClassList = array();

    foreach ($allDuplicationClasses as $key => $duplicationClass)
    {
        $duplicatedCodeBlockContents = $duplicationClass[0][1];
        $locations = $duplicationClass[1][1];

        $firstLocationInfo = $locations[1][1];
        $duplicationNumberOfLinesPerBlock = $firstLocationInfo->endLine - $firstLocationInfo->beginLine;
        $amountOfLinesInDuplicationClass = count($locations) * $duplicationNumberOfLinesPerBlock;

        $convertedLocationArray = array();
        foreach ($locations as $location)
        {
            $locationInfoAsArray = (array) $location[1];

            $childLocationArray = array();
            $childLocationArray["name"] = basename($locationInfoAsArray["path"]);
            $childLocationArray["size"] = $duplicationNumberOfLinesPerBlock;
            $childLocationArray["url"] = $locationInfoAsArray["path"];
            $childLocationArray["begin"] = $locationInfoAsArray["beginLine"];
            $childLocationArray["end"] = $locationInfoAsArray["endLine"];
            $childLocationArray["basenamePlusFileLocation"] =  sprintf("%s <%d, %d>", $childLocationArray["name"], $childLocationArray["begin"], $childLocationArray["end"]);

            $convertedLocationArray[] = $childLocationArray;
        }

        // used in pack hierarchy
        $duplicationCategoryName = sprintf("%d lines", $duplicationNumberOfLinesPerBlock, "lines");
       
        // used in pie chart
        $duplicationClassArray = array("name" => "", "children" => $convertedLocationArray);

        $locationsArray = array_unique(array_column($convertedLocationArray, "basenamePlusFileLocation"));
        $duplicationClassList[] = array("caption" => join(", ", $locationsArray), "label" => "Duplication class $key", "value" => $amountOfLinesInDuplicationClass);
        if (!array_key_exists($duplicationCategoryName, $convertedDataArray))
             $convertedDataArray[$duplicationCategoryName] = array();

        $convertedDataArray[$duplicationCategoryName][] = $duplicationClassArray;
    }

    $convertedDataArrayWithLineCategoryRewritten = array();
    foreach($convertedDataArray as $convertDataArrayLineCategoryKey => $convertDataArrayLineCategoryValue)
    {
        $convertedDataArrayWithLineCategoryRewritten [] = array("name" => $convertDataArrayLineCategoryKey, "children" => $convertDataArrayLineCategoryValue);
    }

    $convertedDataArrayWithLineCategoryRewrittenWithSkeleton = array("name" => "", "children" => $convertedDataArrayWithLineCategoryRewritten);

    convertArrayToJSONAndSaveToFile($convertedDataArrayWithLineCategoryRewrittenWithSkeleton, $duplicationClassList);
}

function convertArrayToJSONAndSaveToFile($convertedDataArrayWithLineCategoryRewrittenWithSkeleton, $duplicationClassList)
{
    $convertedDataArrayAsJSON = json_encode($convertedDataArrayWithLineCategoryRewrittenWithSkeleton );

    file_put_contents(sprintf("data/%s", RESULT_OF_ANALYSIS_CONVERTED_PACK_HIERARCHY_LOCATION), $convertedDataArrayAsJSON);

    $duplicationClassesAsJSON = json_encode($duplicationClassList);

    file_put_contents(sprintf("data/%s", RESULT_OF_ANALYSIS_CONVERTED_PIE_CHART_LOCATION), $duplicationClassesAsJSON);

    printf("Conversion successful from input file %s.\nFound and extracted %d duplication classes.\nData written to files %s and %s.\n", RASCAL_ANALYSIS_RESULT_LOCATION, count($duplicationClassList), RESULT_OF_ANALYSIS_CONVERTED_PACK_HIERARCHY_LOCATION, RESULT_OF_ANALYSIS_CONVERTED_PIE_CHART_LOCATION);

}

convertJSON($analysisResultJSONFileContents);
?>