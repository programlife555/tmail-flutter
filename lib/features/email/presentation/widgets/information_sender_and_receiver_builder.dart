import 'package:core/presentation/extensions/color_extension.dart';
import 'package:core/presentation/resources/image_paths.dart';
import 'package:core/presentation/utils/responsive_utils.dart';
import 'package:core/presentation/views/button/tmail_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:model/email/email_action_type.dart';
import 'package:model/email/presentation_email.dart';
import 'package:model/extensions/presentation_email_extension.dart';
import 'package:tmail_ui_user/features/base/widget/email_avatar_builder.dart';
import 'package:tmail_ui_user/features/email/presentation/model/email_unsubscribe.dart';
import 'package:tmail_ui_user/features/email/presentation/widgets/email_receiver_widget.dart';
import 'package:tmail_ui_user/features/email/presentation/widgets/email_sender_builder.dart';
import 'package:tmail_ui_user/features/email/presentation/widgets/email_view_app_bar_widget.dart';
import 'package:tmail_ui_user/features/email/presentation/widgets/received_time_builder.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations.dart';

class InformationSenderAndReceiverBuilder extends StatelessWidget {

  final PresentationEmail emailSelected;
  final ResponsiveUtils responsiveUtils;
  final ImagePaths imagePaths;
  final EmailUnsubscribe? emailUnsubscribe;
  final OnOpenEmailAddressDetailAction? openEmailAddressDetailAction;
  final OnEmailActionClick? onEmailActionClick;

  const InformationSenderAndReceiverBuilder({
    Key? key,
    required this.emailSelected,
    required this.responsiveUtils,
    required this.imagePaths,
    required this.emailUnsubscribe,
    this.openEmailAddressDetailAction,
    this.onEmailActionClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: emailSelected.numberOfAllEmailAddress() > 0
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
        children: [
          EmailAvatarBuilder(emailSelected: emailSelected),
          const SizedBox(width: 16),
          Expanded(child: LayoutBuilder(builder: (context, constraints) {
            return Transform(
              transform: Matrix4.translationValues(0.0, -5.0, 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (emailSelected.from?.isNotEmpty == true)
                    Row(children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(child: Transform(
                              transform: Matrix4.translationValues(-5.0, 0.0, 0.0),
                              child: EmailSenderBuilder(
                                emailAddress: emailSelected.from!.first,
                                openEmailAddressDetailAction: openEmailAddressDetailAction,
                              )
                            )),
                            if (!emailSelected.isSubscribed && emailUnsubscribe != null && !responsiveUtils.isPortraitMobile(context))
                              TMailButtonWidget.fromText(
                                text: AppLocalizations.of(context).unsubscribe,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 14,
                                  color: AppColor.colorTextBody,
                                  decoration: TextDecoration.underline,
                                ),
                                padding: const EdgeInsetsDirectional.symmetric(vertical: 5, horizontal: 8),
                                backgroundColor: Colors.transparent,
                                onTapActionCallback: () => onEmailActionClick?.call(emailSelected, EmailActionType.unsubscribe),
                              ),
                          ],
                        )
                      ),
                      ReceivedTimeBuilder(
                        emailSelected: emailSelected,
                        margin: const EdgeInsetsDirectional.only(start: 16),
                      ),
                    ]),
                  if (emailSelected.numberOfAllEmailAddress() > 0)
                    EmailReceiverWidget(
                      emailSelected: emailSelected,
                      maxWidth: constraints.maxWidth,
                      openEmailAddressDetailAction: openEmailAddressDetailAction,
                    )
                ]
              ),
            );
          })),
        ]
      ),
    );
  }
}