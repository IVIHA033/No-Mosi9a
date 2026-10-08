import 'package:flutter/foundation.dart';

/// Notices for the native components bundled in the APK (Flutter packages
/// register their own licenses automatically).
Stream<LicenseEntry> thirdPartyLicenses() async* {
  yield const LicenseEntryWithLineBreaks(
    ['DPDFNet speech enhancement models (Ceva)'],
    'DPDFNet: Boosting DeepFilterNet2 via Dual-Path RNN.\n'
    'Models from https://huggingface.co/Ceva-IP/DPDFNet, used unmodified.\n'
    'Licensed under the Apache License, Version 2.0.\n\n$_apache2',
  );
  yield const LicenseEntryWithLineBreaks(
    ['Silero VAD speech detector'],
    'Model from https://github.com/snakers4/silero-vad, used unmodified.\n'
    'Copyright (c) 2020-present Silero Team\n\n$_mit',
  );
  yield const LicenseEntryWithLineBreaks(
    ['ONNX Runtime'],
    'Copyright (c) Microsoft Corporation\n\n$_mit',
  );
  yield const LicenseEntryWithLineBreaks(
    ['Shizuku API'],
    'Copyright (c) RikkaApps\nLicensed under the Apache License, Version 2.0.\n\n$_apache2',
  );
  yield const LicenseEntryWithLineBreaks(
    ['HiddenApiBypass'],
    'Copyright (c) LSPosed\nLicensed under the Apache License, Version 2.0.\n\n$_apache2',
  );
  yield const LicenseEntryWithLineBreaks(
    ['KISS FFT (Kotlin port)'],
    'Copyright (c) 2003-2010, Mark Borgerding. All rights reserved.\n\n'
    'Redistribution and use in source and binary forms, with or without modification, are '
    'permitted provided that the following conditions are met:\n\n'
    '* Redistributions of source code must retain the above copyright notice, this list of '
    'conditions and the following disclaimer.\n'
    '* Redistributions in binary form must reproduce the above copyright notice, this list of '
    'conditions and the following disclaimer in the documentation and/or other materials '
    'provided with the distribution.\n'
    '* Neither the author nor the names of any contributors may be used to endorse or promote '
    'products derived from this software without specific prior written permission.\n\n'
    'THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS '
    'OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF '
    'MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE '
    'COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, '
    'EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF '
    'SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) '
    'HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR '
    'TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS '
    'SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.',
  );
}

const _mit = 'Permission is hereby granted, free of charge, to any person obtaining a copy of this '
    'software and associated documentation files (the "Software"), to deal in the Software '
    'without restriction, including without limitation the rights to use, copy, modify, merge, '
    'publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons '
    'to whom the Software is furnished to do so, subject to the following conditions:\n\n'
    'The above copyright notice and this permission notice shall be included in all copies or '
    'substantial portions of the Software.\n\n'
    'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, '
    'INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR '
    'PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE '
    'FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR '
    'OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER '
    'DEALINGS IN THE SOFTWARE.';

const _apache2 = 'Apache License, Version 2.0, January 2004, http://www.apache.org/licenses/\n\n'
    'TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION\n\n'
    '1. Definitions. "License" shall mean the terms and conditions for use, reproduction, and '
    'distribution as defined by Sections 1 through 9 of this document. "Licensor" shall mean the '
    'copyright owner or entity authorized by the copyright owner that is granting the License. '
    '"Legal Entity" shall mean the union of the acting entity and all other entities that '
    'control, are controlled by, or are under common control with that entity. "You" (or "Your") '
    'shall mean an individual or Legal Entity exercising permissions granted by this License. '
    '"Source" form shall mean the preferred form for making modifications. "Object" form shall '
    'mean any form resulting from mechanical transformation or translation of a Source form. '
    '"Work" shall mean the work of authorship made available under the License. "Derivative '
    'Works" shall mean any work that is based on (or derived from) the Work. "Contribution" '
    'shall mean any work of authorship submitted to the Licensor for inclusion in the Work. '
    '"Contributor" shall mean Licensor and any Legal Entity on behalf of whom a Contribution has '
    'been received by Licensor and subsequently incorporated within the Work.\n\n'
    '2. Grant of Copyright License. Subject to the terms and conditions of this License, each '
    'Contributor hereby grants to You a perpetual, worldwide, non-exclusive, no-charge, '
    'royalty-free, irrevocable copyright license to reproduce, prepare Derivative Works of, '
    'publicly display, publicly perform, sublicense, and distribute the Work and such Derivative '
    'Works in Source or Object form.\n\n'
    '3. Grant of Patent License. Subject to the terms and conditions of this License, each '
    'Contributor hereby grants to You a perpetual, worldwide, non-exclusive, no-charge, '
    'royalty-free, irrevocable patent license to make, have made, use, offer to sell, sell, '
    'import, and otherwise transfer the Work, where such license applies only to those patent '
    'claims licensable by such Contributor that are necessarily infringed by their '
    'Contribution(s) alone or by combination of their Contribution(s) with the Work. If You '
    'institute patent litigation against any entity alleging that the Work constitutes direct or '
    'contributory patent infringement, then any patent licenses granted to You under this '
    'License for that Work shall terminate as of the date such litigation is filed.\n\n'
    '4. Redistribution. You may reproduce and distribute copies of the Work or Derivative Works '
    'thereof in any medium, with or without modifications, and in Source or Object form, '
    'provided that You meet the following conditions: (a) You must give any other recipients of '
    'the Work or Derivative Works a copy of this License; and (b) You must cause any modified '
    'files to carry prominent notices stating that You changed the files; and (c) You must '
    'retain, in the Source form of any Derivative Works that You distribute, all copyright, '
    'patent, trademark, and attribution notices from the Source form of the Work; and (d) If the '
    'Work includes a "NOTICE" text file as part of its distribution, then any Derivative Works '
    'that You distribute must include a readable copy of the attribution notices contained '
    'within such NOTICE file.\n\n'
    '5. Submission of Contributions. Unless You explicitly state otherwise, any Contribution '
    'intentionally submitted for inclusion in the Work by You to the Licensor shall be under the '
    'terms and conditions of this License, without any additional terms or conditions.\n\n'
    '6. Trademarks. This License does not grant permission to use the trade names, trademarks, '
    'service marks, or product names of the Licensor, except as required for reasonable and '
    'customary use in describing the origin of the Work.\n\n'
    '7. Disclaimer of Warranty. Unless required by applicable law or agreed to in writing, '
    'Licensor provides the Work (and each Contributor provides its Contributions) on an "AS IS" '
    'BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied, including, '
    'without limitation, any warranties or conditions of TITLE, NON-INFRINGEMENT, '
    'MERCHANTABILITY, or FITNESS FOR A PARTICULAR PURPOSE.\n\n'
    '8. Limitation of Liability. In no event and under no legal theory shall any Contributor be '
    'liable to You for damages, including any direct, indirect, special, incidental, or '
    'consequential damages of any character arising as a result of this License or out of the '
    'use or inability to use the Work.\n\n'
    '9. Accepting Warranty or Additional Liability. While redistributing the Work or Derivative '
    'Works thereof, You may choose to offer, and charge a fee for, acceptance of support, '
    'warranty, indemnity, or other liability obligations and/or rights consistent with this '
    'License, acting only on Your own behalf and on Your sole responsibility.\n\n'
    'END OF TERMS AND CONDITIONS';
