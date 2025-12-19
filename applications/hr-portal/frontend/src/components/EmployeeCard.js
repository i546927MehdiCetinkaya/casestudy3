import React from 'react';

const EmployeeCard = ({ employee, onProvisionWorkspace, onDeleteWorkspace, workspace, provisioningStatus }) => {
  const getStatusColor = (status) => {
    switch (status) {
      case 'active': return 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20';
      case 'terminated': return 'bg-gray-500/10 text-gray-400 border-gray-500/20';
      default: return 'bg-gray-500/10 text-gray-400 border-gray-500/20';
    }
  };

  const getRoleColor = (role) => {
    switch (role) {
      case 'developer': return 'bg-blue-500/10 text-blue-400 border-blue-500/20';
      case 'hr-admin': return 'bg-red-500/10 text-red-400 border-red-500/20';
      case 'manager': return 'bg-purple-500/10 text-purple-400 border-purple-500/20';
      default: return 'bg-gray-500/10 text-gray-400 border-gray-500/20';
    }
  };

  const isTerminated = employee.status === 'terminated';
  const hasActiveWorkspace = workspace && workspace.status !== 'terminated';

  return (
    <div className={`
      relative group flex flex-col
      bg-slate-800/50 backdrop-blur-sm 
      border border-slate-700/50 hover:border-slate-600 
      rounded-xl p-5 
      transition-all duration-200 hover:shadow-lg hover:shadow-slate-900/20
      ${isTerminated ? 'opacity-75 hover:opacity-100 grayscale' : ''}
    `}>
      {/* Header Section */}
      <div className="flex justify-between items-start mb-4">
        <div className="flex items-center space-x-3">
          <div className="h-12 w-12 rounded-full bg-slate-700 flex items-center justify-center text-slate-300 font-semibold text-lg border border-slate-600">
            {employee.firstName?.[0]}{employee.lastName?.[0]}
          </div>
          <div>
            <h3 className="text-base font-semibold text-slate-100 leading-tight">
              {employee.firstName} {employee.lastName}
            </h3>
            <p className="text-xs text-slate-400 mt-1 font-mono truncate max-w-[180px]">
              {employee.email}
            </p>
          </div>
        </div>
        <button className="text-slate-500 hover:text-slate-300 transition-colors p-1 rounded hover:bg-slate-700/50">
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
          </svg>
        </button>
      </div>

      {/* Tags Section */}
      <div className="flex flex-wrap gap-2 mb-5">
        <span className={`px-2 py-1 rounded-md text-xs font-medium border ${getRoleColor(employee.role)}`}>
          {employee.role}
        </span>
        <span className={`px-2 py-1 rounded-md text-xs font-medium border ${getStatusColor(employee.status)}`}>
          {employee.status}
        </span>
      </div>

      {/* Department Field */}
      <div className="mb-6">
        <div className="flex items-center space-x-2 text-slate-400 text-sm bg-slate-900/40 py-2 px-3 rounded-lg border border-slate-800">
          <svg className="w-4 h-4 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
          </svg>
          <span>{employee.department}</span>
        </div>
      </div>

      {/* Footer / Actions */}
      <div className="mt-auto">
        {provisioningStatus ? (
          <div className="w-full py-2 px-4 bg-yellow-500/10 text-yellow-400 text-sm font-medium rounded-lg border border-yellow-500/20 flex items-center justify-center gap-2">
            <svg className="animate-spin h-4 w-4" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            {provisioningStatus}
          </div>
        ) : hasActiveWorkspace ? (
          <div className="space-y-2">
            <div className="flex items-center justify-between text-xs text-emerald-400 mb-2 px-1">
              <span className="flex items-center gap-1.5">
                <span className="relative flex h-2 w-2">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
                </span>
                Workspace Active
              </span>
              <span className="text-slate-500 text-[10px]">ID: WS-{workspace.workspaceId?.slice(0,4)}</span>
            </div>
            <button 
              onClick={() => window.open(workspace.url || `https://${workspace.dnsName}:${workspace.nodePort}`, '_blank')}
              className="w-full py-2 px-4 bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 text-sm font-medium rounded-lg border border-emerald-500/20 transition-colors flex items-center justify-center gap-2 group-hover:border-emerald-500/40"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
              </svg>
              View Credentials
            </button>
            {onDeleteWorkspace && (
              <button 
                onClick={() => onDeleteWorkspace(workspace.workspaceId)}
                className="w-full py-2 px-4 bg-red-500/10 hover:bg-red-500/20 text-red-400 text-sm font-medium rounded-lg border border-red-500/20 transition-colors flex items-center justify-center gap-2"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
                Delete Workspace
              </button>
            )}
          </div>
        ) : (
          <button 
            disabled={isTerminated}
            onClick={() => onProvisionWorkspace && onProvisionWorkspace(employee.employeeId)}
            className={`
              w-full py-2 px-4 text-sm font-medium rounded-lg border flex items-center justify-center gap-2
              transition-colors
              ${isTerminated
                ? 'bg-slate-800 text-slate-500 border-slate-700 cursor-not-allowed opacity-60' 
                : 'bg-indigo-600 hover:bg-indigo-500 text-white border-transparent shadow-lg shadow-indigo-900/20'}
            `}
          >
            {isTerminated ? (
              <>
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
                Terminated
              </>
            ) : (
              <>
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
                Provision Workspace
              </>
            )}
          </button>
        )}
      </div>
    </div>
  );
};

export default EmployeeCard;
