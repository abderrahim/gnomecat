/* -*- tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
 * This file is part of GNOMECAT
 *
 * Copyright (C) 2013 - Marcos Chavarría Teijeiro
 *
 * GNOMECAT is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * GNOMECAT is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with GNOMECAT. If not, see <http://www.gnu.org/licenses/>.
 */

using GNOMECAT;
using GNOMECAT.FileProject;
using GNOMECAT.UI;
using GNOMECAT.Search;
using GNOMECAT.Navigator;
using GNOMECAT.Iterators;
using Gee;

namespace GNOMECAT.UI {

    [GtkTemplate (ui = "/org/gnome/gnomecat/ui/editpanel.ui")]
    public class EditPanel : Gtk.Box, GNOMECAT.UI.Panel
    {

        [GtkChild]
        public Gtk.Box box;

        public MessageListWidget message_list;
        public SearchBar searchbar;
        public HintPanelWidget hints_panel;

        public GNOMECAT.FileProject.File? _file;
        public GNOMECAT.FileProject.File? file
        {
            get
            {
                return _file;
            }
            set
            {
                _file = value;
                message_list.file = value;

                navigator_all = new FileNavigator (this, new TransparentFilter<Message> ());
                navigator_fuzzy = new FileNavigator (this, new FuzzyFilter ());
                navigator_translated = new FileNavigator (this, new TranslatedFilter ());
                navigator_untranslated = new FileNavigator (this, new UntranslatedFilter ());
            }

        }

        private GNOMECAT.Navigator.FileNavigator navigator_fuzzy;
        private GNOMECAT.Navigator.FileNavigator navigator_translated;
        private GNOMECAT.Navigator.FileNavigator navigator_untranslated;
        private GNOMECAT.Navigator.FileNavigator navigator_all;
        private GNOMECAT.Search.Search active_search;


        private ArrayList<ChangedMessageSensible> change_messages_sensible;

        public EditPanel ()
        {

            //FIXME: move the next block to ui file
            message_list = new MessageListWidget ();
            hints_panel = new HintPanelWidget();
            searchbar = new SearchBar();
            message_list.message_selected.connect (on_message_selected);
            searchbar.search_changed.connect (on_search_changed);
            this.pack_start(searchbar, false);;
            box.pack_start (message_list, true);
            box.pack_start (hints_panel, false);


            this._file.file_changed.connect (() =>
                {
                    (GNOMECAT.Application.get_default ().get_active_window () as GNOMECAT.UI.Window)
                        .file_changed (file);
                });
        }


        public void on_message_selected (Message m)
        {
            hints_panel.message = m;
            if (navigator_all != null) navigator_all.message = m;
            if (navigator_translated != null) navigator_translated.message = m;
            if (navigator_fuzzy != null) navigator_fuzzy.message = m;
            if (navigator_untranslated != null) navigator_untranslated.message = m;
        }

        public void on_search_changed (SearchInfo search_info)
        {
            if (search_info != null)
            {
                this.active_search = new GNOMECAT.Search.Search(this, search_info);
            }
            else
            {
                this.active_search.deselect();
                this.active_search = null;
            }
        }

        public void on_edit_undo (GNOMECAT.UI.Window window)
        {
            MessageEditorTab tab;
            if ((tab = message_list.get_active_editor_tab ()) != null)
                tab.undo ();
        }

        public void on_edit_redo (GNOMECAT.UI.Window window)
        {
            MessageEditorTab tab;
            if ((tab = message_list.get_active_editor_tab ()) != null)
                tab.redo ();
        }

        public void on_go_next (GNOMECAT.UI.Window window)
        {
            navigator_all.next ();
        }

        public void on_go_previous (GNOMECAT.UI.Window window)
        {
            navigator_all.previous ();
        }

        public void on_go_next_fuzzy (GNOMECAT.UI.Window window)
        {
            navigator_fuzzy.next ();
        }

        public void on_go_previous_fuzzy (GNOMECAT.UI.Window window)
        {
            navigator_fuzzy.previous ();
        }

        public void on_go_next_translated (GNOMECAT.UI.Window window)
        {
            navigator_translated.next ();
        }

        public void on_go_previous_translated (GNOMECAT.UI.Window window)
        {
            navigator_translated.previous ();
        }

        public void on_go_next_untranslated (GNOMECAT.UI.Window window)
        {
            navigator_untranslated.next ();
        }

        public void on_go_previous_untranslated (GNOMECAT.UI.Window window)
        {
            navigator_untranslated.previous ();
        }

        public void on_search_next (GNOMECAT.UI.Window window)
        {
            if (active_search != null) active_search.next ();
        }

        public void on_search_previous (GNOMECAT.UI.Window window)
        {
            if (active_search != null) active_search.previous ();
        }

        public void on_search_replace (GNOMECAT.UI.Window window)
        {
            if (active_search != null) active_search.replace ();
        }

        public void on_back (GNOMECAT.UI.Window window)
        {
            window.window_panels.page = WindowStatus.OPENEDFILES;
            window.headerbar.set_openedfiles_toolbar();
        }

        public void select (GNOMECAT.SelectLevel level,
            GNOMECAT.FileProject.MessageFragment? fragment)
        {
            message_list.select (level, fragment);
        }

        public void deselect (GNOMECAT.SelectLevel level,
            GNOMECAT.FileProject.MessageFragment? fragment)
        {
            message_list.deselect (level, fragment);
        }
    }
}