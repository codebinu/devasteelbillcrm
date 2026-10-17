<%@ Page Language="C#" AutoEventWireup="true" CodeFile="login.aspx.cs" Inherits="login" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Login | Invoice Me</title>
    <%--<script src="js/jquery.js" type="text/javascript"></script>--%>
    <script type="text/javascript" src="js/common.js"></script>
    <script src="js/jquery-2.0.3.js" type="text/javascript"></script>
    <script type="text/javascript" src="js/jquery.cookie.js"></script>
    <!-- Bootstrap -->
    <link href="css/bootstrap/bootstrap.min.css" rel="stylesheet" />
    <!-- Font Awesome -->
    <link href="css/bootstrap/font-awesome/css/font-awesome.min.css" rel="stylesheet" />
    <!-- NProgress -->
    <link href="css/bootstrap/nprogress.css" rel="stylesheet" />
    <!-- Animate.css -->
    <link href="css/bootstrap/animate.min.css" rel="stylesheet" />
    <!-- iCheck -->
    <link href="css/bootstrap/green.css" rel="stylesheet" />
    <!-- Custom Theme Style -->
    <link href="css/bootstrap/custom.min.css" rel="stylesheet" />
    <!--My Style-->
    <link href="../css/bootstrap/mystyle.css" rel="stylesheet" type="text/css" />

    <style>
        body, html {
            height: 100%;
        }

        .bg {
            /* The image used */
            /*background-image: url("images/invoicemeimage4.jpg");*/
            background-color: #4da4e0;
            /* Full height */
            height: 100%;
            /* Center and scale the image nicely */
            background-position: center;
            background-repeat: no-repeat;
            background-size: cover;
        }

        .field-icon {
            float: right;
            margin-left: -25px;
            margin-top: -45px;
            position: relative;
            z-index: 2;
        }

        .container {
            padding-top: 50px;
            margin: auto;
        }
    </style>

    <script type="text/javascript">
        $(document).ready(function () {
                     $.removeCookie('invntrystaffId');
                     $.removeCookie('invntrystaffBranchId');
                     $.removeCookie('invntrystaffCountryId');
                     $.removeCookie('invntrystaffBranchName');
                     $.removeCookie('invntrystaffName');
                     $.removeCookie('invntrystaffPassword');
                     if ($.cookie("invntryrememberme") == "yes") {
                         $("#chebxRememberme").attr("checked", true);
                         $("#comboRoles").val($.cookie("invntrystaffRole"));
                         $("#txtusername").val($.cookie("invntrystaffName"));
                         $("#txtpassword").val($.cookie("invntrystaffPassword"));
                     }
                     else {
                         $("#chebxRememberme").attr("checked", false);
                         $("#txtusername").val('');
                         $("#txtpassword").val('');
                     }

                     $(".toggle-password").click(function () {

                         $(this).toggleClass("fa-eye fa-eye-slash");
                         var input = $($(this).attr("toggle"));
                         if (input.attr("type") == "password") {
                             input.attr("type", "text");
                         } else {
                             input.attr("type", "password");
                         }
                     });
                 });

                 // Start main login
                 function login() {
                     var username = $("#txtusername").val();
                     var password = $("#txtpassword").val();

                     if (username == "") {
                         alert("please enter username");
                         return;
                     }
                     if (password == "") {
                         alert("please enter password");
                         return;
                     }

                     loading();

                     $.ajax({
                         type: "POST",
                         crossdomain: true,
                         url: "login.aspx/mainLogin",
                         data: "{'username':'" + username + "','password':'" + password + "'}",
                         contentType: "application/json; charset=utf-8",
                         dataType: "json",
                         success: function (msg) {
                             Unloading();
                             if (msg.d != "N") {
                                 var Userobj = JSON.parse(msg.d);
                                 if (Userobj == "") {
                                     alert("Please provide correct Login details...!");
                                     return false;
                                 } else {
                                     var CookieDate = new Date();
                                     CookieDate.setFullYear(CookieDate.getFullYear() + 10);
                                     $.cookie("invntrystaffId", Userobj[0].user_id, { expires: CookieDate }); //set cookie
                                     // $.cookie("staffRole", splitarray[2], { expires: CookieDate }); //set cookie
                                     $.cookie("invntrystaffName", username, { expires: CookieDate }); //set cookie
                                     $.cookie("invntrystaffPassword", password, { expires: CookieDate }); //set cookie
                                     $.cookie("invntrystaffFirstName", Userobj[0].first_name, { expires: CookieDate }); //set cookie
                                     $.cookie("invntrystaffLastName", Userobj[0].last_name, { expires: CookieDate }); //set cookie
                                     $.cookie("invntrystaffTypeID", Userobj[0].user_type, { expires: CookieDate }); //set cookie
                                     $.cookie("invntrystaffBranchId", Userobj[0].branch_id, { expires: CookieDate }); //set cookie
                                     $.cookie("invntrystaffBranchName", Userobj[0].branch_name, { expires: CookieDate }); //set cookie
                                     $.cookie("invntryTimeZone", Userobj[0].branch_timezone, { expires: CookieDate }); //set cookie
                                     $.cookie("invntrystaffCountryId", Userobj[0].branch_countryid, { expires: CookieDate }); //set cookie
                                     var tid = $.cookie("invntrystaffTypeID");
                                     if ($("#chebxRememberme").is(':checked')) {
                                         $.cookie("invntryrememberme", "yes", { expires: CookieDate }); //set cookie
                                         $.cookie("invntrystaffPassword", password, { expires: CookieDate }); //set cookie

                                     }
                                     else {
                                         $.cookie("invntryrememberme", "no", { expires: CookieDate }); //set cookie
                                     }

                                     location.href = "dashboard.aspx";
                                     return false;
                                 }

                             }
                             else {
                                 alert("Please provide correct Login details...!");
                                 return false;
                             }

                         },
                         error: function (xhr, status) {
                             Unloading();
                             alert("Internet Problem");
                         }
                     });
                 }

                 function show() {
                     var a = document.getElementById("txtpassword");
                     var b = document.getElementById("EYE");
                     if (a.type == "password") {
                         a.type = "text";
                         b.src = "https://i.stack.imgur.com/waw4z.png";
                     }
                     else {
                         a.type = "password";
                         b.src = "https://i.stack.imgur.com/Oyk1g.png";
                     }
                 }

    </script >

