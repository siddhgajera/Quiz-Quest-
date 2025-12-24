import 'package:flutter/material.dart';
import '../models/activity_model.dart';

class ActivityTile extends StatelessWidget {
  final ActivityModel activity;
  final VoidCallback? onTap;
  final bool showUserInfo;

  const ActivityTile({
    super.key,
    required this.activity,
    this.onTap,
    this.showUserInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildActivityIcon(),
      title: Text(
        activity.title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activity.description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          if (showUserInfo) ...[
            const SizedBox(height: 4),
            _buildUserInfo(),
          ],
          const SizedBox(height: 4),
          Text(
            activity.timeAgo,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
      trailing: _buildTrailingIcon(),
      onTap: onTap,
    );
  }

  Widget _buildActivityIcon() {
    final activityIcon = activity.activityIcon;
    Color color;
    IconData icon;

    switch (activityIcon.color) {
      case 'green':
        color = Colors.green;
        break;
      case 'blue':
        color = Colors.blue;
        break;
      case 'red':
        color = Colors.red;
        break;
      case 'orange':
        color = Colors.orange;
        break;
      case 'amber':
        color = Colors.amber;
        break;
      case 'purple':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    switch (activityIcon.icon) {
      case 'person_add':
        icon = Icons.person_add;
        break;
      case 'login':
        icon = Icons.login;
        break;
      case 'check_circle':
        icon = Icons.check_circle;
        break;
      case 'add':
        icon = Icons.add;
        break;
      case 'arrow_upward':
        icon = Icons.arrow_upward;
        break;
      case 'arrow_downward':
        icon = Icons.arrow_downward;
        break;
      case 'check':
        icon = Icons.check;
        break;
      case 'block':
        icon = Icons.block;
        break;
      case 'star':
        icon = Icons.star;
        break;
      case 'edit':
        icon = Icons.edit;
        break;
      case 'security':
        icon = Icons.security;
        break;
      case 'verified':
        icon = Icons.verified;
        break;
      default:
        icon = Icons.info;
    }

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildUserInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 8,
          backgroundColor: Colors.grey[300],
          backgroundImage: activity.userProfileImage != null
              ? NetworkImage(activity.userProfileImage!)
              : null,
          child: activity.userProfileImage == null
              ? Text(
                  activity.userName.isNotEmpty
                      ? activity.userName[0].toUpperCase()
                      : activity.userEmail[0].toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            activity.userName.isNotEmpty ? activity.userName : activity.userEmail,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget? _buildTrailingIcon() {
    if (activity.metadata.isNotEmpty) {
      return Icon(
        Icons.info_outline,
        size: 16,
        color: Colors.grey[400],
      );
    }
    return null;
  }
}

class ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.activity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildActivityIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activity.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildUserAvatar(),
                        const SizedBox(width: 6),
                        Text(
                          activity.userName.isNotEmpty 
                              ? activity.userName 
                              : activity.userEmail.split('@').first,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          activity.timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityIcon() {
    final activityIcon = activity.activityIcon;
    Color color;
    IconData icon;

    switch (activityIcon.color) {
      case 'green':
        color = Colors.green;
        break;
      case 'blue':
        color = Colors.blue;
        break;
      case 'red':
        color = Colors.red;
        break;
      case 'orange':
        color = Colors.orange;
        break;
      case 'amber':
        color = Colors.amber;
        break;
      case 'purple':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    switch (activityIcon.icon) {
      case 'person_add':
        icon = Icons.person_add;
        break;
      case 'login':
        icon = Icons.login;
        break;
      case 'check_circle':
        icon = Icons.check_circle;
        break;
      case 'add':
        icon = Icons.add;
        break;
      case 'arrow_upward':
        icon = Icons.arrow_upward;
        break;
      case 'arrow_downward':
        icon = Icons.arrow_downward;
        break;
      case 'check':
        icon = Icons.check;
        break;
      case 'block':
        icon = Icons.block;
        break;
      case 'star':
        icon = Icons.star;
        break;
      case 'edit':
        icon = Icons.edit;
        break;
      case 'security':
        icon = Icons.security;
        break;
      case 'verified':
        icon = Icons.verified;
        break;
      default:
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildUserAvatar() {
    return CircleAvatar(
      radius: 10,
      backgroundColor: Colors.grey[300],
      backgroundImage: activity.userProfileImage != null
          ? NetworkImage(activity.userProfileImage!)
          : null,
      child: activity.userProfileImage == null
          ? Text(
              activity.userName.isNotEmpty
                  ? activity.userName[0].toUpperCase()
                  : activity.userEmail[0].toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            )
          : null,
    );
  }
}

class ActivityDetailDialog extends StatelessWidget {
  final ActivityModel activity;

  const ActivityDetailDialog({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          _buildActivityIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              activity.title,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              activity.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildUserSection(),
            const SizedBox(height: 16),
            _buildTimeSection(),
            if (activity.metadata.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildMetadataSection(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildActivityIcon() {
    final activityIcon = activity.activityIcon;
    Color color;
    IconData icon;

    switch (activityIcon.color) {
      case 'green':
        color = Colors.green;
        break;
      case 'blue':
        color = Colors.blue;
        break;
      case 'red':
        color = Colors.red;
        break;
      case 'orange':
        color = Colors.orange;
        break;
      case 'amber':
        color = Colors.amber;
        break;
      case 'purple':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    switch (activityIcon.icon) {
      case 'person_add':
        icon = Icons.person_add;
        break;
      case 'login':
        icon = Icons.login;
        break;
      case 'check_circle':
        icon = Icons.check_circle;
        break;
      case 'add':
        icon = Icons.add;
        break;
      case 'arrow_upward':
        icon = Icons.arrow_upward;
        break;
      case 'arrow_downward':
        icon = Icons.arrow_downward;
        break;
      case 'check':
        icon = Icons.check;
        break;
      case 'block':
        icon = Icons.block;
        break;
      case 'star':
        icon = Icons.star;
        break;
      case 'edit':
        icon = Icons.edit;
        break;
      case 'security':
        icon = Icons.security;
        break;
      case 'verified':
        icon = Icons.verified;
        break;
      default:
        icon = Icons.info;
    }

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildUserSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            backgroundImage: activity.userProfileImage != null
                ? NetworkImage(activity.userProfileImage!)
                : null,
            child: activity.userProfileImage == null
                ? Text(
                    activity.userName.isNotEmpty
                        ? activity.userName[0].toUpperCase()
                        : activity.userEmail[0].toUpperCase(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.userName.isNotEmpty ? activity.userName : 'Unknown User',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  activity.userEmail,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.timeAgo,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
              Text(
                '${activity.timestamp.day}/${activity.timestamp.month}/${activity.timestamp.year} at ${activity.timestamp.hour}:${activity.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Additional Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...activity.metadata.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key}: ',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
