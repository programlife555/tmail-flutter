
import 'package:model/mailbox/presentation_mailbox.dart';

extension ListPresentationMailboxExtension on List<PresentationMailbox> {

  List<PresentationMailbox> get listSubscribedMailboxes =>
    where((mailbox) => mailbox.supportedSubscribe).toList();

  List<PresentationMailbox> get listPersonalMailboxes =>
    where((mailbox) => mailbox.isPersonal).toList();
}