</head>
<body class="login bg">

    <div class="col-md-12 col-sm-12 col-xs-12">
        <a class="hiddenanchor" id="signup"></a>
        <a class="hiddenanchor" id="signin"></a>

        <div class="login_wrapper">
            <div class="col-md-12 col-sm-12 col-xs-12 animate form login_form " style="background-color: #ffffff; border-radius: 10px; border: 2px solid #516274">
                <div>
                    <h1 style="font-size: 40px; text-align: center; color: #3095da">Invoice<b style="color: #808080">Me</b></h1>
                </div>
                <section class="login_content" style="width: 50%;">
                    <form class="form-horizontal" method="" action="">
                        <h1>Login</h1>
                        <div class="form-group">
                            <div>
                                <label class="title_left">Username</label>
                                <input type="text" id="txtusername" class="form-control" placeholder="Username" required="">
                            </div>
                        </div>
                        <div class="form-group">
                            <label class="title_left">Password</label>

                            <input id="txtpassword" type="password" class="form-control" name="password" placeholder="Password" />
                            <span toggle="#txtpassword" class="fa fa-fw fa-eye field-icon toggle-password" style="width: 3em; font-size: 15px"></span>

                        </div>

                        <div>

                            <div class="pull-left" href="#">

                                <div class="checkbox">
                                    <label style="">
                                        <input type="checkbox" value="" id="chebxRememberme">
                                        <span class="cr"><i class="cr-icon fa fa-check"></i></span>
                                        Remember Me ?
                                    </label>
                                </div>

                            </div>

                            <div class="btn btn-primary " style="width: 100%; margin-top: 15px" onclick="javascript:login();">Log in</div>

                        </div>

                        <div class="clearfix"></div>

                        <div class="separator">
                            <%-- <p class="change_link">New to site?
                  <a href="#signup" class="to_register"> Create Account </a>
                </p>--%>

                            <div class="clearfix"></div>
                            <br>
                        </div>
                    </form>
                </section>
            </div>


        </div>
    </div>
    <!-- Bootstrap -->
    <script src="js/bootstrap/bootstrap.min.js"></script>
    <!-- FastClick -->
    <script src="js/bootstrap/fastclick.js"></script>
    <!-- NProgress -->
    <script src="js/bootstrap/nprogress.js"></script>

    <script src="js/bootbox.min.js"></script>
</body>
</html>
