import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:tfg_03/services/services.dart';
import 'package:tfg_03/themes/app_theme.dart';
import 'package:tfg_03/widgets/widgets.dart';
import 'package:tfg_03/providers/providers.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final fireBaseService = Provider.of<FireBaseService>(context);

    return FutureBuilder(
      future: getUserData(authService.readUId()),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (!snapshot.hasData) return Container();

        final user = snapshot.data;
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
                create: (_) => UserProvider(user['name'], user['picture']))
          ],
          child: Scaffold(
            body: const Stack(
              children: [
                BackGround(),

                //* Seleccionar foto con cámara
                Positioned(
                  top: 280,
                  left: 100,
                  child: _CameraButton(),
                ),

                //* Seleccionar imagen de la galería
                Positioned(
                  top: 280,
                  right: 100,
                  child: _GalleryButton(),
                ),
                _Profile()
              ],
            ),

            //*Botón de guardar
            floatingActionButton: _SaveButton(
                fireBaseService: fireBaseService, authService: authService),
          ),
        );
      },
    );
  }
}

class _GalleryButton extends StatelessWidget {
  const _GalleryButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return IconButton(
        onPressed: () async {
          final picker = ImagePicker();

          final XFile? pickedFile = await picker.pickImage(
              source: ImageSource.gallery, imageQuality: 100);

          if (pickedFile == null) {
            print('No seleccionó nada');
            return;
          }

          print('Tenemos una imagen ${pickedFile.path}');

          userProvider.image = File(pickedFile.path);
          print(userProvider.image);
          userProvider.notifyListener();
        },
        icon: const Icon(
          Icons.photo_outlined,
          color: Colors.grey,
        ));
  }
}

class _CameraButton extends StatelessWidget {
  const _CameraButton({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return IconButton(
        onPressed: () async {
          final picker = ImagePicker();

          final XFile? pickedFile = await picker.pickImage(
              source: ImageSource.camera, imageQuality: 100);

          if (pickedFile == null) {
            print('No seleccionó nada');
            return;
          }

          print('Tenemos una imagen ${pickedFile.path}');

          userProvider.image = File(pickedFile.path);
          print(userProvider.image);
          userProvider.notifyListener();
        },
        icon: const Icon(
          Icons.camera_alt_outlined,
          color: Colors.grey,
        ));
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.fireBaseService,
    required this.authService,
  });

  final FireBaseService fireBaseService;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return FloatingActionButton(
      backgroundColor: const Color.fromARGB(255, 28, 29, 59),
      onPressed: () async {
        if (!userProvider.isvalidform()) return;

        uploadImage(userProvider.image)
            .then((url) => userProvider.pictureUrl = url);
        print('URL ${uploadImage(userProvider.image)}');
        print(userProvider.pictureUrl);
        print(userProvider.name);
        await fireBaseService.updateUser(
            authService.readUId(), userProvider.name, userProvider.getPicture);
      },
      child: const Icon(
        Icons.save_outlined,
        color: AppTheme.secondaryColor,
      ),
    );
  }
}

class _Profile extends StatelessWidget {
  const _Profile();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final authService = Provider.of<AuthService>(context);
    print('IMAGEN: ${userProvider.image}');
    return FutureBuilder(
      future: getUserData(authService.readUId()),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) return Container();

        final user = snapshot.data;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 100,
            ),
            if (userProvider.image != null)
              CircleAvatar(
                  maxRadius: 100,
                  backgroundImage: FileImage(userProvider.image!)),
            if (userProvider.image == null)
              CircleAvatar(
                maxRadius: 100,
                backgroundImage: NetworkImage(user['picture']),
              ),
            const SizedBox(
              height: 40,
            ),
            _Form(user: user),
            Expanded(child: Container())
          ],
        );
      },
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.user,
  });

  final user;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Form(
          key: userProvider.formkey,
          child: TextForm(
            validator: (value) {
              if (value == null) return 'Campo obiglatorio';
              if (value.length < 3) return 'tiene que contener más de 3 letras';
              return null;
            },
            onChange: (value) => userProvider.name = value,
            initialValue: user['name'],
            textAlign: TextAlign.center,
          )),
    );
  }
}