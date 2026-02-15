using Gtk;

public class Dino.Ui.ViewModel.GeneralPreferencesPage : Object {
    public bool send_typing { get; set; }
    public bool send_marker { get; set; }
    public bool notifications { get; set; }
    public bool convert_emojis { get; set; }
    public bool run_in_background { get; set; }
    public bool autostart { get; set; }
}

[GtkTemplate (ui = "/im/dino/Dino/preferences_window/general_preferences_page.ui")]
public class Dino.Ui.GeneralPreferencesPage : Adw.PreferencesPage {
    [GtkChild] private unowned Adw.SwitchRow typing_row;
    [GtkChild] private unowned Adw.SwitchRow marker_row;
    [GtkChild] private unowned Adw.SwitchRow notification_row;
    [GtkChild] private unowned Adw.SwitchRow emoji_row;
    [GtkChild] private unowned Adw.SwitchRow run_in_background_row;
    [GtkChild] private unowned Adw.SwitchRow autostart_row;
    [GtkChild] public unowned Button request_background_portal_button;

    public ViewModel.GeneralPreferencesPage model { get; set; default = new ViewModel.GeneralPreferencesPage(); }
    private Binding[] model_bindings = new Binding[0];
    private Xdp.Portal portal = new Xdp.Portal();

    construct {
        this.notify["model"].connect(on_model_changed);
        request_background_portal_button.clicked.connect(() => {
            request_background_portal();
        });
    }

    private void on_model_changed() {
        foreach (Binding binding in model_bindings) {
            binding.unbind();
        }
        if (model != null) {
            model_bindings = new Binding[] {
                model.bind_property("send-typing", typing_row, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL),
                model.bind_property("send-marker", marker_row, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL),
                model.bind_property("notifications", notification_row, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL),
                model.bind_property("convert-emojis", emoji_row, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL),
                model.bind_property("run-in-background", run_in_background_row, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL),
                model.bind_property("autostart", autostart_row, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL),
            };
        } else {
            model_bindings = new Binding[0];
        }
    }

    private void request_background_portal() {
        Xdp.Parent parent = Xdp.parent_new_gtk ((Gtk.Window) get_native ());

        Xdp.BackgroundFlags flags = Xdp.BackgroundFlags.NONE;
        if (autostart_row.active) {
            flags |= Xdp.BackgroundFlags.AUTOSTART;
        }

        GLib.GenericArray<weak string> commands = new GLib.GenericArray<weak string>();
        commands.add ("dino --gapplication-service");

        portal.request_background.begin (
            parent,
            "Allow Dino to continue receive messages and calls",
            commands,
            flags,
            null,
            callback
        );
    }

    private void callback (GLib.Object? obj, GLib.AsyncResult res) {
        try {
            bool? success;
            //result_label.visible = true;
            success = portal.request_background.end (res); // Receive if the request was successful or not

            if (success) {
                warning ("Request successful");
                //result_label.label = "Request successful";
                //result_label.add_css_class ("success");
            }
            else {
                warning ("Request failed");
                //result_label.label = "Request failed";
                //result_label.add_css_class ("warning");
            }

            if (success == null) {
                critical ("Background portal cancelled");
                //result_label.label = "Background portal cancelled";
                //result_label.add_css_class ("warning");
                return;
            }
        }
        catch (Error e) {
            critical (e.message); // Handle error
            //result_label.label = e.message;
            //result_label.add_css_class ("error");
        }
    }
}
