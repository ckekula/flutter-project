import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_instagram_offline_first_clone/app/bloc/app_bloc.dart';
import 'package:flutter_instagram_offline_first_clone/attachments/attachments.dart';
import 'package:flutter_instagram_offline_first_clone/chats/chat/widgets/widgets.dart';
import 'package:flutter_instagram_offline_first_clone/l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:instagram_blocks_ui/instagram_blocks_ui.dart';
import 'package:intl/intl.dart';
import 'package:shared/shared.dart';

class MessageBubbleContent extends StatelessWidget {
  const MessageBubbleContent({
    required this.message,
    super.key,
  });

  final Message message;

  bool get hasNonUrlAttachments =>
      message.attachments.any((a) => a.type != AttachmentType.urlPreview.value);

  bool get hasUrlAttachments =>
      message.attachments.any((a) => a.type == AttachmentType.urlPreview.value);

  bool get hasAttachments => hasUrlAttachments || hasNonUrlAttachments;

  bool get hasRepliedComment => message.repliedMessage != null;

  bool get displayBottomStatuses => hasAttachments;

  bool get isEdited =>
      message.createdAt.isAfter(message.updatedAt) &&
      !message.createdAt.isAtSameMomentAs(message.updatedAt);

  bool get isSharedPostUnavailable =>
      message.sharedPostId == null && message.message.trim().isEmpty;

  bool get hasSharedPost =>
      message.sharedPost != null &&
      message.replyMessageId == null &&
      message.replyMessageAttachmentUrl == null;

  bool get isSharedPostReel => message.sharedPost?.isReel ?? false;

  @override
  Widget build(BuildContext context) {
    final user = context.select((AppBloc bloc) => bloc.state.user);
    final isMine = message.sender?.id == user.id;
    final sharedPost = message.sharedPost;

    final effectiveTextColor = switch ((isMine, context.isLight)) {
      (true, _) => AppColors.white,
      (false, true) => AppColors.black,
      (false, false) => AppColors.white,
    };

    return BubbleBackground(
      colors: [
        if (!isMine) ...[
          context.customReversedAdaptiveColor(
            light: AppColors.white,
            dark: AppColors.primaryDarkBlue,
          ),
        ] else
          ...AppColors.primaryMessageBubbleGradient,
      ],
      child: switch ((
        isSharedPostUnavailable,
        hasSharedPost,
        isSharedPostReel
      )) {
        (true, _, _) => MessageSharedPostUnavailable(
            message: message,
            isEdited: isEdited,
            effectiveTextColor: effectiveTextColor,
          ),
        (false, true, true) => MessageSharedReel(
            sharedPost: sharedPost!,
            effectiveTextColor: effectiveTextColor,
            isEdited: isEdited,
            message: message,
          ),
        (false, true, false) => MessageSharedPost(
            sharedPost: sharedPost!,
            effectiveTextColor: effectiveTextColor,
            isEdited: isEdited,
            message: message,
          ),
        (false, false, _) => MessageContentView(
            hasRepliedComment: hasRepliedComment,
            message: message,
            displayBottomStatuses: displayBottomStatuses,
            isMine: isMine,
            effectiveTextColor: effectiveTextColor,
            isEdited: isEdited,
            hasAttachments: hasAttachments,
          ),
      },
    );
  }
}

class MessageContentView extends StatelessWidget {
  const MessageContentView({
    required this.hasRepliedComment,
    required this.message,
    required this.displayBottomStatuses,
    required this.isMine,
    required this.effectiveTextColor,
    required this.isEdited,
    required this.hasAttachments,
    super.key,
  });

