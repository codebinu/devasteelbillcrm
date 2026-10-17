<%@ Page Language="C#" AutoEventWireup="true" CodeFile="ExportToXML.aspx.cs" Inherits="ExportToXML" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <script src="js/jquery-2.0.3.js"></script>
    <script>

        function download_xml() {

            $.ajax({
                url: 'http://localhost:5140/ExportToXML.aspx/BuildXmlDocument',
                method: 'GET',                
                xhrFields: {
                    responseType: 'blob'
                },
                success: function (data) {
                    var a = document.createElement('a');
                    var url = window.URL.createObjectURL(data);
                    a.href = url;
                    a.download = 'myfile.pdf';
                    a.click();
                    window.URL.revokeObjectURL(url);
                }
            });
        }

    </script>
</head>
<body>
    <form id="form1" >
        <div>
            <button type="button" id="GetFile" onclick="download_xml();">Get File!</button>
        </div>
    </form>
</body>
</html>
