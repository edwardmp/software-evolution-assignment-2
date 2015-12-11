<?php

$filePath = $_GET["filePath"];

if (!$filePath)
{
    throw new Exception("No path passed.");
}

if (!is_file($filePath))
{
    throw new Exception("No file exists at location.");
}

print(htmlentities(file_get_contents($filePath)));

?>