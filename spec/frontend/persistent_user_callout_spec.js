import MockAdapter from 'axios-mock-adapter';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import PersistentUserCallout from '~/persistent_user_callout';

jest.mock('~/flash');

describe('PersistentUserCallout', () => {
  const dismissEndpoint = '/dismiss';
  const featureName = 'feature';
  const groupId = '5';

  function createFixture() {
    const fixture = document.createElement('div');
    fixture.innerHTML = `
      <div
        class="container"
        data-dismiss-endpoint="${dismissEndpoint}"
        data-feature-id="${featureName}"
        data-group-id="${groupId}"
      >
        <button type="button" class="js-close js-close-primary"></button>
        <button type="button" class="js-close js-close-secondary"></button>
      </div>
    `;

    return fixture;
  }

  function createDeferredLinkFixture() {
    const fixture = document.createElement('div');
    fixture.innerHTML = `
      <div
        class="container"
        data-dismiss-endpoint="${dismissEndpoint}"
        data-feature-id="${featureName}"
        data-defer-links="true"
      >
        <button type="button" class="js-close"></button>
        <a href="/somewhere-pleasant" target="_blank" class="deferred-link">A link</a>
        <a href="/somewhere-else" target="_blank" class="normal-link">Another link</a>
      </div>
    `;

    return fixture;
  }

  function createFollowLinkFixture() {
    const fixture = document.createElement('div');
    fixture.innerHTML = `
      <ul>
        <li
          class="container"
          data-dismiss-endpoint="${dismissEndpoint}"
          data-feature-id="${featureName}"
        >
          <a class="js-follow-link" href="/somewhere-pleasant">A Link</a>
        </li>
      </ul>
  `;

    return fixture;
  }

  describe('dismiss', () => {
    const buttons = {};
    let mockAxios;
    let persistentUserCallout;

    beforeEach(() => {
      const fixture = createFixture();
      const container = fixture.querySelector('.container');
      buttons.primary = fixture.querySelector('.js-close-primary');
      buttons.secondary = fixture.querySelector('.js-close-secondary');
      mockAxios = new MockAdapter(axios);
      persistentUserCallout = new PersistentUserCallout(container);
      jest.spyOn(persistentUserCallout.container, 'remove').mockImplementation(() => {});
    });

    afterEach(() => {
      mockAxios.restore();
    });

    it.each`
      button
      ${'primary'}
      ${'secondary'}
    `('POSTs endpoint and removes container when clicking $button close', async ({ button }) => {
      mockAxios.onPost(dismissEndpoint).replyOnce(200);

      buttons[button].click();

      await waitForPromises();

      expect(persistentUserCallout.container.remove).toHaveBeenCalled();
      expect(mockAxios.history.post[0].data).toBe(
        JSON.stringify({ feature_name: featureName, group_id: groupId }),
      );
    });

    it('invokes Flash when the dismiss request fails', async () => {
      mockAxios.onPost(dismissEndpoint).replyOnce(500);

      buttons.primary.click();

      await waitForPromises();

      expect(persistentUserCallout.container.remove).not.toHaveBeenCalled();
      expect(createFlash).toHaveBeenCalledWith({
        message: 'An error occurred while dismissing the alert. Refresh the page and try again.',
      });
    });
  });

  describe('deferred links', () => {
    let button;
    let deferredLink;
    let normalLink;
    let mockAxios;
    let persistentUserCallout;
    let windowSpy;

    beforeEach(() => {
      const fixture = createDeferredLinkFixture();
      const container = fixture.querySelector('.container');
      button = fixture.querySelector('.js-close');
      deferredLink = fixture.querySelector('.deferred-link');
      normalLink = fixture.querySelector('.normal-link');
      mockAxios = new MockAdapter(axios);
      persistentUserCallout = new PersistentUserCallout(container);
      jest.spyOn(persistentUserCallout.container, 'remove').mockImplementation(() => {});
      windowSpy = jest.spyOn(window, 'open').mockImplementation(() => {});
    });

    afterEach(() => {
      mockAxios.restore();
    });

    it('defers loading of a link until callout is dismissed', async () => {
      const { href, target } = deferredLink;
      mockAxios.onPost(dismissEndpoint).replyOnce(200);

      deferredLink.click();

      await waitForPromises();

      expect(windowSpy).toHaveBeenCalledWith(href, target);
      expect(persistentUserCallout.container.remove).toHaveBeenCalled();
      expect(mockAxios.history.post[0].data).toBe(JSON.stringify({ feature_name: featureName }));
    });

    it('does not dismiss callout on non-deferred links', async () => {
      normalLink.click();

      await waitForPromises();

      expect(windowSpy).not.toHaveBeenCalled();
      expect(persistentUserCallout.container.remove).not.toHaveBeenCalled();
    });

    it('does not follow link when notification is closed', async () => {
      mockAxios.onPost(dismissEndpoint).replyOnce(200);

      button.click();

      await waitForPromises();

      expect(windowSpy).not.toHaveBeenCalled();
      expect(persistentUserCallout.container.remove).toHaveBeenCalled();
    });
  });

  describe('follow links', () => {
    let link;
    let mockAxios;
    let persistentUserCallout;

    useMockLocationHelper();

    beforeEach(() => {
      const fixture = createFollowLinkFixture();
      const container = fixture.querySelector('.container');
      link = fixture.querySelector('.js-follow-link');
      mockAxios = new MockAdapter(axios);

      persistentUserCallout = new PersistentUserCallout(container);
      jest.spyOn(persistentUserCallout.container, 'remove').mockImplementation(() => {});
    });

    afterEach(() => {
      mockAxios.restore();
    });

    it('uses a link to trigger callout and defers following until callout is finished', async () => {
      const { href } = link;
      mockAxios.onPost(dismissEndpoint).replyOnce(200);

      link.click();

      await waitForPromises();

      expect(window.location.assign).toHaveBeenCalledWith(href);
      expect(persistentUserCallout.container.remove).not.toHaveBeenCalled();
      expect(mockAxios.history.post[0].data).toBe(JSON.stringify({ feature_name: featureName }));
    });

    it('invokes Flash when the dismiss request fails', async () => {
      mockAxios.onPost(dismissEndpoint).replyOnce(500);

      link.click();

      await waitForPromises();

      expect(window.location.assign).not.toHaveBeenCalled();
      expect(createFlash).toHaveBeenCalledWith({
        message:
          'An error occurred while acknowledging the notification. Refresh the page and try again.',
      });
    });
  });

  describe('factory', () => {
    it('returns an instance of PersistentUserCallout with the provided container property', () => {
      const fixture = createFixture();

      expect(PersistentUserCallout.factory(fixture) instanceof PersistentUserCallout).toBe(true);
    });

    it('returns undefined if container is falsey', () => {
      expect(PersistentUserCallout.factory()).toBe(undefined);
    });
  });
});
