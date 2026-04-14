import pandas as pd
import matplotlib.pyplot as plt
import os

# --- НАСТРОЙКИ ПУТЕЙ ---
log_dir = '/root/catkin_ws/src/cv8_traj/logs/'
joint_log_path = os.path.join(log_dir, 'cv8_traj_joint_log.csv')
tool_log_path = os.path.join(log_dir, 'cv8_traj_tool_log.csv')

def plot_joint_logs(path):
    """Визуализация графиков q, qd, qdd для одного или трех суставов"""
    if not os.path.exists(path):
        print(f"[-] Файл суставов не найден: {path}")
        return

    print(f"[+] Чтение лога суставов: {path}")
    df = pd.read_csv(path)

    # Проверка на пустой файл
    if df.empty:
        print("[-] Файл пуст!")
        return

    t = df['t'].values

    # Новый формат: t,q_j1,qd_j1,qdd_j1,q_j2,qd_j2,qdd_j2,...
    joint_ids = sorted({
        int(col.split('_j')[1])
        for col in df.columns
        if col.startswith('q_j')
    })

    if joint_ids:
        # ограничиваемся первыми тремя, чтобы график был читаемым
        joint_ids = joint_ids[:3]
        fig, axs = plt.subplots(len(joint_ids), 1, figsize=(10, 10), sharex=True)
        if len(joint_ids) == 1:
            axs = [axs]
        fig.suptitle('анализ движения трех выбранных суставов', fontsize=16)

        for i, joint_id in enumerate(joint_ids):
            q_col = f'q_j{joint_id}'
            qd_col = f'qd_j{joint_id}'
            qdd_col = f'qdd_j{joint_id}'

            axs[i].plot(t, df[q_col].values, color='tab:red', label=f'joint {joint_id}: q')
            axs[i].plot(t, df[qd_col].values, color='tab:purple', label=f'joint {joint_id}: qd')
            axs[i].plot(t, df[qdd_col].values, color='tab:green', label=f'joint {joint_id}: qdd')
            axs[i].set_ylabel('рад / рад/с / рад/с²')
            axs[i].grid(True, linestyle='--')
            axs[i].legend(loc='upper right')

        axs[-1].set_xlabel('Время [с]')
    else:
        # старый формат: t,q,qd,qdd
        fig, axs = plt.subplots(3, 1, figsize=(10, 10), sharex=True)
        fig.suptitle('анализ движения выбранного сустава', fontsize=16)

        q = df['q'].values
        qd = df['qd'].values
        qdd = df['qdd'].values

        axs[0].plot(t, q, color='blue', label='позиция (q)')
        axs[0].set_ylabel('угол [рад]')
        axs[0].grid(True, linestyle='--')
        axs[0].legend(loc='upper right')

        axs[1].plot(t, qd, color='red', label='скорость (qd)')
        axs[1].set_ylabel('рад/с')
        axs[1].grid(True, linestyle='--')
        axs[1].legend(loc='upper right')

        axs[2].plot(t, qdd, color='green', label='ускорение (qdd)')
        axs[2].set_ylabel('рад/с²')
        axs[2].set_xlabel('Время [с]')
        axs[2].grid(True, linestyle='--')
        axs[2].legend(loc='upper right')

    plt.tight_layout(rect=[0, 0.03, 1, 0.95])

def plot_tool_logs(path):
    """Визуализация 3D траектории инструмента"""
    if not os.path.exists(path):
        return

    print(f"[+] Чтение лога инструмента: {path}")
    df = pd.read_csv(path)

    fig = plt.figure(figsize=(10, 7))
    ax = fig.add_subplot(111, projection='3d')
    
    # Используем .values для осей X, Y, Z
    ax.plot(df['x'].values, df['y'].values, df['z'].values, 
            label='TCP Path', color='magenta', linewidth=2)

    ax.set_xlabel('X [м]')
    ax.set_ylabel('Y [м]')
    ax.set_zlabel('Z [м]')
    ax.set_title('3D Траектория инструмента')
    ax.set_box_aspect((1, 1, 1)) 
    plt.legend()

if __name__ == "__main__":
    plot_joint_logs(joint_log_path)
    plot_tool_logs(tool_log_path)
    
    if not os.path.exists(joint_log_path) and not os.path.exists(tool_log_path):
        print("!!! ОШИБКА: Файлы логов не найдены.")
    else:
        print("[*] Отображение графиков...")
        plt.show()