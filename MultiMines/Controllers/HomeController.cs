using MultiMines.GameLogic;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace MultiMines.Controllers
{
    public class HomeController : Controller
    {
        //
        // GET: /Home/

        public ActionResult Index()
        {
            return View();
        }

        public JsonResult RandomBoard()
        {
            var maxWidth = 50;
            var maxHeight = 50;
            var rand = new Random();
            var randomWidth = rand.Next(maxWidth) + 1;
            var randomHeight = rand.Next(maxHeight) + 1;
            var randomNumMines = rand.Next(randomWidth * randomHeight) + 1;
            return Json(
                JsonConvert.SerializeObject(new MinesweeperBoard(randomWidth, randomHeight, 100)),
                JsonRequestBehavior.AllowGet);
        }
    }
}
