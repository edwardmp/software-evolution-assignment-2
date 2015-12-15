<?php

function head()
{
    print(file_get_contents('./template/header.html'));
}

function content($title)
{
    $content = file_get_contents('./template/content.html');

    $replacedContent = substituteVariablePlaceholders(array("TypeTitle"), array($title), $content);

    print($replacedContent);
}

function footer()
{
    print(file_get_contents('./template/footer.html'));
}

function substituteVariablePlaceholders($variablesToSubstitute, $values, $content)
{
    array_walk($variablesToSubstitute, function(&$item)
    { 
        $item = sprintf("{{ %s }}", $item); 
    });

    return str_replace($variablesToSubstitute, $values, $content);
}
?>