CREATE TABLE `common_matrial`  (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '自增ID',
  `uuid` varchar(255) NULL COMMENT '系统唯一ID',
  `source_id` varchar(255) NULL COMMENT '三方ID',
  `status` int NULL COMMENT '物料状态 1-有效 2-无效',
  `detail` text NULL COMMENT '物料详情 可存放json字段',
  `create_time` int NULL COMMENT '创建时间',
  `update_time` int NULL COMMENT '更新时间',
  PRIMARY KEY (`id`)
) COMMENT = '物料表';

CREATE TABLE `common_mps`  (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '自增ID',
  `matrial_id` int NOT NULL COMMENT '物料ID',
  `process_id` int NULL COMMENT '流程ID',
  `create_time` int NULL COMMENT '创建时间',
  `update_time` int NULL COMMENT '更新时间',
  PRIMARY KEY (`id`)
) COMMENT = '物料-流程-关联表';

CREATE TABLE `common_process`  (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `process_code` int NULL COMMENT '流程code',
  `process_name` varchar(255) NULL COMMENT '流程名称',
  `status` int NULL COMMENT '状态 1-处理中 2-处理成功 3-处理失败',
  `create_time` int NULL COMMENT '创建时间',
  `update_time` int NULL COMMENT '更新时间',
  PRIMARY KEY (`id`)
) COMMENT = '流程处理表';

ALTER TABLE `common_mps` ADD CONSTRAINT `fk_common_mps_common_mps_1` FOREIGN KEY (`matrial_id`) REFERENCES `common_matrial` (`id`);
ALTER TABLE `common_mps` ADD CONSTRAINT `fk_common_mps_common_mps_2` FOREIGN KEY (`process_id`) REFERENCES `common_process` (`id`);

