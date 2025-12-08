import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
	const HomeScreen({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Legacy Capsule'),
				centerTitle: true,
			),
			body: const Center(
				child: Text(
					'Welcome to Legacy Capsule',
					style: TextStyle(fontSize: 20),
				),
			),
		);
	}
}
