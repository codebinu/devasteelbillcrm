using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Text;
using System.Web.Services;
using System.Data;
using commonfunction;
using Newtonsoft.Json;

public partial class web_inventory_PriceListCreator : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        insertOldOutstanding();
    }

    private void insertOldOutstanding()
    {
        mySqlConnection db = new mySqlConnection();
        db.BeginTransaction();
        try
        {
            // GET ITEMS FROM ITEM_BRANCH_STOCK
            var dt = db.SelectQueryForTransaction("SELECT itb.itbs_id,itb.itm_class_one,itb.itm_class_two,itb.itm_class_three FROM tbl_itembranch_stock itb");
            
            // LOOP ITEMS AND INSERT
            if (dt.Rows.Count > 0)
            {
                var count = dt.Rows.Count;
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    db.ExecuteQueryForTransaction("INSERT INTO tbl_item_pricelist (itbs_id,tpm_id,tip_price,tip_last_updated_date) VALUES ('" + dt.Rows[i]["itbs_id"].ToString() + "','1','" + dt.Rows[i]["itm_class_one"].ToString() + "','2019-03-24 17:48:00')");
                    db.ExecuteQueryForTransaction("INSERT INTO tbl_item_pricelist (itbs_id,tpm_id,tip_price,tip_last_updated_date) VALUES ('" + dt.Rows[i]["itbs_id"].ToString() + "','2','" + dt.Rows[i]["itm_class_two"].ToString() + "','2019-03-24 17:48:00')");
                    db.ExecuteQueryForTransaction("INSERT INTO tbl_item_pricelist (itbs_id,tpm_id,tip_price,tip_last_updated_date) VALUES ('" + dt.Rows[i]["itbs_id"].ToString() + "','3','" + dt.Rows[i]["itm_class_three"].ToString() + "','2019-03-24 17:48:00')");
                }

            }

            db.CommitTransaction();
        }
        catch (Exception e)
        {
            db.RollBackTransaction();
            throw e;
        }

    }
}