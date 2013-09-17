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

using ValaCAT.FileProject;
using Gee;
using ValaCAT.Iterators;
using ValaCAT.UI;

namespace ValaCAT.Navigator
{
	public class Navigator : Object, ChangedMessageSensible
	{
		public ValaCAT.FileProject.File file {get {return filetab.file;}}
		private FileIterator iterator;
		private IteratorFilter<Message> filter;
		private ValaCAT.UI.FileTab filetab;


		public Navigator (FileTab ft, IteratorFilter<Message> filter)
		{
			filetab = ft;
			iterator = new FileIterator (ft.file, filter);
			this.filter = filter;
		}

		public void next_item ()
		{
			Message? m = iterator.next ();

			if (m == null)
			{
				iterator.first ();
				m = iterator.get_current_element ();
			}

			if (m == null)
				return; //FIXME

			MessageListRow? row = filetab.message_list.find_row_by_message (m);
			filetab.message_list.select_row (row);
		}

		public void previous_item ()
		{
			Message? m = iterator.previous ();

			if (m == null)
			{
				iterator.last ();
				m = iterator.get_current_element ();
			}

			if (m == null)
				return; //FIXME

			MessageListRow? row = filetab.message_list.find_row_by_message (m);
			filetab.message_list.select_row (row);
		}

		public void set_message (Message m)
		{
			if (filter.check (m))
			{
				set_message_intern (m);
			}
			else
			{
				Gee.ArrayList<Message> msgs = this.file.messages;
				int index;
				for (index = msgs.index_of (m); index >= 0 && ! filter.check (msgs.get (index)); index--);

				if (index == -1)
					iterator.first ();
				else
					set_message_intern (msgs.get (index));
			}
		}

		private void set_message_intern (Message m)
		{
			Message? current_message = null;
			iterator.first ();
			do
			{
				current_message = this.iterator.next ();
			}
			while (current_message != m && current_message != null);

			if (current_message == null)
			{
				print ("ERROR!!"); //TODO
			}
		}

	}
}