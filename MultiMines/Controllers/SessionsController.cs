using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using WebMatrix.WebData;

namespace MultiMines.Controllers
{
    public class SessionsController : Controller
    {
        [HttpPost]
        public ActionResult Create()
        {
            var username = Request["username"];
            var password = Request["password"];
            if (!WebSecurity.Login(username, password, false))
            {
                TempData["error"] = "Invalid credentials.";
            }
            return RedirectToAction("index", "home");
        }

        public ActionResult Delete()
        {
            WebSecurity.Logout();
            return RedirectToAction("index", "home");
        }
    }
}