  final bool hasRepliedComment;
  final Message message;
  final bool displayBottomStatuses;
  final bool isMine;
  final Color effectiveTextColor;
  final bool isEdited;
  final bool hasAttachments;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasRepliedComment) RepliedMessageBubble(message: message),
              if (displayBottomStatuses)
                Padding(
                  padding: !hasRepliedComment
                      ? EdgeInsets.zero
                      : const EdgeInsets.only(
                          top: AppSpacing.xs,
                        ),
                  child: TextBubble(
                    message: message,
                    isMine: isMine,
                    isOnlyEmoji: message.message.isOnlyEmoji,
                  ),
                )
              else
                TextMessageWidget(
                  text: message.message,
                  spacing: AppSpacing.md,
                  textStyle:
                      context.bodyLarge?.apply(color: effectiveTextColor),
                  child: MessageStatuses(
                    isEdited: isEdited,
                    message: message,
                  ),
                ),
              if (hasAttachments) ParseAttachments(message: message),
            ],
          ),
        ),
        if (displayBottomStatuses)
          Positioned.fill(
            right: AppSpacing.md,
            bottom: AppSpacing.xs,
            child: Align(
              alignment: Alignment.bottomRight,
              child: MessageStatuses(
                isEdited: isEdited,
                message: message,
              ),
            ),
          ),
      ],
    );
  }
}

class MessageSharedPost extends StatelessWidget {
  const MessageSharedPost({
    required this.sharedPost,
    required this.effectiveTextColor,
    required this.isEdited,
    required this.message,
    super.key,
  });

