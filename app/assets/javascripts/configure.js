var configureApp = angular.module("configureApp", []);
configureApp.controller("configureController", ['$scope', function($scope){
    $scope.csvCols = [];
    $scope.firstColumn = "";

    $scope.isFormInvalid = function(){
        return $scope.frmConfigure.$invalid || $scope.firstColNotValid();
    };
    $scope.firstColNotValid = function(){
        return $scope.firstColumn != "" && $scope.firstColumn.toLowerCase() != "email"
    }

}]);

configureApp.directive("fileread", [function () {
    return {
        link: function (scope, element, attributes) {
            element.bind("change", function (changeEvent) {

                var reader = new FileReader();
                reader.onload = function (loadEvent) {
                    //debugger;
                    scope.$apply(function () {
                        scope.csvFile = loadEvent.target.result;
                        scope.csvCols = scope.csvFile.split("\n")[0].split(",");
                        scope.firstColumn = scope.csvCols[0].toLowerCase();
                    });
                };
                reader.readAsText(changeEvent.target.files[0]);
            });
        }
    }
}]);