<?php

$analysisResultJSONFileContents = file_get_contents("resultOfAnalysis.json");

$jsonAsArray = json_decode($analysisResultJSONFileContents);
$allDuplicationClasses = $jsonAsArray[1];

$convertedDataArray = array();

foreach ($allDuplicationClasses as $duplicationClass)
{
    $amountOfLinesInDuplicationClass = 0;
    $duplicatedCodeBlockContents = $duplicationClass[0][1];

    $convertedDataArray[$duplicatedCodeBlockContents]["children"] = array();

    $locations = $duplicationClass[1][1];
   // var_dump($locations);
    foreach ($locations as $location)
    {
        $locationInfoAsArray = (array) $location[1];
        $amountOfLinesInDuplicationClass += $locationInfoAsArray["endLine"] - $locationInfoAsArray["beginLine"];
        $locationInfoToKeep = array_intersect_key($locationInfoAsArray , array_flip(array("endLine", "beginLine", "path")));
        $convertedDataArray[$duplicatedCodeBlockContents]["children"][] = $locationInfoToKeep;
    }

    $convertedDataArray[$duplicatedCodeBlockContents]["numberOfLines"] = $amountOfLinesInDuplicationClass;

    //print_r($convertedDataArray);
}

$convertedDataArrayAsJSON = json_encode($convertedDataArray);

file_put_contents("resultOfAnalysisConverted.json", $convertedDataArrayAsJSON);

?>