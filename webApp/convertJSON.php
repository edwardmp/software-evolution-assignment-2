<?php

$analysisResultJSONFileContents = file_get_contents("resultOfAnalysis.json");

$jsonAsArray = json_decode($analysisResultJSONFileContents);
$allDuplicationClasses = $jsonAsArray[1];

$convertedDataArray = array();

foreach ($allDuplicationClasses as $duplicationClass)
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
        $childLocationArray["name"] = sprintf("%s %d %d", basename($locationInfoAsArray["path"]), $locationInfoAsArray["beginLine"], $locationInfoAsArray["endLine"]);
        $childLocationArray["size"] = $duplicationNumberOfLinesPerBlock;

        $convertedLocationArray[] = $childLocationArray;
    }

    $duplicationCategoryName = sprintf("%d lines", $duplicationNumberOfLinesPerBlock, "lines");
    $duplicationClassArray = array("name" => substr($duplicatedCodeBlockContents, 0, 100), "children" => $convertedLocationArray);

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

$convertedDataArrayAsJSON = json_encode($convertedDataArrayWithLineCategoryRewrittenWithSkeleton );

file_put_contents("resultOfAnalysisConverted.json", $convertedDataArrayAsJSON);

?>