/// Ancien module « enhanced » fusionné dans [validation_helper.dart].
///
/// Import préféré :
/// ```dart
/// import 'package:easyconnect/utils/validation_helper.dart';
/// ```
@Deprecated(
  'Importer validation_helper.dart et utiliser ValidationHelper '
  '(validateurs + snackbars unifiés).',
)
library;

import 'validation_helper.dart';

export 'validation_helper.dart';

@Deprecated('Utiliser ValidationHelper')
typedef ValidationHelperEnhanced = ValidationHelper;
