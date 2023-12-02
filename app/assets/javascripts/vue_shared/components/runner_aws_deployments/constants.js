import { s__, sprintf } from '~/locale';

export const README_URL =
  'https://gitlab.com/guided-explorations/aws/gitlab-runner-autoscaling-aws-asg/-/blob/main/easybuttons.md';

export const CF_BASE_URL =
  'https://us-west-2.console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/create/review?';

export const TEMPLATES_BASE_URL = 'https://gl-public-templates.s3.amazonaws.com/cfn/experimental/';

export const EASY_BUTTONS = [
  {
    stackName: 'linux-docker-nonspot',
    templateName:
      'easybutton-amazon-linux-2-docker-manual-scaling-with-schedule-ondemandonly.cf.yml',
    description: s__(
      'Runners|Amazon Linux 2 Docker HA with manual scaling and optional scheduling. Non-spot.',
    ),
    moreDetails1: s__('Runners|No spot. This is the default choice for Linux Docker executor.'),
    moreDetails2: s__(
      'Runners|A capacity of 1 enables warm HA through Auto Scaling group re-spawn. A capacity of 2 enables hot HA because the service is available even when a node is lost. A capacity of 3 or more enables hot HA and manual scaling of runner fleet.',
    ),
  },
  {
    stackName: 'linux-docker-spotonly',
    templateName: 'easybutton-amazon-linux-2-docker-manual-scaling-with-schedule-spotonly.cf.yml',
    description: sprintf(
      s__(
        'Runners|Amazon Linux 2 Docker HA with manual scaling and optional scheduling. %{percentage} spot.',
      ),
      { percentage: '100%' },
    ),
    moreDetails1: sprintf(s__('Runners|%{percentage} spot.'), { percentage: '100%' }),
    moreDetails2: s__(
      'Runners|Capacity of 1 enables warm HA through Auto Scaling group re-spawn. Capacity of 2 enables hot HA because the service is available even when a node is lost. Capacity of 3 or more enables hot HA and manual scaling of runner fleet.',
    ),
  },
  {
    stackName: 'win2019-shell-non-spot',
    templateName: 'easybutton-windows2019-shell-manual-scaling-with-scheduling-ondemandonly.cf.yml',
    description: s__(
      'Runners|Windows 2019 Shell with manual scaling and optional scheduling. Non-spot.',
    ),
    moreDetails1: s__('Runners|No spot. Default choice for Windows Shell executor.'),
    moreDetails2: s__(
      'Runners|Capacity of 1 enables warm HA through Auto Scaling group re-spawn. Capacity of 2 enables hot HA because the service is available even when a node is lost. Capacity of 3 or more enables hot HA and manual scaling of runner fleet.',
    ),
  },
  {
    stackName: 'win2019-shell-spot',
    templateName: 'easybutton-windows2019-shell-manual-scaling-with-scheduling-spotonly.cf.yml',
    description: sprintf(
      s__(
        'Runners|Windows 2019 Shell with manual scaling and optional scheduling. %{percentage} spot.',
      ),
      { percentage: '100%' },
    ),
    moreDetails1: sprintf(s__('Runners|%{percentage} spot.'), { percentage: '100%' }),
    moreDetails2: s__(
      'Runners|Capacity of 1 enables warm HA through Auto Scaling group re-spawn. Capacity of 2 enables hot HA because the service is available even when a node is lost. Capacity of 3 or more enables hot HA and manual scaling of runner fleet.',
    ),
  },
];
