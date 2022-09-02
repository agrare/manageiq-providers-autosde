class ManageIQ::Providers::Autosde::StorageManager::EmsRefreshWorkflow < ManageIQ::Providers::EmsRefreshWorkflow
  def run_native_op
    queue_signal(:poll_native_task)
  end
  alias start run_native_op

  def poll_native_task
    case autosde_client.JobApi.jobs_pk_get(options[:native_task_id]).status
    when "FAILURE"
      signal(:abort, "Task failed")
    when "SUCCESS"
      queue_signal(:refresh)
    else
      queue_signal(:poll_native_task, :deliver_on => Time.now.utc + 1.minute)
    end
  rescue => err
    _log.log_backtrace(err)
    signal(:abort, err.message, "error ADRIAN")
  end

  def autosde_client
    @autosde_client ||= ext_management_system.autosde_client
  end

  def ext_management_system
    @ext_management_system ||= ExtManagementSystem.find(options[:ems_id])
  end
end
