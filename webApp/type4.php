<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->

        <title>Duplication Visualizer</title>
        <!-- Bootstrap core CSS -->
        <link href="bower_components/bootstrap/dist/css/bootstrap.min.css" rel="stylesheet">
        <link href="bower_components/SyntaxHighlighter/styles/shCore.css" rel="stylesheet" type="text/css" />
        <link href="bower_components/SyntaxHighlighter/styles/shThemeDefault.css" rel="stylesheet" type="text/css" />

        <!-- Custom styles for this template -->
        <link href="style/dashboard.css" rel="stylesheet">
        <link href="style/d3.css" rel="stylesheet">

        <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
        <!--[if lt IE 9]>
        <script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
        <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
        <![endif]-->
    </head>
    <body>
        <nav class="navbar navbar-inverse navbar-fixed-top">
            <div class="container-fluid">
                <div class="navbar-header">
                    <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
                        <span class="sr-only">Toggle navigation</span>
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                    </button>
                    <a class="navbar-brand" href="#">Duplication Visualizer <span class="glyphicon glyphicon-stats"></span></a>
                </div>
                <div id="navbar" class="navbar-collapse collapse">
                    <ul class="nav navbar-nav navbar-right">
                        <li<a href="/type1.php">Type 1</a></li>
                        <li><a href="/type2.php">Type 2</a></li>
                        <li class="active"><a href="/type4.php">Type 4</a></li>
                    </ul>
                </div>
            </div>
        </nav>

        <div class="container-fluid">
            <div class="row">
                    <div class="col-md-10 col-md-offset-1 main">
                    <h1 class="page-header">Type 4</h1>
            </div>

            <div class="row">
                <div class="col-md-10 col-md-offset-1">

                    <div id="graph" style="height:800px"></div>
                    <div id="pieChart"></div>

                    <table id="duplicationClassTable" class="table table-hover table-striped"> 
                        <thead> 
                            <tr>
                                <th>
                                    #
                                </th> 
                                <th>
                                    Files
                                </th>
                                <th>
                                    Number of duplicate lines per instance
                                </th>
                                <th>
                                    Total number of lines duplicated
                                </th>
                            </tr> 
                        </thead> 
                        <tbody>
                        </tbody> 
                    </table>
                </div>

            </div>
        </div>

        <!-- Modal -->
        <div class="modal fade" id="codeModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel">
            <div class="modal-dialog modal-lg" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                        <h4 class="modal-title" id="myModalLabel">Code</h4>
                        <a href="#" id="openInEclipseButton" class="btn btn-info btn-lg"><span class="glyphicon glyphicon glyphicon-file" aria-hidden="true"></span> Open in Eclipse</a>
                    </div>

                    <div class="modal-body">
                        <pre class="brush: java" id="code"></pre>
                    </div>

                    <div class="modal-footer">
                        <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                    </div>
                </div>
            </div>
        </div>

        <!-- Bootstrap core JavaScript
        ================================================== -->
        <!-- Placed at the end of the document so the pages load faster -->
        <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
        <script type="text/javascript" src="bower_components/jquery/dist/jquery.js"></script>
        <script type="text/javascript" src="bower_components/bootstrap/dist/js/bootstrap.js"></script>

        <script type="text/javascript" src="bower_components/d3/d3.js"></script>
        <script type="text/javascript" src="bower_components/d3pie/d3pie/d3pie.min.js"></script>
        <script type="text/javascript" src="bower_components/SyntaxHighlighter/scripts/xRegExp.js"></script>
        <script type="text/javascript" src="bower_components/SyntaxHighlighter/scripts/shCore.js"></script>
        <script type="text/javascript" src="bower_components/SyntaxHighlighter/scripts/shBrushJava.js"></script>
        <script src="scripts/visualize.js"></script>
    </body>
</html>