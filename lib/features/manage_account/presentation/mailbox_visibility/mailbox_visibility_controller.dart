import 'package:core/presentation/extensions/color_extension.dart';
import 'package:core/presentation/resources/image_paths.dart';
import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:core/presentation/utils/app_toast.dart';
import 'package:core/presentation/utils/responsive_utils.dart';
import 'package:core/utils/app_logger.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jmap_dart_client/jmap/core/state.dart' as jmap;
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/mailbox/expand_mode.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:tmail_ui_user/features/base/base_mailbox_controller.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subscribe_action_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subscribe_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/subscribe_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/subscribe_multiple_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/get_all_mailboxes_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/refresh_changes_all_mailboxes_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/subscribe_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/subscribe_multiple_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/get_all_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/refresh_all_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/subscribe_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/subscribe_multiple_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_categories.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_categories_expand_mode.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_node.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_tree_builder.dart';
import 'package:tmail_ui_user/features/mailbox_creator/domain/usecases/verify_name_interactor.dart';
import 'package:tmail_ui_user/features/manage_account/presentation/mailbox_visibility/state/mailbox_visibility_state.dart';
import 'package:tmail_ui_user/features/manage_account/presentation/manage_account_dashboard_controller.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations.dart';
import 'package:tmail_ui_user/main/routes/route_navigation.dart';

class MailboxVisibilityController extends BaseMailboxController {
  SubscribeMailboxInteractor? _subscribeMailboxInteractor;
  SubscribeMultipleMailboxInteractor? _subscribeMultipleMailboxInteractor;
  final _accountDashBoardController = Get.find<ManageAccountDashBoardController>();
  final _appToast = Get.find<AppToast>();
  final _imagePaths = Get.find<ImagePaths>();
  final _responsiveUtils = Get.find<ResponsiveUtils>();
  final mailboxCategoriesExpandMode = MailboxCategoriesExpandMode.initial().obs;
  final mailboxListScrollController = ScrollController();

  Map<Role, MailboxId> mapDefaultMailboxIdByRole = {};
  Map<MailboxId, PresentationMailbox> mapMailboxById = {};
  PresentationMailbox? outboxMailbox;

  jmap.State? _currentMailboxState;

  MailboxVisibilityController(
    TreeBuilder treeBuilder,
    VerifyNameInteractor verifyNameInteractor,
    GetAllMailboxInteractor getAllMailboxInteractor,
    RefreshAllMailboxInteractor refreshAllMailboxInteractor
  ) : super(
    treeBuilder,
    verifyNameInteractor,
    getAllMailboxInteractor: getAllMailboxInteractor,
    refreshAllMailboxInteractor: refreshAllMailboxInteractor
  );

  @override
  void onInit() {
    super.onInit();
    try {
      _subscribeMailboxInteractor = Get.find<SubscribeMailboxInteractor>();
      _subscribeMultipleMailboxInteractor = Get.find<SubscribeMultipleMailboxInteractor>();
    } catch (e) {
      logError('MailboxVisibilityController::onInit(): ${e.toString()}');
    }
  }

  @override
  void onData(Either<Failure, Success> newState) {
    super.onData(newState);
    newState.fold((failure) => null, (success) {
      if (success is GetAllMailboxSuccess) {
        _currentMailboxState = success.currentMailboxState;
        _handleBuildMailboxTree(success.mailboxList);
      } else if (success is RefreshChangesAllMailboxSuccess) {
        _currentMailboxState = success.currentMailboxState;
        refreshTree(success.mailboxList);
      }
    });
  }

  @override
  void onDone() {
    viewState.value.fold((failure) {}, (success) {
      if (success is SubscribeMailboxSuccess) {
        _subscribeMailboxSuccess(success);
      } else if (success is SubscribeMultipleMailboxAllSuccess) {
        _handleUnsubscribeMultipleMailboxAllSuccess(success);
      } else if (success is SubscribeMultipleMailboxHasSomeSuccess) {
        _handleUnsubscribeMultipleMailboxHasSomeSuccess(success);
      }
    });
  }

  @override
  void onReady() {
    final _session = _accountDashBoardController.sessionCurrent.value;
    final _accountId = _accountDashBoardController.accountId.value;
    if(_session != null && _accountId != null) {
      getAllMailbox(_session, _accountId);
    }
    super.onReady();
  }

  void _handleBuildMailboxTree(List<PresentationMailbox> mailboxList) async {
    dispatchState(Right(LoadingBuildTreeMailboxVisibility()));
    await buildTree(mailboxList);
    dispatchState(Right(BuildTreeMailboxVisibilitySuccess()));
  }

  void subscribeMailbox(MailboxNode mailboxNode) {
    final _mailboxSubscribeState = mailboxNode.item.isSubscribedMailbox
      ? MailboxSubscribeState.disabled : MailboxSubscribeState.enabled;
    final _mailboxSubscribeStateAction = mailboxNode.item.isSubscribedMailbox
      ? MailboxSubscribeAction.unSubscribe : MailboxSubscribeAction.subscribe;
    _subscribeMailboxAction(
        SubscribeMailboxRequest(
          mailboxNode.item.id,
          _mailboxSubscribeState,
          _mailboxSubscribeStateAction,
        )
    );
  }

