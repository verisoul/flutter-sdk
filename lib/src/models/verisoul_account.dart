class VerisoulAccount {
  final String id;
  final String? email;
  final Map<String, dynamic>? metadata;

  VerisoulAccount({required this.id, this.email, this.metadata});

  Map<String, dynamic> toMap() => {
        'id': id,
        if (email != null) 'email': email,
        if (metadata != null) 'metadata': metadata,
      };
}
