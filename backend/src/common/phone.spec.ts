import { normalizeIranPhone } from './phone';

describe('normalizeIranPhone',()=>{
  it.each([
    ['09121234567','09121234567'],
    ['+989121234567','09121234567'],
    ['00989121234567','09121234567'],
    ['9121234567','09121234567'],
    ['۰۹۱۲۱۲۳۴۵۶۷','09121234567'],
  ])('normalizes %s', (input,expected)=>expect(normalizeIranPhone(input)).toBe(expected));
  it('rejects invalid Iranian mobile numbers',()=>expect(()=>normalizeIranPhone('02112345678')).toThrow('INVALID_IRAN_PHONE'));
});
