/* -*- tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
 * This file is part of valacat
 *
 * Copyright (C) 2013 - Marcos Chavarría Teijeiro
 *
 * valacat is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * valacat is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with valacat. If not, see <http://www.gnu.org/licenses/>.
 */

using Gtk;
using ValaCAT.UI;
using ValaCAT.FileProject;
using Gee;

namespace ValaCAT.Application
{
    public class Application : Gtk.Application
    {

        private ArrayList<string> _extensions;
        private ArrayList<FileOpener> file_openers;

        public ArrayList<string> extensions {   get
            {
                _extensions = new ArrayList<string> ();
                foreach (FileOpener fo in file_openers)
                {
                    foreach (string ext in fo.extensions)
                        _extensions.add (ext);
                }
                return _extensions;
            }
        }

        private Application ()
        {
            Object (application_id: "info.aquelando.valacat",
                flags: ApplicationFlags.HANDLES_OPEN);
        }

        construct
        {
            this.file_openers = new ArrayList<FileOpener> ();
            this.add_opener (new ValaCAT.PoFiles.PoFileOpener ());
        }

        public void add_opener (FileOpener o)
        {
            this.file_openers.add (o);
        }

        public void open_file (GLib.File f,  ValaCAT.UI.Window window)
        {
            int index_last_point = f.get_path ().last_index_of_char ('.');
            string extension = f.get_path ().substring (index_last_point + 1);
            foreach (FileOpener o in this.file_openers)
            {
                if (extension in o.extensions)
                {
                    ValaCAT.FileProject.File? file = o.open_file (f.get_path (),null);
                    if (file == null)
                        print ("Error while open file.");
                    else
                        window.add_file (file);
                }
            }
        }

        public override void activate ()
        {
            ValaCAT.UI.Window window = new ValaCAT.UI.Window (this);
            window.show_all ();
            Gtk.main ();
        }

        public override void open (GLib.File[] files, string hint)
        {
            ValaCAT.UI.Window window = new ValaCAT.UI.Window (this);

            foreach (GLib.File f in files)
                this.open_file (f, window);

            ValaCAT.FileProject.Project p = new Project (""); //DEMO
            p.add_file (new ValaCAT.Demo.DemoFile ());
            p.add_file (new ValaCAT.Demo.DemoFile ());

            window.add_project (p);

            window.show_all ();
            Gtk.main ();
        }

        public static int main (string[] args)
        {
            Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.GNOMELOCALEDIR);
            Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
            Intl.textdomain (Config.GETTEXT_PACKAGE);

            var app = new Application ();
            return app.run (args);
        }

    }
}