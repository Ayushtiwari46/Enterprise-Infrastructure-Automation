# Project Resumption Instructions

**Purpose:** This document dictates the mandatory, deterministic procedure to safely resume development if execution is stopped, paused, or restarted across turns.

---

## 1. Resumption Trigger
When the user states:
> **"RESUME INFRASTRUCTURE AUTOMATION PROJECT"**
or any prompt to continue work.

---

## 2. Mandatory Resumption Protocol

Follow this exact sequence. Do not skip steps.

1. **Read Current Checkpoint Pointer:**
   - Inspect `project-management/PROJECT_CHECKPOINT.md` to identify the active checkpoint ID (e.g. `CHK-001`).
2. **Read Active Checkpoint Manifest:**
   - Open `project-management/checkpoints/checkpoint_XXX.md` corresponding to the active pointer.
3. **Verify Master State:**
   - Review `project-management/PROJECT_STATUS.md` to identify the current phase and completed vs. pending tasks.
   - Review `project-management/TASK_REGISTER.md` for the exact next uncompleted task.
4. **Inspect File Inventory:**
   - Verify that all files listed in `project-management/FILE_INVENTORY.md` exist locally and remotely.
5. **Synchronize Controller State:**
   - Run `python scratch/sync_and_exec.py` to ensure all local workspace files are perfectly mirrored to `/root/Infrastructure-Automation/` on `192.168.242.132`.
6. **Execute Next Task:**
   - Continue development from the exact pending task in the Task Register.
   - Do NOT rebuild the repository from scratch.
   - Do NOT overwrite existing validated playbooks.
   - Do NOT reset progress counters.
