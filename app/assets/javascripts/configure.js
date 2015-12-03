var configureApp = angular.module("configureApp", []);
configureApp.controller("configureController", ['$scope', '$http', '$interval', function($scope, $http, $interval){
    $scope.csvCols = [];
    $scope.firstColumn = "";
    $scope.modelObject = {};

    $scope.isFormInvalid = function(){
        return $scope.frmConfigure.$invalid || $scope.firstColNotValid();
    };
    $scope.firstColNotValid = function(){
        return $scope.firstColumn != "" && $scope.firstColumn.toLowerCase() != "email"
    };

    $scope.submitForm = function(authToken){

        var sendData = {
            from_email: $scope.modelObject.fromEmail,
            from_name: $scope.modelObject.fromName,
            subject: $scope.modelObject.subject,
            template_id: $scope.modelObject.templateId,
            notify_email: $scope.modelObject.notifyEmail
        };

        var fd = new FormData();
        fd.append("authenticity_token", authToken);
        fd.append("csv_file", $scope.modelObject.csvFile);
        fd.append("data", JSON.stringify(sendData));

        $http.post("/email/send", fd,{
            headers: {
                'Content-Type': undefined
            },
            transformRequest: angular.identity
        });

        //$interval(function(){
        //    $scope.getStatus(authToken);
        //}, 2000);
    };

    //$scope.getStatus = function(authToken){
    //    $http.get("/email/get_progress", {authenticity_token: authToken})
    //        .success(function(data){
    //            console.log(data);
    //        })
    //        .error(function(data){
    //            console.log(data);
    //        })
    //};

}]);

configureApp.directive("fileread", [function () {
    return {
        link: function (scope, element, attributes) {
            element.bind("change", function (changeEvent) {

                var reader = new FileReader();
                reader.onload = function (loadEvent) {
                    scope.$apply(function () {
                        debugger;
                        //scope.modelObject.csvFile = loadEvent.target.result;
                        var fileText = loadEvent.target.result;
                        scope.csvCols = fileText.split("\n")[0].split(",");
                        scope.firstColumn = scope.csvCols[0].toLowerCase();
                    });
                };
                scope.modelObject.csvFile = changeEvent.target.files[0];
                if(scope.modelObject.csvFile){
                    reader.readAsText(changeEvent.target.files[0]);
                }
            });
        }
    }
}]);