/**
 * Boundary for sensitive mobile persistence.
 * Native production builds should provide a Stronghold-backed implementation.
 * This starter intentionally does not hardcode a Stronghold vault password.
 * Access tokens stay in memory; refresh-token persistence can be plugged in here.
 */
export interface SecureStorageProvider{get(key:string):Promise<string|null>;set(key:string,value:string):Promise<void>;remove(key:string):Promise<void>}
export class MemorySecureStorage implements SecureStorageProvider{private readonly values=new Map<string,string>();async get(key:string){return this.values.get(key)??null}async set(key:string,value:string){this.values.set(key,value)}async remove(key:string){this.values.delete(key)}}
export const secureStorage:SecureStorageProvider=new MemorySecureStorage();
