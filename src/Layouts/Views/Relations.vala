/*
* Copyright (c) 2011-2018 Alecaddd (http://alecaddd.com)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Sequeler.Layouts.Views.Relations : Gtk.Grid {
	public weak Sequeler.Window window { get; construct; }

	public Gtk.ScrolledWindow scroll;
	public Gtk.Label result_message;

	private string _table_name = "";

	public string table_name {
		get { return _table_name; }
		set { _table_name = value; }
	}

	public Relations (Sequeler.Window main_window) {
		Object (
			orientation: Gtk.Orientation.VERTICAL,
			window: main_window
		);
	}

	construct {
		scroll = new Gtk.ScrolledWindow (null, null);
		scroll.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
		scroll.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
		scroll.expand = true;

		var info_bar = new Gtk.Grid ();
		info_bar.get_style_context ().add_class ("library-toolbar");
		info_bar.attach (build_results_msg (), 0, 0, 1, 1);

		attach (scroll, 0, 0, 1, 1);
		attach (info_bar, 0, 1, 1, 1);

		placeholder ();
	}

	public Gtk.Label build_results_msg () {
		result_message = new Gtk.Label (_("No Results Available"));
		result_message.halign = Gtk.Align.START;
		result_message.margin = 7;
		result_message.margin_top = 6;
		result_message.hexpand = true;
		result_message.wrap = true;

		return result_message;
	}

	public void placeholder () {
		var intro = new Granite.Widgets.Welcome (_("Select Table"), _("Select a table from the left sidebar to activate this view."));
		scroll.add (intro);
	}

	public void clear () {
		if (scroll.get_child () != null) {
			scroll.remove (scroll.get_child ());
		}
	}

	public void reset () {
		if (scroll.get_child () != null) {
			scroll.remove (scroll.get_child ());
		}

		result_message.label = _("No Results Available");
		placeholder ();

		scroll.show_all ();
	}

	public void fill (string? table) {
		if (table == null) {
			return;
		}

		if (table == _table_name) {
			return;
		}

		table_name = table;

		var query = (window.main.connection.db_type as DataBaseType).show_table_relations (table);

		var table_relations = get_table_relations (query);

		if (table_relations == null) {
			return;
		}

		var result_data = new Sequeler.Partials.TreeBuilder (table_relations, window);
		result_message.label = table_relations.get_n_rows ().to_string () + _(" Constraints");

		clear ();

		scroll.add (result_data);
		scroll.show_all ();
	}

	private Gda.DataModel? get_table_relations (string query) {
		Gda.DataModel? result = null;
		var error = "";

		var loop = new MainLoop ();
		window.main.connection.init_select_query.begin (query, (obj, res) => {
			try {
				result = window.main.connection.init_select_query.end (res);
			} catch (ThreadError e) {
				error = e.message;
				result = null;
			}
			loop.quit ();
		});

		loop.run ();

		if (error != "") {
			window.main.connection.query_warning (error);
			result_message.label = error;
			return null;
		}

		return result;
	}
}