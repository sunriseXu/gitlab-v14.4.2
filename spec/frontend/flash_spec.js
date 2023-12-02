import * as Sentry from '@sentry/browser';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import createFlash, {
  hideFlash,
  addDismissFlashClickListener,
  FLASH_TYPES,
  FLASH_CLOSED_EVENT,
  createAlert,
  VARIANT_WARNING,
} from '~/flash';

jest.mock('@sentry/browser');

describe('Flash', () => {
  describe('hideFlash', () => {
    let el;

    beforeEach(() => {
      el = document.createElement('div');
      el.className = 'js-testing';
    });

    it('sets transition style', () => {
      hideFlash(el);

      expect(el.style.transition).toBe('opacity 0.15s');
    });

    it('sets opacity style', () => {
      hideFlash(el);

      expect(el.style.opacity).toBe('0');
    });

    it('does not set styles when fadeTransition is false', () => {
      hideFlash(el, false);

      expect(el.style.opacity).toBe('');
      expect(el.style.transition).toHaveLength(0);
    });

    it('removes element after transitionend', () => {
      document.body.appendChild(el);

      hideFlash(el);
      el.dispatchEvent(new Event('transitionend'));

      expect(document.querySelector('.js-testing')).toBeNull();
    });

    it('calls event listener callback once', () => {
      jest.spyOn(el, 'remove');
      document.body.appendChild(el);

      hideFlash(el);

      el.dispatchEvent(new Event('transitionend'));
      el.dispatchEvent(new Event('transitionend'));

      expect(el.remove.mock.calls.length).toBe(1);
    });

    it(`dispatches ${FLASH_CLOSED_EVENT} event after transitionend event`, () => {
      jest.spyOn(el, 'dispatchEvent');

      hideFlash(el);

      el.dispatchEvent(new Event('transitionend'));

      expect(el.dispatchEvent).toHaveBeenCalledWith(new Event(FLASH_CLOSED_EVENT));
    });
  });

  describe('createAlert', () => {
    const mockMessage = 'a message';
    let alert;

    describe('no flash-container', () => {
      it('does not add to the DOM', () => {
        alert = createAlert({ message: mockMessage });

        expect(alert).toBeNull();
        expect(document.querySelector('.gl-alert')).toBeNull();
      });
    });

    describe('with flash-container', () => {
      beforeEach(() => {
        setHTMLFixture('<div class="flash-container"></div>');
      });

      afterEach(() => {
        if (alert) {
          alert.$destroy();
        }
        resetHTMLFixture();
      });

      it('adds alert element into the document by default', () => {
        alert = createAlert({ message: mockMessage });

        expect(document.querySelector('.flash-container').textContent.trim()).toBe(mockMessage);
        expect(document.querySelector('.flash-container .gl-alert')).not.toBeNull();
      });

      it('adds flash of a warning type', () => {
        alert = createAlert({ message: mockMessage, variant: VARIANT_WARNING });

        expect(
          document.querySelector('.flash-container .gl-alert.gl-alert-warning'),
        ).not.toBeNull();
      });

      it('escapes text', () => {
        alert = createAlert({ message: '<script>alert("a");</script>' });

        const html = document.querySelector('.flash-container').innerHTML;

        expect(html).toContain('&lt;script&gt;alert("a");&lt;/script&gt;');
        expect(html).not.toContain('<script>alert("a");</script>');
      });

      it('adds alert into specified container', () => {
        setHTMLFixture(`
            <div class="my-alert-container"></div>
            <div class="my-other-container"></div>
        `);

        alert = createAlert({ message: mockMessage, containerSelector: '.my-alert-container' });

        expect(document.querySelector('.my-alert-container .gl-alert')).not.toBeNull();
        expect(document.querySelector('.my-alert-container').innerText.trim()).toBe(mockMessage);

        expect(document.querySelector('.my-other-container .gl-alert')).toBeNull();
        expect(document.querySelector('.my-other-container').innerText.trim()).toBe('');
      });

      it('adds alert into specified parent', () => {
        setHTMLFixture(`
            <div id="my-parent">
              <div class="flash-container"></div>
            </div>
            <div id="my-other-parent">
              <div class="flash-container"></div>
            </div>
        `);

        alert = createAlert({ message: mockMessage, parent: document.getElementById('my-parent') });

        expect(document.querySelector('#my-parent .flash-container .gl-alert')).not.toBeNull();
        expect(document.querySelector('#my-parent .flash-container').innerText.trim()).toBe(
          mockMessage,
        );

        expect(document.querySelector('#my-other-parent .flash-container .gl-alert')).toBeNull();
        expect(document.querySelector('#my-other-parent .flash-container').innerText.trim()).toBe(
          '',
        );
      });

      it('removes element after clicking', () => {
        alert = createAlert({ message: mockMessage });

        expect(document.querySelector('.flash-container .gl-alert')).not.toBeNull();

        document.querySelector('.gl-dismiss-btn').click();

        expect(document.querySelector('.flash-container .gl-alert')).toBeNull();
      });

      it('does not capture error using Sentry', () => {
        alert = createAlert({
          message: mockMessage,
          captureError: false,
          error: new Error('Error!'),
        });

        expect(Sentry.captureException).not.toHaveBeenCalled();
      });

      it('captures error using Sentry', () => {
        alert = createAlert({
          message: mockMessage,
          captureError: true,
          error: new Error('Error!'),
        });

        expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Error));
        expect(Sentry.captureException).toHaveBeenCalledWith(
          expect.objectContaining({
            message: 'Error!',
          }),
        );
      });

      describe('with buttons', () => {
        const findAlertAction = () => document.querySelector('.flash-container .gl-alert-action');

        it('adds primary button', () => {
          alert = createAlert({
            message: mockMessage,
            primaryButton: {
              text: 'Ok',
            },
          });

          expect(findAlertAction().textContent.trim()).toBe('Ok');
        });

        it('creates link with href', () => {
          alert = createAlert({
            message: mockMessage,
            primaryButton: {
              link: '/url',
              text: 'Ok',
            },
          });

          const action = findAlertAction();

          expect(action.textContent.trim()).toBe('Ok');
          expect(action.nodeName).toBe('A');
          expect(action.getAttribute('href')).toBe('/url');
        });

        it('create button as href when no href is present', () => {
          alert = createAlert({
            message: mockMessage,
            primaryButton: {
              text: 'Ok',
            },
          });

          const action = findAlertAction();

          expect(action.nodeName).toBe('BUTTON');
          expect(action.getAttribute('href')).toBe(null);
        });

        it('escapes the title text', () => {
          alert = createAlert({
            message: mockMessage,
            primaryButton: {
              text: '<script>alert("a")</script>',
            },
          });

          const html = findAlertAction().innerHTML;

          expect(html).toContain('&lt;script&gt;alert("a")&lt;/script&gt;');
          expect(html).not.toContain('<script>alert("a")</script>');
        });

        it('calls actionConfig clickHandler on click', () => {
          const clickHandler = jest.fn();

          alert = createAlert({
            message: mockMessage,
            primaryButton: {
              text: 'Ok',
              clickHandler,
            },
          });

          expect(clickHandler).toHaveBeenCalledTimes(0);

          findAlertAction().click();

          expect(clickHandler).toHaveBeenCalledTimes(1);
          expect(clickHandler).toHaveBeenCalledWith(expect.any(MouseEvent));
        });
      });

      describe('Alert API', () => {
        describe('dismiss', () => {
          it('dismiss programmatically with .dismiss()', () => {
            expect(document.querySelector('.gl-alert')).toBeNull();

            alert = createAlert({ message: mockMessage });

            expect(document.querySelector('.gl-alert')).not.toBeNull();

            alert.dismiss();

            expect(document.querySelector('.gl-alert')).toBeNull();
          });

          it('calls onDismiss when dismissed', () => {
            const dismissHandler = jest.fn();

            alert = createAlert({ message: mockMessage, onDismiss: dismissHandler });

            expect(dismissHandler).toHaveBeenCalledTimes(0);

            alert.dismiss();

            expect(dismissHandler).toHaveBeenCalledTimes(1);
          });
        });
      });
    });
  });

  describe('createFlash', () => {
    const message = 'test';
    const fadeTransition = false;
    const addBodyClass = true;
    const defaultParams = {
      message,
      actionConfig: null,
      fadeTransition,
      addBodyClass,
    };

    describe('no flash-container', () => {
      it('does not add to the DOM', () => {
        const flashEl = createFlash({ message });

        expect(flashEl).toBeNull();

        expect(document.querySelector('.flash-alert')).toBeNull();
      });
    });

    describe('with flash-container', () => {
      beforeEach(() => {
        setHTMLFixture(
          '<div class="content-wrapper js-content-wrapper"><div class="flash-container"></div></div>',
        );
      });

      afterEach(() => {
        resetHTMLFixture();
      });

      it('adds flash alert element into the document by default', () => {
        createFlash({ ...defaultParams });

        expect(document.querySelector('.flash-container .flash-alert')).not.toBeNull();
        expect(document.body.className).toContain('flash-shown');
      });

      it('adds flash of a warning type', () => {
        createFlash({ ...defaultParams, type: FLASH_TYPES.WARNING });

        expect(document.querySelector('.flash-container .flash-warning')).not.toBeNull();
        expect(document.body.className).toContain('flash-shown');
      });

      it('escapes text', () => {
        createFlash({ ...defaultParams, message: '<script>alert("a")</script>' });

        const html = document.querySelector('.flash-text').innerHTML;

        expect(html).toContain('&lt;script&gt;alert("a")&lt;/script&gt;');
        expect(html).not.toContain('<script>alert("a")</script>');
      });

      it('adds flash into specified parent', () => {
        createFlash({ ...defaultParams, parent: document.querySelector('.content-wrapper') });

        expect(document.querySelector('.content-wrapper .flash-alert')).not.toBeNull();
        expect(document.querySelector('.content-wrapper').innerText.trim()).toEqual(message);
      });

      it('adds container classes when inside content-wrapper', () => {
        createFlash(defaultParams);

        expect(document.querySelector('.flash-text').className).toBe('flash-text');
        expect(document.querySelector('.content-wrapper').innerText.trim()).toEqual(message);
      });

      it('does not add container when outside of content-wrapper', () => {
        document.querySelector('.content-wrapper').className = 'js-content-wrapper';
        createFlash(defaultParams);

        expect(document.querySelector('.flash-text').className.trim()).toContain('flash-text');
      });

      it('removes element after clicking', () => {
        createFlash({ ...defaultParams });

        document.querySelector('.flash-alert .js-close-icon').click();

        expect(document.querySelector('.flash-alert')).toBeNull();

        expect(document.body.className).not.toContain('flash-shown');
      });

      it('does not capture error using Sentry', () => {
        createFlash({ ...defaultParams, captureError: false, error: new Error('Error!') });

        expect(Sentry.captureException).not.toHaveBeenCalled();
      });

      it('captures error using Sentry', () => {
        createFlash({ ...defaultParams, captureError: true, error: new Error('Error!') });

        expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Error));
        expect(Sentry.captureException).toHaveBeenCalledWith(
          expect.objectContaining({
            message: 'Error!',
          }),
        );
      });

      describe('with actionConfig', () => {
        const findFlashAction = () => document.querySelector('.flash-container .flash-action');

        it('adds action link', () => {
          createFlash({
            ...defaultParams,
            actionConfig: {
              title: 'test',
            },
          });

          expect(findFlashAction()).not.toBeNull();
        });

        it('creates link with href', () => {
          createFlash({
            ...defaultParams,
            actionConfig: {
              href: 'testing',
              title: 'test',
            },
          });

          const action = findFlashAction();

          expect(action.href).toBe(`${window.location}testing`);
          expect(action.textContent.trim()).toBe('test');
        });

        it('uses hash as href when no href is present', () => {
          createFlash({
            ...defaultParams,
            actionConfig: {
              title: 'test',
            },
          });

          expect(findFlashAction().href).toBe(`${window.location}#`);
        });

        it('adds role when no href is present', () => {
          createFlash({
            ...defaultParams,
            actionConfig: {
              title: 'test',
            },
          });

          expect(findFlashAction().getAttribute('role')).toBe('button');
        });

        it('escapes the title text', () => {
          createFlash({
            ...defaultParams,
            actionConfig: {
              title: '<script>alert("a")</script>',
            },
          });

          const html = findFlashAction().innerHTML;

          expect(html).toContain('&lt;script&gt;alert("a")&lt;/script&gt;');
          expect(html).not.toContain('<script>alert("a")</script>');
        });

        it('calls actionConfig clickHandler on click', () => {
          const clickHandler = jest.fn();

          createFlash({
            ...defaultParams,
            actionConfig: {
              title: 'test',
              clickHandler,
            },
          });

          findFlashAction().click();

          expect(clickHandler).toHaveBeenCalled();
        });
      });

      describe('additional behavior', () => {
        describe('close', () => {
          it('clicks the close icon', () => {
            const flash = createFlash({ ...defaultParams });
            const close = document.querySelector('.flash-alert .js-close-icon');

            jest.spyOn(close, 'click');
            flash.close();

            expect(close.click.mock.calls.length).toBe(1);
          });
        });
      });
    });
  });

  describe('addDismissFlashClickListener', () => {
    let el;

    describe('with close icon', () => {
      beforeEach(() => {
        el = document.createElement('div');
        el.innerHTML = `
          <div class="flash-container">
            <div class="flash">
              <div class="close-icon js-close-icon"></div>
            </div>
          </div>
        `;
      });

      it('removes global flash on click', () => {
        addDismissFlashClickListener(el, false);

        el.querySelector('.js-close-icon').click();

        expect(document.querySelector('.flash')).toBeNull();
      });
    });

    describe('without close icon', () => {
      beforeEach(() => {
        el = document.createElement('div');
        el.innerHTML = `
          <div class="flash-container">
            <div class="flash">
            </div>
          </div>
        `;
      });

      it('does not throw', () => {
        expect(() => addDismissFlashClickListener(el, false)).not.toThrow();
      });
    });
  });
});
