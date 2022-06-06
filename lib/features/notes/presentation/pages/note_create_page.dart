import 'package:dairy_app/core/pages/home_page.dart';
import 'package:dairy_app/core/widgets/glassmorphism_cover.dart';
import 'package:dairy_app/features/notes/presentation/bloc/notes/notes_bloc.dart';
import 'package:dairy_app/features/notes/presentation/pages/note_read_only_page.dart';
import 'package:dairy_app/features/notes/presentation/widgets/note_title_input_field.dart';
import 'package:dairy_app/features/notes/presentation/widgets/rich_text_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

class NoteCreatePage extends StatefulWidget {
  // display page growing animation
  static String get routeThroughHome => '/note-create-though-home';

  // display fade transition animaiton
  static String get routeThroughNoteReadOnly =>
      '/note-create-through-note-read-only';

  const NoteCreatePage({Key? key}) : super(key: key);

  @override
  State<NoteCreatePage> createState() => _NoteCreatePageState();
}

class _NoteCreatePageState extends State<NoteCreatePage> {
  late bool _isInitialized = false;
  late final NotesBloc notesBloc;

  @override
  void didChangeDependencies() {
    if (!_isInitialized) {
      notesBloc = BlocProvider.of<NotesBloc>(context);

      // it is definetely a new note if we reached this page and the state is still NoteDummyState
      if (notesBloc.state is NoteDummyState) {
        notesBloc.add(const InitializeNote());
      }
      _isInitialized = true;
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: glassAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(225, 234, 94, 141),
          image: DecorationImage(
            image: AssetImage(
              "assets/images/digital-art-neon-bubbles.jpg",
            ),
            fit: BoxFit.cover,
            alignment: Alignment(0.725, 0.1),
          ),
        ),

        // TODO: this creates new instance of appbar everytime, find a workaround for this
        padding: EdgeInsets.only(
          top: AppBar().preferredSize.height +
              MediaQuery.of(context).padding.top +
              10.0,
          left: 10.0,
          right: 10.0,
          // bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: BlocListener<NotesBloc, NotesState>(
          bloc: notesBloc,
          listener: (context, state) {
            if (state is NoteFetchFailed) {
              _showToast("feiled to fetch note");
            } else if (state is NotesSavingFailed) {
              _showToast("Failed to save note");
            } else if (state is NoteSavedSuccesfully) {
              _showToast(state.newNote!
                  ? "Note saved successfully"
                  : "Note updated successfully");
              _routeToHome();
            }
          },
          child: Column(
            children: [
              BlocBuilder<NotesBloc, NotesState>(
                bloc: notesBloc,
                buildWhen: (previousState, state) {
                  return previousState.title != state.title;
                },
                builder: (context, state) {
                  void _onTitleChanged(String title) {
                    notesBloc.add(UpdateNote(title: title));
                  }

                  if (!state.safe) {
                    return NoteTitleInputField(
                        initialValue: "", onTitleChanged: _onTitleChanged);
                  }
                  return NoteTitleInputField(
                    initialValue: state.title!,
                    onTitleChanged: _onTitleChanged,
                  );
                },
              ),
              const SizedBox(height: 10),
              BlocBuilder<NotesBloc, NotesState>(
                bloc: notesBloc,
                buildWhen: (previousState, state) {
                  return previousState is NoteDummyState;
                },
                builder: (context, state) {
                  return RichTextEditor(
                    controller: state.controller,
                  );
                },
              ),
              SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom,
              )
            ],
          ),
        ),
      ),
    );
  }

  void _routeToHome() {
    notesBloc.add(RefreshNote());
    Navigator.of(context).pop();
  }

  AppBar glassAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: BlocBuilder<NotesBloc, NotesState>(
        bloc: notesBloc,
        builder: (context, state) {
          // We want to show this button when notes in edited
          if (state.safe) {
            return IconButton(
              icon: const Icon(
                Icons.close,
                size: 25,
              ),
              onPressed: () async {
                bool? result = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("You have unsaved changes"),
                        actions: [
                          TextButton(
                            child: const Text('LEAVE'),
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            style: ElevatedButton.styleFrom(
                              primary: Colors.purple,
                              onPrimary: Colors.purple[200],
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(16),
                                ),
                              ),
                              elevation: 4,
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: const Text("STAY",
                                style: TextStyle(color: Colors.white)),
                          )
                        ],
                      );
                    });
                if (result != null && result == true) {
                  _routeToHome();
                }
              },
            );
          }
          return Container();
        },
      ),
      backgroundColor: Colors.transparent,
      actions: [
        BlocBuilder<NotesBloc, NotesState>(
          bloc: notesBloc,
          builder: (context, state) {
            if (state.safe) {
              return Padding(
                padding: const EdgeInsets.only(right: 13.0),
                child: IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () => notesBloc.add(SaveNote()),
                ),
              );
            }

            if (state is NoteSaveLoading) {
              return Padding(
                padding: const EdgeInsets.only(right: 13.0),
                child: IconButton(
                  icon: const SizedBox(
                    height: 25,
                    width: 25,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () => notesBloc.add(SaveNote()),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
        BlocBuilder<NotesBloc, NotesState>(
          bloc: notesBloc,
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.only(right: 13.0),
              child: IconButton(
                icon: const Icon(Icons.calendar_month_outlined),
                onPressed: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: state.createdAt!,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(3000),
                  );

                  final TimeOfDay? timeOfDay = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(state.createdAt!),
                    initialEntryMode: TimePickerEntryMode.dial,
                  );

                  final createdAt = DateTime(pickedDate!.year, pickedDate.month,
                      pickedDate.day, timeOfDay!.hour, timeOfDay.minute);
                  notesBloc.add(UpdateNote(createdAt: createdAt));
                },
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 13.0),
          child: IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () => Navigator.of(context)
                .popAndPushNamed(NotesReadOnlyPage.routeThoughNotesCreate),
          ),
        ),
      ],
      flexibleSpace: GlassMorphismCover(
        borderRadius: BorderRadius.circular(0.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.2),
              ],
              begin: AlignmentDirectional.topCenter,
              end: AlignmentDirectional.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.pinkAccent,
        textColor: Colors.white,
        fontSize: 16.0);
  }
}