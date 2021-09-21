USE `es_extended`;

CREATE TABLE `eInventoryLite` (
	`id` varchar(50) NOT NULL,
	`identifier` varchar(60) NOT NULL,
    `name` varchar(50) NOT NULL,
    `slot` varchar(50),
    `type` varchar(50) NOT NULL,

	PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;