  void _subscribeMailboxAction(SubscribeMailboxRequest subscribeMailboxRequest) {
    final _accountId = _accountDashBoardController.accountId.value;
    if (_accountId != null) {
      final subscribeRequest = generateSubscribeRequest(
        subscribeMailboxRequest.mailboxId,
        subscribeMailboxRequest.subscribeState,
        subscribeMailboxRequest.subscribeAction
      );

      if (subscribeRequest is SubscribeMultipleMailboxRequest) {
        consumeState(_subscribeMultipleMailboxInteractor!.execute(_accountId, subscribeRequest));
      } else if (subscribeRequest is SubscribeMailboxRequest) {
        consumeState(_subscribeMailboxInteractor!.execute(_accountId, subscribeRequest));
      }
    }
  }

  void toggleMailboxCategories(MailboxCategories categories) {
    switch(categories) {
      case MailboxCategories.exchange:
        final newExpandMode = mailboxCategoriesExpandMode.value.defaultMailbox == ExpandMode.EXPAND ? ExpandMode.COLLAPSE : ExpandMode.EXPAND;
        mailboxCategoriesExpandMode.value.defaultMailbox = newExpandMode;
        mailboxCategoriesExpandMode.refresh();
        break;
      case MailboxCategories.personalMailboxes:
        final newExpandMode = mailboxCategoriesExpandMode.value.personalMailboxes == ExpandMode.EXPAND ? ExpandMode.COLLAPSE : ExpandMode.EXPAND;
        mailboxCategoriesExpandMode.value.personalMailboxes = newExpandMode;
        mailboxCategoriesExpandMode.refresh();
        break;
      case MailboxCategories.teamMailboxes:
        final newExpandMode = mailboxCategoriesExpandMode.value.teamMailboxes == ExpandMode.EXPAND ? ExpandMode.COLLAPSE : ExpandMode.EXPAND;
        mailboxCategoriesExpandMode.value.teamMailboxes = newExpandMode;
        mailboxCategoriesExpandMode.refresh();
        break;
      case MailboxCategories.appGrid:
        break;
    }
  }

  void _subscribeMailboxSuccess(SubscribeMailboxSuccess subscribeMailboxSuccess) {
    if (subscribeMailboxSuccess.subscribeAction == MailboxSubscribeAction.unSubscribe
        && currentOverlayContext != null
        && currentContext != null) {
        _showToastSubscribeMailboxSuccess(subscribeMailboxSuccess.mailboxId);
    }

    _refreshMailboxChanges(subscribeMailboxSuccess.currentEmailState);
  }

  void _handleUnsubscribeMultipleMailboxHasSomeSuccess(SubscribeMultipleMailboxHasSomeSuccess subscribeMailboxSuccess) {
    if(subscribeMailboxSuccess.subscribeAction == MailboxSubscribeAction.unSubscribe) {
      _showToastSubscribeMailboxSuccess(
        subscribeMailboxSuccess.parentMailboxId,
        listDescendantMailboxIds: subscribeMailboxSuccess.mailboxIdsSubscribe
      );
    }

    _refreshMailboxChanges(subscribeMailboxSuccess.currentEmailState);
  }

  void _handleUnsubscribeMultipleMailboxAllSuccess(SubscribeMultipleMailboxAllSuccess subscribeMailboxSuccess) {
    if(subscribeMailboxSuccess.subscribeAction == MailboxSubscribeAction.unSubscribe) {
      _showToastSubscribeMailboxSuccess(
          subscribeMailboxSuccess.parentMailboxId,
          listDescendantMailboxIds: subscribeMailboxSuccess.mailboxIdsSubscribe
      );
    }

    _refreshMailboxChanges(subscribeMailboxSuccess.currentEmailState);
  }

  void _refreshMailboxChanges(jmap.State? currentEmailState) {
    final _session = _accountDashBoardController.sessionCurrent.value;
    final _accountId = _accountDashBoardController.accountId.value;
    final currentMailboxState = currentEmailState ?? _currentMailboxState;
    if (_session != null && _accountId != null && currentMailboxState != null) {
      refreshMailboxChanges(_session, _accountId, currentMailboxState);
    }
  }

  void _showToastSubscribeMailboxSuccess(
      MailboxId mailboxIdSubscribed,
      {List<MailboxId>? listDescendantMailboxIds}
  ) {
    if (currentOverlayContext != null && currentContext != null) {
      _appToast.showBottomToast(
          currentOverlayContext!,
          AppLocalizations.of(currentContext!).toastMsgHideMailboxSuccess,
          actionName: AppLocalizations.of(currentContext!).undo,
          onActionClick: () => _subscribeMailboxAction(
            SubscribeMailboxRequest(
              mailboxIdSubscribed,
              MailboxSubscribeState.enabled,
              MailboxSubscribeAction.subscribe
            )
          ),
          leadingIcon: SvgPicture.asset(
            _imagePaths.icFolderMailbox,
            width: 24,
            height: 24,
            color: Colors.white,
            fit: BoxFit.fill
          ),
          backgroundColor: AppColor.toastSuccessBackgroundColor,
          textColor: Colors.white,
          textActionColor: Colors.white,
          actionIcon: SvgPicture.asset(_imagePaths.icUndo),
          maxWidth: _responsiveUtils.getMaxWidthToast(currentContext!)
      );
    }
  }
}