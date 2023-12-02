import { setHTMLFixture } from 'helpers/fixtures';
import * as createDefaultClient from '~/lib/graphql';
import initIssuablePopovers from '~/issuable/popover/index';

createDefaultClient.default = jest.fn();

describe('initIssuablePopovers', () => {
  let mr1;
  let mr2;
  let mr3;
  let issue1;

  beforeEach(() => {
    setHTMLFixture(`
      <div id="one" class="gfm-merge_request" data-mr-title="title" data-iid="1" data-project-path="group/project" data-reference-type="merge_request">
        MR1
      </div>
      <div id="two" class="gfm-merge_request" title="title" data-iid="1" data-project-path="group/project" data-reference-type="merge_request">
        MR2
      </div>
      <div id="three" class="gfm-merge_request">
        MR3
      </div>
      <div id="four" class="gfm-issue" title="title" data-iid="1" data-project-path="group/project" data-reference-type="issue">
        MR3
      </div>
    `);

    mr1 = document.querySelector('#one');
    mr2 = document.querySelector('#two');
    mr3 = document.querySelector('#three');
    issue1 = document.querySelector('#four');

    mr1.addEventListener = jest.fn();
    mr2.addEventListener = jest.fn();
    mr3.addEventListener = jest.fn();
    issue1.addEventListener = jest.fn();
  });

  it('does not add the same event listener twice', () => {
    initIssuablePopovers([mr1, mr1, mr2, issue1]);

    expect(mr1.addEventListener).toHaveBeenCalledTimes(1);
    expect(mr2.addEventListener).toHaveBeenCalledTimes(1);
    expect(issue1.addEventListener).toHaveBeenCalledTimes(1);
  });

  it('does not add listener if it does not have the necessary data attributes', () => {
    initIssuablePopovers([mr1, mr2, mr3]);

    expect(mr3.addEventListener).not.toHaveBeenCalled();
  });
});
