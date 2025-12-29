```sql
-- ============================================
-- 数据库: Trello Clone - 多人协作任务管理系统
-- 说明: 所有表字段均包含详细注释
-- 作者: Janice Dong
-- 版本: 1.0
-- ============================================

-- 1. 用户表 - 存储系统所有用户信息
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),           -- 用户唯一标识符，使用UUID避免ID猜测攻击
    email VARCHAR(255) UNIQUE NOT NULL,                     -- 用户邮箱，用于登录和通知，必须唯一
    username VARCHAR(100) NOT NULL,                         -- 用户显示名称，团队内可见
    password_hash VARCHAR(255),                             -- 密码哈希值，使用bcrypt/scrypt算法存储
    avatar_url TEXT,                                        -- 用户头像URL，支持上传自定义头像
    bio TEXT,                                               -- 用户个人简介，展示专业技能或兴趣
    phone VARCHAR(20),                                      -- 用户手机号，用于紧急联系或二次验证
    timezone VARCHAR(50) DEFAULT 'UTC',                     -- 用户时区，用于正确显示时间
    locale VARCHAR(10) DEFAULT 'zh-CN',                     -- 用户语言偏好，用于国际化
    is_active BOOLEAN DEFAULT true,                         -- 用户账户是否激活，false表示禁用
    is_verified BOOLEAN DEFAULT false,                      -- 邮箱是否已验证，未验证用户功能受限
    email_notifications JSONB DEFAULT '{                    -- 用户邮件通知偏好设置
        "card_assigned": true,
        "card_mentioned": true,
        "due_date_reminder": true,
        "weekly_digest": false,
        "product_updates": false
    }',
    push_notifications JSONB DEFAULT '{                     -- 用户推送通知偏好设置
        "enabled": true,
        "card_updates": true,
        "mentions": true
    }',
    last_login_at TIMESTAMPTZ,                              -- 最近一次登录时间，用于安全审计
    login_attempts INTEGER DEFAULT 0,                       -- 连续登录失败次数，用于防止暴力破解
    locked_until TIMESTAMPTZ,                               -- 账户锁定直到的时间，超过则自动解锁
    two_factor_enabled BOOLEAN DEFAULT false,               -- 是否启用双因素认证
    two_factor_secret VARCHAR(100),                         -- 双因素认证密钥
    deleted_at TIMESTAMPTZ,                                 -- 软删除时间戳，null表示未删除
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 账户创建时间，不可为空
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 账户最后更新时间，用于同步
    CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')  -- 邮箱格式验证
);

-- 2. 工作空间表 - 团队协作的核心容器
CREATE TABLE workspaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 工作空间唯一标识符
    name VARCHAR(255) NOT NULL,                             -- 工作空间名称，如"产品研发部"
    slug VARCHAR(255) UNIQUE NOT NULL,                      -- 工作空间URL友好标识，如"product-team"
    description TEXT,                                       -- 工作空间详细描述
    logo_url TEXT,                                          -- 工作空间Logo图片URL
    banner_url TEXT,                                        -- 工作空间横幅图片URL
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,  -- 工作空间所有者，拥有最高权限
    visibility VARCHAR(50) DEFAULT 'private',               -- 可见性: private(私有)/public(公开)/team(团队可见)
    invitation_policy VARCHAR(50) DEFAULT 'admin_only',     -- 邀请策略: admin_only(仅管理员)/all_members(所有成员)
    default_role VARCHAR(50) DEFAULT 'member',              -- 新成员默认角色
    settings JSONB DEFAULT '{                               -- 工作空间级别设置
        "max_boards": 50,
        "max_members": 100,
        "allow_external_invites": true,
        "require_approval": false,
        "data_retention_days": 365
    }',
    subscription_tier VARCHAR(50) DEFAULT 'free',           -- 订阅等级: free/basic/pro/business
    subscription_ends_at TIMESTAMPTZ,                       -- 订阅到期时间
    storage_used BIGINT DEFAULT 0,                          -- 已使用存储空间(字节)
    storage_limit BIGINT DEFAULT 1073741824,                -- 存储空间限制(默认1GB)
    is_active BOOLEAN DEFAULT true,                         -- 工作空间是否活跃
    deleted_at TIMESTAMPTZ,                                 -- 软删除时间戳
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 创建时间
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL           -- 最后更新时间
);

-- 3. 工作空间成员表 - 工作空间与用户的多对多关系
CREATE TABLE workspace_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 成员关系唯一标识符
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,  -- 关联的工作空间ID
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,            -- 关联的用户ID
    role VARCHAR(50) NOT NULL DEFAULT 'member',             -- 成员角色: owner/admin/member/guest
    title VARCHAR(100),                                     -- 成员在工作空间内的职位/头衔
    permissions JSONB DEFAULT '{                            -- 成员的具体权限配置
        "can_create_board": true,
        "can_invite_member": false,
        "can_remove_member": false,
        "can_manage_workspace": false,
        "can_view_all_boards": false,
        "can_export_data": false
    }',
    notification_settings JSONB DEFAULT '{                  -- 成员在工作空间内的通知设置
        "email_frequency": "immediate",
        "desktop_notifications": true,
        "mobile_notifications": true
    }',
    joined_at TIMESTAMPTZ DEFAULT NOW(),                    -- 加入工作空间的时间
    invited_by UUID REFERENCES users(id),                   -- 邀请人ID
    invitation_id UUID,                                     -- 关联的邀请记录ID
    is_active BOOLEAN DEFAULT true,                         -- 成员是否活跃（可设置为暂停访问）
    last_accessed_at TIMESTAMPTZ,                           -- 最后访问该工作空间的时间
    UNIQUE(workspace_id, user_id),                          -- 确保用户在工作空间内唯一
    CONSTRAINT valid_role CHECK (role IN ('owner', 'admin', 'member', 'guest'))  -- 角色枚举验证
);

-- 4. 看板表 - 项目管理的核心单元
CREATE TABLE boards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 看板唯一标识符
    title VARCHAR(255) NOT NULL,                            -- 看板标题
    description TEXT,                                       -- 看板详细描述
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,  -- 所属工作空间，null表示个人看板
    creator_id UUID NOT NULL REFERENCES users(id),          -- 创建者ID
    background_type VARCHAR(50) DEFAULT 'color',            -- 背景类型: color/image/gradient
    background_value VARCHAR(100) DEFAULT '#0079BF',        -- 背景值: 颜色值/图片URL
    cover_image_url TEXT,                                   -- 看板封面图URL
    visibility VARCHAR(50) DEFAULT 'private',               -- 可见性: private/workspace/public
    settings JSONB DEFAULT '{                               -- 看板级别设置
        "allow_comments": true,
        "allow_attachments": true,
        "allow_labels": true,
        "allow_checklists": true,
        "allow_due_dates": true,
        "allow_voting": false,
        "allow_subscriptions": true,
        "card_cover_images": true,
        "card_count": "hide",                               -- hide/show
        "sort_by": "manual",                                -- manual/date/priority
        "filter": {}
    }',
    is_template BOOLEAN DEFAULT false,                      -- 是否为模板看板
    template_category VARCHAR(100),                         -- 模板分类: project/team/personal
    is_closed BOOLEAN DEFAULT false,                        -- 看板是否已关闭/归档
    closed_at TIMESTAMPTZ,                                  -- 关闭时间
    closed_by UUID REFERENCES users(id),                    -- 关闭者
    is_starred BOOLEAN DEFAULT false,                       -- 当前用户是否星标此看板
    last_activity_at TIMESTAMPTZ,                           -- 最后活动时间，用于排序
    card_count INTEGER DEFAULT 0,                           -- 卡片总数（缓存字段）
    member_count INTEGER DEFAULT 0,                         -- 成员总数（缓存字段）
    view_count INTEGER DEFAULT 0,                           -- 查看次数统计
    deleted_at TIMESTAMPTZ,                                 -- 软删除时间戳
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 创建时间
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 最后更新时间
    CONSTRAINT visibility_check CHECK (visibility IN ('private', 'workspace', 'public'))
);

-- 5. 看板成员表 - 看板与用户的多对多关系
CREATE TABLE board_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 看板成员关系唯一标识符
    board_id UUID NOT NULL REFERENCES boards(id) ON DELETE CASCADE,  -- 关联的看板ID
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,    -- 关联的用户ID
    role VARCHAR(50) NOT NULL DEFAULT 'member',             -- 在看板中的角色: admin/editor/commenter/viewer
    permissions JSONB DEFAULT '{                            -- 在看板中的具体权限
        "can_edit_board": true,
        "can_delete_board": false,
        "can_invite_member": false,
        "can_remove_member": false,
        "can_edit_settings": false,
        "can_archive_board": false,
        "can_move_board": false,
        "can_copy_board": true
    }',
    notification_level VARCHAR(50) DEFAULT 'all',           -- 通知级别: all/mentions/none
    is_favorite BOOLEAN DEFAULT false,                      -- 是否将此看板设为收藏
    color_label VARCHAR(20),                                -- 在看板中分配的颜色标签（用于视觉区分）
    added_at TIMESTAMPTZ DEFAULT NOW(),                     -- 加入看板的时间
    added_by UUID REFERENCES users(id),                     -- 添加者ID
    last_viewed_at TIMESTAMPTZ,                             -- 最后查看该看板的时间
    UNIQUE(board_id, user_id),                              -- 确保用户在看板中唯一
    CONSTRAINT valid_role CHECK (role IN ('admin', 'editor', 'commenter', 'viewer'))
);

-- 6. 列表表 - 看板内的垂直分类（泳道）
CREATE TABLE lists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 列表唯一标识符
    board_id UUID NOT NULL REFERENCES boards(id) ON DELETE CASCADE,  -- 所属看板ID
    title VARCHAR(255) NOT NULL,                            -- 列表标题，如"待办事项"、"进行中"
    description TEXT,                                       -- 列表详细描述
    position INTEGER NOT NULL,                              -- 在看板中的位置顺序，从0开始
    wip_limit INTEGER,                                      -- 在制品限制（看板方法中的WIP限制）
    wip_limit_enabled BOOLEAN DEFAULT false,                -- 是否启用WIP限制
    color VARCHAR(7),                                       -- 列表颜色标签（十六进制）
    is_archived BOOLEAN DEFAULT false,                      -- 列表是否已归档
    archived_at TIMESTAMPTZ,                                -- 归档时间
    archived_by UUID REFERENCES users(id),                  -- 归档者
    card_count INTEGER DEFAULT 0,                           -- 卡片数量（缓存字段）
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 创建时间
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL           -- 最后更新时间
);

-- 7. 卡片表 - 任务/事项的基本单元
CREATE TABLE cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 卡片唯一标识符
    list_id UUID NOT NULL REFERENCES lists(id) ON DELETE CASCADE,  -- 所属列表ID
    title VARCHAR(255) NOT NULL,                            -- 卡片标题
    description TEXT,                                       -- 卡片详细描述，支持Markdown
    description_html TEXT,                                  -- 描述HTML版本（转换后缓存）
    cover_image_url TEXT,                                   -- 卡片封面图URL
    cover_color VARCHAR(7),                                 -- 封面颜色（十六进制）
    cover_size VARCHAR(20) DEFAULT 'normal',                -- 封面尺寸: normal/full
    position INTEGER NOT NULL,                              -- 在列表中的位置顺序，从0开始
    due_date TIMESTAMPTZ,                                   -- 截止日期
    start_date TIMESTAMPTZ,                                 -- 开始日期
    is_completed BOOLEAN DEFAULT false,                     -- 是否已完成
    completed_at TIMESTAMPTZ,                               -- 完成时间
    completed_by UUID REFERENCES users(id),                 -- 完成者
    time_estimate INTEGER,                                  -- 预估时间（分钟）
    time_spent INTEGER DEFAULT 0,                           -- 已花费时间（分钟）
    is_subscribed BOOLEAN DEFAULT false,                    -- 当前用户是否订阅此卡片更新
    subscriber_count INTEGER DEFAULT 0,                     -- 订阅者数量（缓存）
    comment_count INTEGER DEFAULT 0,                        -- 评论数量（缓存）
    attachment_count INTEGER DEFAULT 0,                     -- 附件数量（缓存）
    checklist_items_count INTEGER DEFAULT 0,                -- 检查项总数（缓存）
    checklist_items_completed INTEGER DEFAULT 0,            -- 已完成的检查项数（缓存）
    vote_count INTEGER DEFAULT 0,                           -- 投票数（缓存）
    is_archived BOOLEAN DEFAULT false,                      -- 卡片是否已归档
    archived_at TIMESTAMPTZ,                                -- 归档时间
    archived_by UUID REFERENCES users(id),                  -- 归档者
    created_by UUID REFERENCES users(id),                   -- 创建者
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 创建时间
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 最后更新时间
    last_comment_at TIMESTAMPTZ,                            -- 最后评论时间
    last_activity_at TIMESTAMPTZ                            -- 最后活动时间
);

-- 8. 卡片成员表 - 卡片与用户的多对多关系（任务分配）
CREATE TABLE card_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 卡片成员关系唯一标识符
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,    -- 关联的卡片ID
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,    -- 关联的用户ID
    assigned_at TIMESTAMPTZ DEFAULT NOW(),                  -- 分配时间
    assigned_by UUID REFERENCES users(id),                  -- 分配者
    is_lead BOOLEAN DEFAULT false,                          -- 是否为主要负责人
    UNIQUE(card_id, user_id)                                -- 确保用户在卡片中唯一
);

-- 9. 评论表 - 卡片内的讨论和反馈
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 评论唯一标识符
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,  -- 所属卡片ID
    user_id UUID NOT NULL REFERENCES users(id),             -- 评论者ID
    parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,  -- 父评论ID（支持回复）
    content TEXT NOT NULL,                                  -- 评论内容，支持Markdown
    content_html TEXT,                                      -- 评论内容HTML版本（转换后缓存）
    mentions JSONB DEFAULT '[]',                            -- 被提及的用户ID数组
    attachments JSONB DEFAULT '[]',                         -- 附件信息数组（图片/文件）
    reaction_counts JSONB DEFAULT '{}',                     -- 表情反应计数，如{"👍": 3, "❤️": 1}
    is_pinned BOOLEAN DEFAULT false,                        -- 是否置顶
    pinned_at TIMESTAMPTZ,                                  -- 置顶时间
    pinned_by UUID REFERENCES users(id),                    -- 置顶者
    is_edited BOOLEAN DEFAULT false,                        -- 是否被编辑过
    edited_at TIMESTAMPTZ,                                  -- 最后编辑时间
    edit_history JSONB DEFAULT '[]',                        -- 编辑历史记录
    is_hidden BOOLEAN DEFAULT false,                        -- 是否被隐藏（敏感内容）
    hidden_by UUID REFERENCES users(id),                    -- 隐藏者
    hidden_at TIMESTAMPTZ,                                  -- 隐藏时间
    hidden_reason VARCHAR(255),                             -- 隐藏原因
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 创建时间
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL           -- 最后更新时间
);

-- 10. 活动日志表 - 系统审计和时间线记录
CREATE TABLE activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 活动日志唯一标识符
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,  -- 关联的工作空间ID
    board_id UUID REFERENCES boards(id) ON DELETE CASCADE,          -- 关联的看板ID
    list_id UUID REFERENCES lists(id) ON DELETE SET NULL,           -- 关联的列表ID
    card_id UUID REFERENCES cards(id) ON DELETE SET NULL,           -- 关联的卡片ID
    comment_id UUID REFERENCES comments(id) ON DELETE SET NULL,     -- 关联的评论ID
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,           -- 执行操作的用户ID
    action_type VARCHAR(100) NOT NULL,                      -- 操作类型: card.created, card.moved, comment.added
    action_group VARCHAR(50),                               -- 操作分组: card/list/board/workspace
    old_value JSONB,                                        -- 操作前的值
    new_value JSONB,                                        -- 操作后的值
    diff JSONB,                                             -- 变化差异（计算得出）
    metadata JSONB DEFAULT '{                               -- 操作元数据
        "client": "web",
        "version": "1.0.0"
    }',
    ip_address INET,                                        -- 操作者IP地址
    user_agent TEXT,                                        -- 操作者User-Agent
    is_system_action BOOLEAN DEFAULT false,                 -- 是否为系统自动操作
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL           -- 操作发生时间
);

-- 11. 标签表 - 卡片的分类和标记
CREATE TABLE labels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 标签唯一标识符
    board_id UUID NOT NULL REFERENCES boards(id) ON DELETE CASCADE,  -- 所属看板ID
    name VARCHAR(100) NOT NULL,                             -- 标签名称，如"Bug"、"高优先级"
    color VARCHAR(7) NOT NULL DEFAULT '#61BD4F',            -- 标签颜色（十六进制）
    text_color VARCHAR(7) DEFAULT '#FFFFFF',                -- 文字颜色（自动计算或指定）
    description TEXT,                                       -- 标签描述
    position INTEGER DEFAULT 0,                             -- 在标签列表中的位置顺序
    is_archived BOOLEAN DEFAULT false,                      -- 标签是否已归档
    usage_count INTEGER DEFAULT 0,                          -- 使用次数统计
    created_by UUID REFERENCES users(id),                   -- 创建者
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 创建时间
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL           -- 最后更新时间
);

-- 12. 卡片标签关联表 - 卡片与标签的多对多关系
CREATE TABLE card_labels (
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,    -- 关联的卡片ID
    label_id UUID NOT NULL REFERENCES labels(id) ON DELETE CASCADE,  -- 关联的标签ID
    added_at TIMESTAMPTZ DEFAULT NOW(),                  -- 添加时间
    added_by UUID REFERENCES users(id),                  -- 添加者
    PRIMARY KEY (card_id, label_id)                      -- 复合主键
);

-- 13. 附件表 - 卡片附带的文件
CREATE TABLE attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 附件唯一标识符
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,  -- 所属卡片ID
    user_id UUID NOT NULL REFERENCES users(id),             -- 上传者ID
    file_name VARCHAR(255) NOT NULL,                        -- 原始文件名
    file_url TEXT NOT NULL,                                 -- 文件访问URL
    file_path TEXT,                                         -- 服务器存储路径
    file_size INTEGER,                                      -- 文件大小（字节）
    file_type VARCHAR(100),                                 -- 文件MIME类型
    mime_category VARCHAR(50),                              -- 文件分类: image/document/video/audio/other
    thumbnail_url TEXT,                                     -- 缩略图URL（图片/视频）
    preview_url TEXT,                                       -- 预览URL（文档）
    is_cover BOOLEAN DEFAULT false,                         -- 是否用作卡片封面
    is_uploaded BOOLEAN DEFAULT true,                       -- 是否已上传完成
    upload_progress INTEGER DEFAULT 100,                    -- 上传进度百分比
    width INTEGER,                                          -- 图片/视频宽度
    height INTEGER,                                         -- 图片/视频高度
    duration INTEGER,                                       -- 音频/视频时长（秒）
    pages INTEGER,                                          -- 文档页数
    metadata JSONB DEFAULT '{}',                            -- 文件元数据（EXIF信息等）
    downloads INTEGER DEFAULT 0,                            -- 下载次数统计
    views INTEGER DEFAULT 0,                                -- 查看次数统计
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 上传时间
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL           -- 最后更新时间
);

-- 14. 检查项表 - 卡片的子任务列表
CREATE TABLE checklists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 检查项列表唯一标识符
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,  -- 所属卡片ID
    title VARCHAR(255) NOT NULL,                            -- 检查项列表标题
    position INTEGER NOT NULL,                              -- 在卡片中的位置顺序
    is_collapsed BOOLEAN DEFAULT false,                     -- 是否折叠显示
    created_by UUID REFERENCES users(id),                   -- 创建者
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 创建时间
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL           -- 最后更新时间
);

-- 15. 检查项条目表 - 检查项的具体条目
CREATE TABLE checklist_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 检查项条目唯一标识符
    checklist_id UUID NOT NULL REFERENCES checklists(id) ON DELETE CASCADE,  -- 所属检查项列表ID
    content VARCHAR(500) NOT NULL,                          -- 条目内容
    is_completed BOOLEAN DEFAULT false,                     -- 是否已完成
    completed_at TIMESTAMPTZ,                               -- 完成时间
    completed_by UUID REFERENCES users(id),                 -- 完成者
    position INTEGER NOT NULL,                              -- 在列表中的位置顺序
    due_date TIMESTAMPTZ,                                   -- 截止日期
    assigned_to UUID REFERENCES users(id),                  -- 分配给的用户
    reminder_sent BOOLEAN DEFAULT false,                    -- 是否已发送提醒
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 创建时间
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL           -- 最后更新时间
);

-- 16. 邀请表 - 成员邀请管理
CREATE TABLE invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 邀请唯一标识符
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,  -- 工作空间邀请
    board_id UUID REFERENCES boards(id) ON DELETE CASCADE,          -- 看板直接邀请
    email VARCHAR(255) NOT NULL,                            -- 被邀请者邮箱
    token VARCHAR(100) UNIQUE NOT NULL,                     -- 邀请令牌，用于验证
    role VARCHAR(50) NOT NULL,                              -- 被邀请的角色
    permissions JSONB,                                      -- 自定义权限（可选）
    invited_by UUID NOT NULL REFERENCES users(id),          -- 邀请者ID
    message TEXT,                                           -- 邀请附加消息
    status VARCHAR(50) DEFAULT 'pending',                   -- 状态: pending/accepted/expired/revoked
    expires_at TIMESTAMPTZ NOT NULL,                        -- 邀请过期时间
    accepted_at TIMESTAMPTZ,                                -- 接受时间
    accepted_by UUID REFERENCES users(id),                  -- 接受者用户ID（如果已注册）
    resent_count INTEGER DEFAULT 0,                         -- 重新发送次数
    last_sent_at TIMESTAMPTZ,                               -- 最后发送时间
    source VARCHAR(50) DEFAULT 'email',                     -- 邀请来源: email/link/slack等
    metadata JSONB DEFAULT '{}',                            -- 邀请元数据
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 创建时间
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 最后更新时间
    CONSTRAINT valid_status CHECK (status IN ('pending', 'accepted', 'expired', 'revoked', 'declined'))
);

-- 17. 通知表 - 用户通知中心
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 通知唯一标识符
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,  -- 接收用户ID
    type VARCHAR(100) NOT NULL,                             -- 通知类型: card.assigned/comment.mentioned等
    title VARCHAR(255) NOT NULL,                            -- 通知标题
    content TEXT,                                           -- 通知内容
    content_html TEXT,                                      -- 通知内容HTML版本
    metadata JSONB DEFAULT '{}',                            -- 通知元数据，包含相关资源ID
    related_entity_type VARCHAR(50),                        -- 相关实体类型: card/comment/board等
    related_entity_id UUID,                                 -- 相关实体ID
    action_url TEXT,                                        -- 点击通知跳转的URL
    is_read BOOLEAN DEFAULT false,                          -- 是否已读
    read_at TIMESTAMPTZ,                                    -- 阅读时间
    is_archived BOOLEAN DEFAULT false,                      -- 是否已归档
    archived_at TIMESTAMPTZ,                                -- 归档时间
    priority VARCHAR(20) DEFAULT 'normal',                  -- 优先级: low/normal/high/urgent
    delivery_methods JSONB DEFAULT '["in_app"]',            -- 发送方式: ["in_app", "email", "push"]
    email_sent BOOLEAN DEFAULT false,                       -- 是否已发送邮件
    push_sent BOOLEAN DEFAULT false,                        -- 是否已发送推送
    expires_at TIMESTAMPTZ,                                 -- 通知过期时间
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 创建时间
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL           -- 最后更新时间
);

-- 18. 订阅表 - 用户对资源的订阅
CREATE TABLE subscriptions (
    id UUID PRIMARY DEFAULT gen_random_uuid(),              -- 订阅唯一标识符
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,    -- 订阅用户ID
    entity_type VARCHAR(50) NOT NULL,                       -- 实体类型: card/board/list
    entity_id UUID NOT NULL,                                -- 实体ID
    notification_types JSONB DEFAULT '["all"]',             -- 订阅的通知类型
    is_active BOOLEAN DEFAULT true,                         -- 订阅是否活跃
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 订阅时间
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 最后更新时间
    UNIQUE(user_id, entity_type, entity_id)                 -- 确保用户对同一资源只订阅一次
);

-- 19. 自定义字段表 - 看板自定义字段
CREATE TABLE custom_fields (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 自定义字段唯一标识符
    board_id UUID NOT NULL REFERENCES boards(id) ON DELETE CASCADE,  -- 所属看板ID
    name VARCHAR(100) NOT NULL,                             -- 字段名称
    type VARCHAR(50) NOT NULL,                              -- 字段类型: text/number/date/dropdown/checkbox/url
    description TEXT,                                       -- 字段描述
    position INTEGER DEFAULT 0,                             -- 显示位置顺序
    options JSONB DEFAULT '[]',                             -- 下拉选项（仅dropdown类型）
    default_value TEXT,                                     -- 默认值
    is_required BOOLEAN DEFAULT false,                      -- 是否必填
    show_on_card BOOLEAN DEFAULT true,                      -- 是否在卡片上显示
    is_active BOOLEAN DEFAULT true,                         -- 字段是否启用
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 创建时间
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 最后更新时间
    CONSTRAINT valid_type CHECK (type IN ('text', 'number', 'date', 'dropdown', 'checkbox', 'url', 'person'))
);

-- 20. 自定义字段值表 - 卡片自定义字段的值
CREATE TABLE custom_field_values (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 字段值唯一标识符
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,    -- 所属卡片ID
    field_id UUID NOT NULL REFERENCES custom_fields(id) ON DELETE CASCADE,  -- 字段ID
    value_text TEXT,                                        -- 文本值
    value_number DECIMAL(10, 2),                            -- 数字值
    value_date TIMESTAMPTZ,                                 -- 日期值
    value_boolean BOOLEAN,                                  -- 布尔值
    value_user UUID REFERENCES users(id),                   -- 用户类型值
    updated_by UUID REFERENCES users(id),                   -- 最后更新者
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 创建时间
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 最后更新时间
    UNIQUE(card_id, field_id)                               -- 确保卡片每个字段只有一个值
);

-- 21. 模板表 - 看板模板
CREATE TABLE templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 模板唯一标识符
    name VARCHAR(255) NOT NULL,                             -- 模板名称
    description TEXT,                                       -- 模板描述
    category VARCHAR(100) NOT NULL,                         -- 模板分类: project/team/personal/education
    thumbnail_url TEXT,                                     -- 模板缩略图URL
    content JSONB NOT NULL,                                 -- 模板内容（看板结构JSON）
    usage_count INTEGER DEFAULT 0,                          -- 使用次数统计
    is_featured BOOLEAN DEFAULT false,                      -- 是否精选模板
    is_public BOOLEAN DEFAULT true,                         -- 是否公开
    created_by UUID REFERENCES users(id),                   -- 创建者
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 创建时间
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL           -- 最后更新时间
);

-- 22. 投票表 - 卡片投票功能
CREATE TABLE votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 投票唯一标识符
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,    -- 所属卡片ID
    user_id UUID NOT NULL REFERENCES users(id),             -- 投票用户ID
    value INTEGER DEFAULT 1,                                -- 投票值（支持1-5星评分）
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 投票时间
    UNIQUE(card_id, user_id)                                -- 确保用户对同一卡片只投票一次
);

-- 23. 集成表 - 第三方集成配置
CREATE TABLE integrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 集成唯一标识符
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,  -- 关联的工作空间
    board_id UUID REFERENCES boards(id) ON DELETE CASCADE,          -- 关联的看板
    user_id UUID REFERENCES users(id),                      -- 关联的用户（个人集成）
    provider VARCHAR(50) NOT NULL,                          -- 集成提供商: slack/github/gitlab/google-drive
    name VARCHAR(100) NOT NULL,                             -- 集成自定义名称
    config JSONB NOT NULL,                                  -- 集成配置（令牌、webhook等）
    is_active BOOLEAN DEFAULT true,                         -- 集成是否启用
    last_sync_at TIMESTAMPTZ,                               -- 最后同步时间
    sync_status VARCHAR(50),                                -- 同步状态: success/failed/pending
    error_message TEXT,                                     -- 错误信息（如果同步失败）
    webhook_url TEXT,                                       -- 接收webhook的URL
    webhook_secret VARCHAR(100),                            -- webhook签名密钥
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 创建时间
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 最后更新时间
    UNIQUE(workspace_id, board_id, provider, name)          -- 确保同一资源下集成唯一
);

-- 24. 审核日志表 - 安全和管理审核
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 审核日志唯一标识符
    user_id UUID REFERENCES users(id),                      -- 执行操作的用户ID
    user_email VARCHAR(255),                                -- 用户邮箱（冗余，避免用户删除后丢失）
    action VARCHAR(100) NOT NULL,                           -- 操作类型: user.login/workspace.delete等
    resource_type VARCHAR(50),                              -- 资源类型: user/workspace/board
    resource_id UUID,                                       -- 资源ID
    resource_name VARCHAR(255),                             -- 资源名称（冗余）
    details JSONB DEFAULT '{}',                             -- 操作详情
    ip_address INET,                                        -- IP地址
    user_agent TEXT,                                        -- User-Agent
    location JSONB,                                         -- 地理位置信息
    is_successful BOOLEAN DEFAULT true,                     -- 操作是否成功
    error_message TEXT,                                     -- 错误信息
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL           -- 操作时间
);

-- 25. 文件存储表 - 统一的文件管理
CREATE TABLE file_storage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),          -- 文件唯一标识符
    user_id UUID REFERENCES users(id),                      -- 上传者
    workspace_id UUID REFERENCES workspaces(id),            -- 关联的工作空间
    board_id UUID REFERENCES boards(id),                    -- 关联的看板
    original_name VARCHAR(255) NOT NULL,                    -- 原始文件名
    storage_key VARCHAR(500) NOT NULL,                      -- 存储路径/键
    file_size INTEGER NOT NULL,                             -- 文件大小（字节）
    mime_type VARCHAR(100) NOT NULL,                        -- MIME类型
    category VARCHAR(50),                                   -- 文件分类
    metadata JSONB DEFAULT '{}',                            -- 文件元数据
    is_public BOOLEAN DEFAULT false,                        -- 是否公开访问
    access_count INTEGER DEFAULT 0,                         -- 访问次数
    last_accessed_at TIMESTAMPTZ,                           -- 最后访问时间
    expires_at TIMESTAMPTZ,                                 -- 过期时间（临时文件）
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,          -- 上传时间
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL           -- 最后更新时间
);