  final PostBlock sharedPost;
  final Color effectiveTextColor;
  final bool isEdited;
  final Message message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Tappable(
          animationEffect: TappableAnimationEffect.none,
          onTap: () => context.pushNamed(
            'post_details',
            pathParameters: {'id': sharedPost.id},
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                horizontalTitleGap: AppSpacing.sm,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                leading: UserProfileAvatar(
                  avatarUrl: sharedPost.author.avatarUrl,
                  isLarge: false,
                  withAdaptiveBorder: false,
                ),
                title: Text(
                  sharedPost.author.username,
                  style: context.bodyLarge?.copyWith(
                    fontWeight: AppFontWeight.bold,
                    color: effectiveTextColor,
                  ),
                ),
              ),
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ImageAttachmentThumbnail(
                      image: Attachment(
                        imageUrl: sharedPost.firstMediaUrl,
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Builder(
                      builder: (_) {
                        if (sharedPost.isReel) {
                          return Container(
                            decoration: const BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.dark,
                                  blurRadius: 15,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Assets.icons.instagramReel.svg(
                              height: AppSize.iconSizeBig,
                              width: AppSize.iconSizeBig,
                              colorFilter: const ColorFilter.mode(
                                AppColors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          );
                        }
                        if (sharedPost.media.length > 1) {
                          return const Icon(
                            Icons.layers,
                            size: AppSize.iconSizeBig,
                            shadows: [
                              Shadow(
                                blurRadius: 2,
                              ),
                            ],
                          );
                        }
                        if (sharedPost.hasBothMediaTypes) {
                          return const SizedBox.shrink();
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
              if (sharedPost.caption.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text.rich(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    TextSpan(
                      children: [
                        TextSpan(
                          text: sharedPost.author.username,
                          style: context.bodyLarge?.copyWith(
                            fontWeight: AppFontWeight.bold,
                            color: effectiveTextColor,
                          ),
                        ),
                        const WidgetSpan(
                          child: SizedBox(width: AppSpacing.xs),
                        ),
                        TextSpan(
                          text: sharedPost.caption,
                          style: context.bodyLarge?.apply(
                            color: effectiveTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned.fill(
          right: AppSpacing.md,
          bottom: AppSpacing.xs,
          child: Align(
            alignment: Alignment.bottomRight,
            child: MessageStatuses(
              isEdited: isEdited,
              message: message,
            ),
          ),
        ),
      ],
    );
  }
}

class MessageSharedReel extends StatelessWidget {
  const MessageSharedReel({
    required this.sharedPost,
    required this.effectiveTextColor,
    required this.isEdited,
    required this.message,
    super.key,
  });

  final PostBlock sharedPost;
  final Color effectiveTextColor;
  final bool isEdited;
  final Message message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Tappable(
          animationEffect: TappableAnimationEffect.none,
          onTap: () => context.pushNamed(
            'post_details',
            pathParameters: {'id': sharedPost.id},
          ),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ImageAttachmentThumbnail(
                  image: Attachment(
                    imageUrl: sharedPost.firstMediaUrl,
                  ),
                  // fit: BoxFit.fitHeight,
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Builder(
                  builder: (_) {
                    if (sharedPost.media.length > 1) {
                      return const Icon(
                        Icons.layers,
                        size: AppSize.iconSizeBig,
                        shadows: [
                          Shadow(blurRadius: 2),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                child: ListTile(
                  horizontalTitleGap: AppSpacing.sm,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  leading: UserProfileAvatar(
                    avatarUrl: sharedPost.author.avatarUrl,
                    isLarge: false,
                    withAdaptiveBorder: false,
                  ),
                  title: Text(
                    sharedPost.author.username,
                    style: context.bodyLarge?.copyWith(
                      fontWeight: AppFontWeight.bold,
                      color: effectiveTextColor,
                    ),
                  ),
                  trailing: Container(
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.dark,
                          blurRadius: 15,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Assets.icons.instagramReel.svg(
                      height: AppSize.iconSizeBig,
                      width: AppSize.iconSizeBig,
                      colorFilter: const ColorFilter.mode(
                        AppColors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          right: AppSpacing.md,
          bottom: AppSpacing.xs,
          child: Align(
            alignment: Alignment.bottomRight,
            child: MessageStatuses(
              isEdited: isEdited,
              message: message,
            ),
          ),
        ),
      ],
    );
  }
}

class MessageSharedPostUnavailable extends StatelessWidget {
  const MessageSharedPostUnavailable({
    required this.effectiveTextColor,
    required this.message,
    required this.isEdited,
    super.key,
  });

  final Message message;
  final bool isEdited;
  final Color effectiveTextColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.postUnavailable,
            style: context.bodyLarge?.copyWith(
              fontWeight: AppFontWeight.bold,
              color: effectiveTextColor,
            ),
          ),
          TextMessageWidget(
            text: '${l10n.postUnavailableDescription}.',
            spacing: AppSpacing.md,
            textStyle: context.bodyLarge?.apply(color: effectiveTextColor),
            child: MessageStatuses(
              isEdited: isEdited,
              message: message,
            ),
          ),
        ],
      ),
    );
  }
}

class MessageStatuses extends StatelessWidget {
  const MessageStatuses({
    required this.isEdited,
    required this.message,
    super.key,
  });

  final Message message;
  final bool isEdited;

  @override
  Widget build(BuildContext context) {
    final user = context.select((AppBloc bloc) => bloc.state.user);
    final isMine = message.sender?.id == user.id;

    final effectiveSecondaryTextColor = switch (isMine) {
      true => AppColors.white,
      false => AppColors.grey,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (isEdited)
          Text(
            'edited',
            style: context.bodySmall?.apply(color: effectiveSecondaryTextColor),
          ),
        Text(
          message.createdAt.format(
            context,
            dateFormat: DateFormat.Hm,
          ),
          style: context.bodySmall?.apply(color: effectiveSecondaryTextColor),
        ),
        if (isMine) ...[
          if (message.isRead)
            Assets.icons.check.svg(
              height: AppSize.iconSizeSmall,
              width: AppSize.iconSizeSmall,
              colorFilter: ColorFilter.mode(
                effectiveSecondaryTextColor,
                BlendMode.srcIn,
              ),
            )
          else
            Icon(
              Icons.check,
              size: AppSize.iconSizeSmall,
              color: effectiveSecondaryTextColor,
            ),
        ],
      ].insertBetween(const SizedBox(width: AppSpacing.xs)),
    );
  }
}
