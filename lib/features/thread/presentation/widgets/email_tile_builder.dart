import 'package:core/presentation/extensions/color_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:model/email/email_action_type.dart';
import 'package:model/email/presentation_email.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:model/mailbox/select_mode.dart';
import 'package:tmail_ui_user/features/thread/domain/model/search_query.dart';
import 'package:tmail_ui_user/features/thread/presentation/mixin/base_email_item_tile.dart';

class EmailTileBuilder extends StatelessWidget with BaseEmailItemTile {

  final PresentationEmail presentationEmail;
  final SelectMode selectAllMode;
  final PresentationMailbox? mailboxContain;
  final SearchQuery? searchQuery;
  final bool isSearchEmailRunning;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? paddingDivider;
  final bool isDrag;
  final bool isShowingEmailContent;
  final OnPressEmailActionClick? emailActionClick;
  final OnMoreActionClick? onMoreActionClick;

  EmailTileBuilder({
    super.key,
    required this.presentationEmail,
    required this.selectAllMode,
    required this.isShowingEmailContent,
    this.searchQuery,
    this.isSearchEmailRunning = false,
    this.mailboxContain,
    this.padding,
    this.paddingDivider,
    this.isDrag = false,
    this.emailActionClick,
    this.onMoreActionClick,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          ListTile(
            tileColor: isShowingEmailContent ? AppColor.colorItemEmailSelectedDesktop : null,
            contentPadding: padding ?? const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 5),
            onTap: () => emailActionClick?.call(
                EmailActionType.preview,
                presentationEmail),
            onLongPress: () => emailActionClick?.call(
                EmailActionType.selection,
                presentationEmail),
            leading: GestureDetector(
              onTap: () => emailActionClick?.call(
                  selectAllMode == SelectMode.ACTIVE
                      ? EmailActionType.selection
                      : EmailActionType.preview,
                  presentationEmail),
              child: Container(
                  width: 56,
                  height: 56,
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child:  selectAllMode == SelectMode.ACTIVE
                    ? buildIconAvatarSelection(context, presentationEmail)
                    : buildIconAvatarText(presentationEmail)
              )
            ),
            title: Row(
              children: [
                if (!presentationEmail.hasRead)
                  Padding(
                      padding: const EdgeInsetsDirectional.only(end: 5),
                      child: SvgPicture.asset(
                          imagePaths.icUnreadStatus,
                          width: 9,
                          height: 9,
                          fit: BoxFit.fill)),
                Expanded(child: buildInformationSender(
                  context,
                  presentationEmail,
                  mailboxContain,
                  isSearchEmailRunning,
                  searchQuery)),
                buildIconAnsweredOrForwarded(width: 16, height: 16, presentationEmail: presentationEmail),
                if (presentationEmail.hasAttachment == true)
                  Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      child: buildIconAttachment()),
                Padding(
                    padding: const EdgeInsetsDirectional.only(end: 4, start: 8),
                    child: buildDateTime(context, presentationEmail)),
                buildIconChevron(),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                    padding: const EdgeInsetsDirectional.only(top: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (presentationEmail.hasCalendarEvent)
                          buildCalendarEventIcon(context: context, presentationEmail: presentationEmail),
                        Expanded(child: buildEmailTitle(
                          context,
                          presentationEmail,
                          isSearchEmailRunning,
                          searchQuery)),
                        buildMailboxContain(
                          context,
                          isSearchEmailRunning,
                          presentationEmail),
                        if (presentationEmail.hasStarred)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 8),
                            child: buildIconStar(),
                          )
                      ],
                    )),
                Padding(
                    padding: const EdgeInsetsDirectional.only(top: 6),
                    child: Row(children: [
                      Expanded(child: buildEmailPartialContent(
                        context,
                        presentationEmail,
                        isSearchEmailRunning,
                        searchQuery)),
                    ])
                ),
              ],
            ),
          ),
          Padding(
            padding: paddingDivider ?? const EdgeInsetsDirectional.symmetric(horizontal: 16),
            child: const Divider(color: AppColor.lineItemListColor, height: 1)),
        ],
      ),
    );
  }
}