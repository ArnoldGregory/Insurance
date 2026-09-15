USE insurance_platform;

CREATE TABLE Menus (
    menu_id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    parent_menu_id     BIGINT UNSIGNED NULL,
    label                VARCHAR(100) NOT NULL,
    icon                   VARCHAR(50) NULL,
    url                      VARCHAR(255) NULL,
    sort_order                 INT NOT NULL DEFAULT 0,
    is_active                    TINYINT(1) NOT NULL DEFAULT 1,
    created_by                     BIGINT UNSIGNED NULL,
    created_on                       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_menu_parent     FOREIGN KEY (parent_menu_id) REFERENCES Menus(menu_id) ON DELETE CASCADE,
    CONSTRAINT fk_menu_created_by FOREIGN KEY (created_by)     REFERENCES Users(user_id)  ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_menu_parent ON Menus(parent_menu_id, sort_order);

CREATE TABLE RoleMenus (
    role_id  BIGINT UNSIGNED NOT NULL,
    menu_id  BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (role_id, menu_id),
    CONSTRAINT fk_rm_role FOREIGN KEY (role_id) REFERENCES Roles(role_id) ON DELETE CASCADE,
    CONSTRAINT fk_rm_menu FOREIGN KEY (menu_id) REFERENCES Menus(menu_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO Permissions (code, description) VALUES
    ('MANAGE_MENUS', 'Add/edit Admin Portal menu items and control which roles can see them');

INSERT INTO RolePermissions (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM Roles r, Permissions p
WHERE r.role_code = 'SA' AND p.code = 'MANAGE_MENUS';
