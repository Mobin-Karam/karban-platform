export type PaymentLaunch={attemptId:string;paymentUrl:string};
export interface PaymentLauncher{open(input:PaymentLaunch):Promise<void>}
/**
 * Browser fallback. In production Tauri mobile, use a provider-specific trusted
 * in-app WebView or OS Custom Tab and return through the configured deep link.
 * The backend always verifies the attempt; the client never marks it paid itself.
 */
export class BrowserPaymentLauncher implements PaymentLauncher{async open(input:PaymentLaunch){const url=new URL(input.paymentUrl);if(!['www.zarinpal.com','payment.zarinpal.com','sandbox.zarinpal.com'].includes(url.hostname))throw new Error('PAYMENT_HOST_NOT_ALLOWED');window.location.assign(url.toString())}}
export const paymentLauncher:PaymentLauncher=new BrowserPaymentLauncher();
