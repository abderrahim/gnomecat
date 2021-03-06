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

using Gee;
using Json;

namespace GNOMECAT.Languages
{
    public class PluralForm : GLib.Object
    {

        public int id {get; private set;}
        public int number_of_plurals {get; private set;}
        public string expression {get; private set;}
        public HashMap<int, string> plural_tags {get; private set;}

        public static HashMap<int,PluralForm> plural_forms {get; private set;}


        /**
         * Constructor for plural forms.
         *
         * @param id Id of this plural form.
         * @param number_of_plurals Number of plurals
         * @param expression Expression containig the number of
         *  plurals and the C expressions to distinguish among
         *  plural forms.
         * @param plural_tags Distinguishable names for each plural form.
         */
        public PluralForm   (int id,
                            int number_of_plurals,
                            string expression,
                            HashMap<int, string> plural_tags)
        {
            this.id = id;
            this.number_of_plurals = number_of_plurals;
            this.expression = expression;
            this.plural_tags = plural_tags;
        }


        /**
         * Method that return the tag for a plural form.
         *
         * There are languages that has different plural forms for
         * different numbers these tags try to provide a more readable
         * form to distinguish among this form.
         */
        public string get_plural_form_tag (int plural)
        {
            return plural_tags.get (plural);
        }

        /**
         * Method that returns the instance corresponding the
         * id number provided as parameter.
         */
        public static PluralForm get_plural_from_id (int id)
        {
            return plural_forms.get (id);
        }

        static construct
        {
            plural_forms = new HashMap<int, PluralForm> ();

            try{

                var parser = new Json.Parser ();
                File file = File.new_for_uri ("resource:///org/gnome/gnomecat/plurals.json");
                InputStream stream = file.read ();
                parser.load_from_stream (stream);

                var root_object = parser.get_root ().get_object ();

                foreach (var form in root_object.get_array_member ("forms").get_elements ())
                {
                    var form_object = form.get_object ();

                    int id = int.parse (form_object.get_int_member ("id").to_string ());
                    string expression = form_object.get_string_member ("expression");
                    int number_of_plurals = int.parse (form_object.get_int_member ("number_of_plurals").to_string ());
                    HashMap<int,string> tags = new HashMap<int,string> ();

                    foreach (var tag in form_object.get_array_member ("tags").get_elements ())
                    {
                        var tag_object = tag.get_object ();
                        tags.set (int.parse (tag_object.get_int_member ("number").to_string ()), tag_object.get_string_member ("tag"));
                    }

                    plural_forms.set (id, new PluralForm (id, number_of_plurals, expression, tags));
                }

            } catch (Error e) {
                stderr.printf ("ERROR: %s\n", e.message);
            }
        }
    }


    public class Language : GLib.Object
    {
        public static HashMap<string,Language> languages {get; private set;}

        public string name {get; private set;}
        public string code {get; private set;}
        public PluralForm default_plural_form {get; set;}
        public string default_team_email {get; private set;}

        public int number_of_plurals
        {
            get
            {
                if (default_plural_form == null)
                    return 1;
                return default_plural_form.number_of_plurals;
            }
        }


        public static Language get_language_by_code (string code)
        {
            return languages.get (code);
        }

        public Language (string code, string name, int pluralform, string email)
        {
            this.name = name;
            this.code = code;
            this.default_plural_form = pluralform == -1 ? null :
                PluralForm.get_plural_from_id (pluralform);
            this.default_team_email = email;
        }


        public string? get_plural_form_tag (int plural)
        {
            if (default_plural_form == null)
                return null;
            return this.default_plural_form.get_plural_form_tag (plural);
        }

        static construct
        {
            languages = new HashMap<string, Language> ();

            try {
                var parser = new Json.Parser ();
                File file = File.new_for_uri ("resource:///org/gnome/gnomecat/languages.json");
                InputStream stream = file.read ();
                parser.load_from_stream (stream);

                var root_object = parser.get_root ().get_object ();

                foreach (var lang in root_object.get_array_member ("languages").get_elements ())
                {
                    var lang_object = lang.get_object ();

                    string name = lang_object.get_string_member ("name");
                    string code = lang_object.get_string_member ("code");
                    int plural_form_id = int.parse (lang_object.get_int_member ("pluralform").to_string ());
                    string email = lang_object.get_string_member ("default-team-email");

                    languages.set (code, new Language (code, name, plural_form_id, email));

                }
            } catch (Error e) {
                //TODO: print some error info.
                stderr.printf ("ERROR: %s\n",e.message);
            }
        }
    }
}