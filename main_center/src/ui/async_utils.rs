use std::process::Command;
use std::thread;
use glib::MainContext;
use std::cell::RefCell;

/// Run an external command on a background thread and pass its captured stdout to
/// `callback` on the GTK main thread. If the command fails, `None` is passed.
///
/// This utility should be used whenever a synchronous `Command::output()` call
/// would otherwise block the UI thread.
pub fn run_command_async<I, S, F>(program: &str, args: I, callback: F)
where
    I: IntoIterator<Item = S> + Send + 'static,
    S: Into<String> + Send + 'static,
    F: FnOnce(Option<String>) + 'static,
{
    let prog = program.to_string();
    let args_vec: Vec<String> = args.into_iter().map(|s| s.into()).collect();

    // Use a MainContext channel so that the callback runs on the GTK thread
    // without having to be Send.
    let (sender, receiver) = MainContext::channel::<Option<String>>(glib::PRIORITY_DEFAULT);

    let callback_cell = RefCell::new(Some(callback));

    receiver.attach(None, move |out| {
        if let Some(cb) = callback_cell.take() {
            cb(out);
        }
        glib::Continue(false)
    });

    thread::spawn(move || {
        let output = Command::new(&prog)
            .args(&args_vec)
            .output()
            .ok()
            .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string());
        let _ = sender.send(output);
    });
}

/// Like `run_command_async` but only returns whether the command succeeded.
pub fn run_status_async<I, S, F>(program: &str, args: I, callback: F)
where
    I: IntoIterator<Item = S> + Send + 'static,
    S: Into<String> + Send + 'static,
    F: FnOnce(bool) + 'static,
{
    run_command_async(program, args, move |out| callback(out.is_some()));
} 