Notification = {
    Show: function (text, type, options) {

        if (!window.jQuery) {
            alert("jQuery is not loaded. This library requires jQuery.")
        }
        var defaults = {
            hideAfter: 10000, //milli seconds
            autoHide : true,
            device : "desktop" //future use, when supporting mobile
        };

        options = $.extend({}, true, defaults, options);

        var notify = $(".notify");

        if (notify.length == 0) {
            notify = $("<div></div>").addClass("notify alert");
            notify.append("<span class='text'></span>");
            notify.append("<span class='close' onclick='Notification.Hide();'>&times;</span>");

            notify.find(".text").html(text);

            notify.css({"top": -200, "left": 0, "right": 0});
            notify.appendTo($("body"));

        }else{
            notify.find(".text").html(text);
        }

        switch(type){
            case "success":
                notify.removeClass("alert-warning").removeClass("alert-danger").addClass("alert-success");
                break;
            case "warning":
                notify.removeClass("alert-success").removeClass("alert-danger").addClass("alert-warning");
                break;
            case "error":
                notify.removeClass("alert-warning").removeClass("alert-success").addClass("alert-danger");
                break;
        }

        setTimeout(function(){
            notify.css("top", 0);
        }, 100);

        if(options.autoHide){
            var me = this;
            var notifyTime = setTimeout(function(){
                me.Hide();
            }, options.hideAfter);
        }
    },

    Hide: function () {
        $(".notify").css("top",-200);//.addClass("invisible");
    }
};
