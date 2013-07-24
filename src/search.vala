
using Gkt;
using ValaCAT.FileProject;
using ValaCAT.Iterators;

namespace ValaCAT.UI
{

	/**
	 *
	 */
	[GtkTemplate (ui = "/info/aquelando/valacat/searchdialog.ui")]
	public class SearchDialog : Gtk.Dialog
	{
		[GtkChild]
		private Gtk.Entry entry_search;
		[GtkChild]
		private Gtk.Entry entry_replace;
		[GtkChild]
		private Gtk.CheckButton checkbutton_translated_messages;
		[GtkChild]
		private Gtk.CheckButton checkbutton_fuzzy_messages;
		[GtkChild]
		private Gtk.CheckButton checkbutton_untranslated_messages;
		[GtkChild]
		private Gtk.CheckButton checkbutton_translated;
		[GtkChild]
		private Gtk.CheckButton checkbutton_original;
		[GtkChild]
		private Gtk.CheckButton checkbutton_search_project;
		[GtkChild]
		private Gtk.CheckButton checkbutton_wrap_around;

		private ValaCAT.UI.Window window;

		[GtkCallback]
		private void search_clicked (Button b)
		{
			ini_search(false,true);
		}

		[GtkCallback]
		private void replace_clicked (Button b)
		{
			ini_search(true,true);
		}

		[GtkCallback]
		private void replace_all_clicked (Button b)
		{
			ini_search(true,false);
		}

		[GtkCallback]
		private void close_search_dialog (Widget w)
		{
			this.visible = false;
		}

		private void ini_search (bool replace, bool stop)
		{

			if (checkbutton_search_project.active)
			{
				this.window.active_search = new ProjectSearch();
			}
			else
			{
				this.window.active_search = new FileSearch (this.window.get_active_tab(),
															checkbutton_translated_messages.active,
															checkbutton_untranslated_messages.active,
															checkbutton_fuzzy_messages.active,
															checkbutton_translated.active,
															checkbutton_original.active,
															replace,
															stop,
															entry_search.get_text (),
															entry_replace.get_text ());
			}

			this.window.active_search.next_item();
		}

	}
}


namespace ValaCAT.Search
{
	public abstract class Search : Object
	{
		public abstract string get_search_text ();

		public abstract string get_replace_text ();

		public abstract void next_item ();

		public abstract void previous_item ();

		public abstract void replace ();
	}


	public class ProjectSearch : Search
	{
	}


	public class FileSearch : Search
	{
		public FileSearch (FileTab tab,
						 bool translated,
						 bool untranslated,
						 bool fuzzy,
						 bool original,
						 bool translation,
						 bool replace,
						 bool stop,
						 string search_text,
						 string replace_text)
		{
			ArrayList<IteratorFilter<Message>> filters;
			if (translated)
				file_iterators.add(new TranslatedFilter ());

			if (untranslated)
				file_iterators.add(new UntranslatedFilter ());

			if (fuzzy)
				file_iterators.add(new FuzzyFilter ());

			IteratorFilter<Message> filter_messages;

			if(file_iterators.size == 0)
				filter_messages = null;
			else if (file_iterators.size == 1)
				filter_messages = filters.get(0);
			else
				filter_messages = new ORFilter (filters);

			IteratorFilter<MessageMark> filter_marks;

			if(original && translation)
				filter_marks = new AllMessageMarkFilter();
			else if (original && ! translation)
				filter_marks = new OriginalFilter();
			else if (! original && translation)
				filter_marks = new TransationFilter();
			else
				filter_marks = null;


			this.filetab = tab;
			this.file_iterator = new FileIterator.with_filter(tab.file,filter_messages);
			this.message_iterator = new MessageIterator(null, search_text, filter_marks);
			this.replace = replace;
			this.stop = stop;
			this.replace_text = replace_text;
		}


		public override void next_item ()
		{
			MessageMark mm = null;

			while (mm == null)
			{
				if (this.message_iterator.message == null || this.message_iterator.next() == null)
				{
					Message message = this.file_iterator.next();
					this.message_iterator.set_element(message);
				}

				mm = this.message_iterator.next();
			}

			this.highlight_search(mm);
		}

		public override void previous_item ()
		{
			MessageMark mm = null;

			while (mm == null)
			{
				if (this.message_iterator.message == null || this.message_iterator.previous() == null)
				{
					this.message_iterator.set_element(this.file_iterator.previous());
					this.message_iterator.last();
				}

				mm = this.message_iterator.previous();
			}

			this.highlight_search(mm);
		}

		private void highlight_search (MessageMark mm)
		{
			foreach (MessageListRow row in this.filetab.message_list.messages_list_box.get_children())
			{
				if (row.message = mm.message)
				{
					this.filetab.message_list.messages_list_box.select_row(row);
					MessageEditorTab editor_tab = this.filetab.message_editor.plurals_notebook.get_nth_page(mm.plural_number) as MessageEditorTab;

					if (mm.is_original)
					{
						editor_tab.disable_filters_original_string();
						editor_tab.add_filter_original_string(new MessageMarkFilter (mm));
					}
					else
					{
						editor_tab.disable_filters_translation_string();
						editor_tab.add_filter_translation_string(new MessageMarkFilter (mm));
					}
				}
			}
		}

		public void replace ()
		{
			MessageMark mm = this.message_iterator.get_current_element();
			replace_intern(mm);
		}

		private void replace_intern (MessageMark mm)
		{
			if (mm.is_original)
			{
				return;
			}
			else
			{
				string original_string = mm.message.get_translation(mm.plural_number);
				mm.message.set_translation(mm.plural_number,
					original_string.substring (0,mm.index) + this.replace_text +
					original_string.substring (mm.index + mm.length));
			}
		}
	}

	public class MessageMarkFilter : Filter
	{

		private int index;
		private int length;

		public MessageMarkFilter (MessageMark mm)
		{
			this.index = mm.index;
			this.length = mm.length;
		}

		public override string filter (string input_string)
		{
			string ini_string = input_string.substring (0, index-1);
			string highlighted_string = input_string.substring (index,length);
			string end_string = input_string.substring (index+length);
			return ini_string + "<span background=\"red\">" + highlighted_string + "</span>" + end_string;
		}

	}
}