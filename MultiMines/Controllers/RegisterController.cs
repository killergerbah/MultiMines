using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using WebMatrix.WebData;

namespace MultiMines.Controllers
{
    public class RegisterController : Controller
    {
        //
        // GET: /Register/

        public ActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public ActionResult Create()
        {
            WebSecurity.Logout();
            var username = Request["username"];
            var password = Request["password"];
            var confirmPassword = Request["confirmPassword"];
            if (password != confirmPassword)
            {
                TempData["error"] = "Password inputs did not match.";
                return RedirectToAction("Index");
            }
            else if (WebSecurity.UserExists("username"))
            {
                TempData["error"] = "User already exists.";
                return RedirectToAction("index");
            }
            WebSecurity.CreateUserAndAccount(username, password, null, false);
            WebSecurity.Login(username, password, true);
            return RedirectToAction("Index", "Home");
        }
    }
}
