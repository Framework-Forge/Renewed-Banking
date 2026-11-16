CREATE TABLE IF NOT EXISTS `bank_accounts_new` (
  `id` varchar(50) NOT NULL,
  `amount` int(11) DEFAULT 0,
  `transactions` longtext DEFAULT '[]',
  `auth` longtext DEFAULT '[]',
  `isFrozen` int(11) DEFAULT 0,
  `creator` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `player_transactions` (
  `id` varchar(50) NOT NULL,
  `isFrozen` int(11) DEFAULT 0,
  `transactions` longtext DEFAULT '[]',
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `renewed_invoices` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(120) DEFAULT NULL,
  `recipient` varchar(60) NOT NULL,
  `issuer_resource` varchar(80) NOT NULL,
  `issuer` varchar(120) NOT NULL,
  `receiver_account` varchar(50) DEFAULT NULL,
  `title` varchar(120) NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  `principal` int unsigned NOT NULL,
  `interest_rate` decimal(8,4) NOT NULL DEFAULT 0,
  `interest_interval` enum('hour','day') NOT NULL DEFAULT 'day',
  `due_at` bigint NOT NULL,
  `status` enum('active','processing','paid','cancelled') NOT NULL DEFAULT 'active',
  `metadata` longtext DEFAULT NULL,
  `created_at` bigint NOT NULL,
  `paid_at` bigint DEFAULT NULL,
  `paid_amount` int unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_invoice_external` (`issuer_resource`,`external_id`),
  KEY `idx_invoice_recipient_status` (`recipient`,`status`),
  KEY `idx_invoice_due` (`due_at`)
);

CREATE TABLE IF NOT EXISTS `renewed_invoice_settings` (
  `id` tinyint unsigned NOT NULL,
  `settings` longtext NOT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `renewed_account_members` (
  `account_id` varchar(60) NOT NULL,
  `member_cid` varchar(60) NOT NULL,
  `member_name` varchar(120) NOT NULL,
  `can_withdraw` tinyint(1) NOT NULL DEFAULT 0,
  `can_transfer` tinyint(1) NOT NULL DEFAULT 0,
  `can_pay_invoices` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` bigint NOT NULL,
  `updated_at` bigint NOT NULL,
  PRIMARY KEY (`account_id`,`member_cid`),
  KEY `idx_renewed_member` (`member_cid`)
);
