export const mockStages = [
  {
    name: 'build',
    title: 'build: passed',
    status: {
      __typename: 'DetailedStatus',
      id: 'success-409-409',
      icon: 'status_success',
      text: 'passed',
      label: 'passed',
      group: 'success',
      tooltip: 'passed',
      has_details: true,
      details_path: '/root/ci-project/-/pipelines/318#build',
      illustration: null,
      favicon:
        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
    },
    path: '/root/ci-project/-/pipelines/318#build',
    dropdown_path: '/root/ci-project/-/pipelines/318/stage.json?stage=build',
  },
];

export const mockPipelineStagesQueryResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/20',
      pipeline: {
        id: 'gid://gitlab/Ci::Pipeline/320',
        stages: {
          nodes: [
            {
              __typename: 'CiStage',
              id: 'gid://gitlab/Ci::Stage/409',
              name: 'build',
              detailedStatus: {
                id: 'success-409-409',
                group: 'success',
                icon: 'status_success',
                __typename: 'DetailedStatus',
              },
            },
          ],
        },
      },
    },
  },
};

export const mockPipelineStatusResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/20',
      pipeline: {
        id: 'gid://gitlab/Ci::Pipeline/320',
        detailedStatus: {
          id: 'pending-320-320',
          detailsPath: '/root/ci-project/-/pipelines/320',
          icon: 'status_pending',
          group: 'pending',
          __typename: 'DetailedStatus',
        },
        __typename: 'Pipeline',
      },
      __typename: 'Project',
    },
  },
};

export const mockDownstreamQueryResponse = {
  data: {
    project: {
      id: '1',
      pipeline: {
        path: '/root/ci-project/-/pipelines/790',
        id: 'pipeline-1',
        downstream: {
          nodes: [
            {
              id: 'gid://gitlab/Ci::Pipeline/612',
              path: '/root/job-log-sections/-/pipelines/612',
              project: { id: '1', name: 'job-log-sections', __typename: 'Project' },
              detailedStatus: {
                id: 'status-1',
                group: 'success',
                icon: 'status_success',
                label: 'passed',
                __typename: 'DetailedStatus',
              },
              __typename: 'Pipeline',
            },
          ],
          __typename: 'PipelineConnection',
        },
        upstream: null,
      },
      __typename: 'Project',
    },
  },
};

export const mockUpstreamDownstreamQueryResponse = {
  data: {
    project: {
      id: '1',
      pipeline: {
        id: 'pipeline-1',
        path: '/root/ci-project/-/pipelines/790',
        downstream: {
          nodes: [
            {
              id: 'gid://gitlab/Ci::Pipeline/612',
              path: '/root/job-log-sections/-/pipelines/612',
              project: { id: '1', name: 'job-log-sections', __typename: 'Project' },
              detailedStatus: {
                id: 'status-1',
                group: 'success',
                icon: 'status_success',
                label: 'passed',
                __typename: 'DetailedStatus',
              },
              __typename: 'Pipeline',
            },
          ],
          __typename: 'PipelineConnection',
        },
        upstream: {
          id: 'gid://gitlab/Ci::Pipeline/610',
          path: '/root/trigger-downstream/-/pipelines/610',
          project: { id: '1', name: 'trigger-downstream', __typename: 'Project' },
          detailedStatus: {
            id: 'status-1',
            group: 'success',
            icon: 'status_success',
            label: 'passed',
            __typename: 'DetailedStatus',
          },
          __typename: 'Pipeline',
        },
      },
      __typename: 'Project',
    },
  },
};

export const mockUpstreamQueryResponse = {
  data: {
    project: {
      id: '1',
      pipeline: {
        id: 'pipeline-1',
        path: '/root/ci-project/-/pipelines/790',
        downstream: {
          nodes: [],
          __typename: 'PipelineConnection',
        },
        upstream: {
          id: 'gid://gitlab/Ci::Pipeline/610',
          path: '/root/trigger-downstream/-/pipelines/610',
          project: { id: '1', name: 'trigger-downstream', __typename: 'Project' },
          detailedStatus: {
            id: 'status-1',
            group: 'success',
            icon: 'status_success',
            label: 'passed',
            __typename: 'DetailedStatus',
          },
          __typename: 'Pipeline',
        },
      },
      __typename: 'Project',
    },
  },
};
