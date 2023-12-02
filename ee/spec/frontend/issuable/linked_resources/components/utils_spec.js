import {
  displayAndLogError,
  getLinkIcon,
  identifyLinkType,
} from 'ee/linked_resources/components/utils';
import { createAlert } from '~/flash';

jest.mock('~/flash');

describe('resource links utils', () => {
  describe('display and log error', () => {
    it('displays and logs an error', () => {
      const error = new Error('test');
      displayAndLogError(error);

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while fetching linked resources for the incident.',
        captureError: true,
        error,
      });
    });
  });

  describe('get link icon', () => {
    it('should display a matching link icon name', () => {
      const name = 'zoom';
      const iconName = 'brand-zoom';

      expect(getLinkIcon(name)).toBe(iconName);
    });

    it('should return a default icon name', () => {
      expect(getLinkIcon('random-link-type')).toBe('external-link');
    });
  });

  describe('identify link type', () => {
    it.each`
      link                                             | linkType
      ${'https://gitlab.zoom.us/j/incident-room'}      | ${'zoom'}
      ${'https://zoom.us/j/1123433'}                   | ${'zoom'}
      ${'https://gitlab.zoom.us/my/1123433'}           | ${'zoom'}
      ${'https://gitlab.slack.com/archives/dummy-id'}  | ${'slack'}
      ${'https://company.slack.com/archives/dummy-id'} | ${'slack'}
      ${'https://slack.slack.com/messages/dummy-id-2'} | ${'slack'}
      ${'https://docs.gitlab.com/doc-page'}            | ${'general'}
      ${'https://random-url.com/doc-page'}             | ${'general'}
      ${'https://google.com/email/gmail'}              | ${'general'}
    `('returns $linkType for $link', ({ link, linkType }) => {
      expect(identifyLinkType(link)).toBe(linkType);
    });
  });
});
