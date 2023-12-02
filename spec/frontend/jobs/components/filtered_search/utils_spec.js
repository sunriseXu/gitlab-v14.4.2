import { validateQueryString } from '~/jobs/components/filtered_search/utils';

describe('Filtered search utils', () => {
  describe('validateQueryString', () => {
    it.each`
      queryStringObject          | expected
      ${{ statuses: 'SUCCESS' }} | ${{ statuses: 'SUCCESS' }}
      ${{ statuses: 'failed' }}  | ${{ statuses: 'FAILED' }}
      ${{ wrong: 'SUCCESS' }}    | ${null}
      ${{ statuses: 'wrong' }}   | ${null}
      ${{ wrong: 'wrong' }}      | ${null}
    `(
      'when provided $queryStringObject, the expected result is $expected',
      ({ queryStringObject, expected }) => {
        expect(validateQueryString(queryStringObject)).toEqual(expected);
      },
    );
  });
});
