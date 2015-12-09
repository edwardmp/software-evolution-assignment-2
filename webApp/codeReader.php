<?php

$filePath = $_GET["filePath"];

if (!$filePath)
{
    throw new Exception("No path passed.");
}

print(htmlentities(file_get_contents($filePath)));

?>