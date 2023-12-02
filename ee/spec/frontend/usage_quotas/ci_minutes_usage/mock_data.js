export const ciMinutesUsageMockData = {
  data: {
    ciMinutesUsage: {
      nodes: [
        {
          month: 'July',
          monthIso8601: '2021-07-01',
          minutes: 0,
          sharedRunnersDuration: 0,
          projects: {
            nodes: [],
          },
        },
        {
          month: 'June',
          monthIso8601: '2021-06-01',
          minutes: 5,
          sharedRunnersDuration: 120,
          projects: {
            nodes: [
              {
                name: 'devcafe-wp-theme',
                minutes: 5,
                sharedRunnersDuration: 120,
              },
            ],
          },
        },
      ],
    },
  },
};
