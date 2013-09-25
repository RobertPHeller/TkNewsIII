%module Gpgme

%{
#include <stdio.h>
#include <gpgme.h>
%}


%init %{
    if (Tcl_InitStubs(interp, "8.0", 0) == NULL) {
        return TCL_ERROR;
    }
    Tcl_PkgProvide(interp,"Gpgme",gpgme_check_version(NULL));
%}

%include <typemaps.i>

#ifdef SWIG
typedef unsigned int gpgme_error_t;
typedef unsigned int gpgme_err_code_t;
typedef unsigned int gpg_err_source_t;
#endif

%typemap(out) gpgme_error_t {
    int returnval = TCL_OK;
    Tcl_Obj * tcl_result = $result;
    switch ($1 & GPG_ERR_CODE_MASK) {
    case GPG_ERR_NO_ERROR: break;
    case GPG_ERR_GENERAL: Tcl_SetStringObj(tcl_result,"GPG_ERR_GENERAL",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNKNOWN_PACKET: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNKNOWN_PACKET",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNKNOWN_VERSION: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNKNOWN_VERSION",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_PUBKEY_ALGO: Tcl_SetStringObj(tcl_result,"GPG_ERR_PUBKEY_ALGO",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_DIGEST_ALGO: Tcl_SetStringObj(tcl_result,"GPG_ERR_DIGEST_ALGO",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_BAD_PUBKEY: Tcl_SetStringObj(tcl_result,"GPG_ERR_BAD_PUBKEY",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_BAD_SECKEY: Tcl_SetStringObj(tcl_result,"GPG_ERR_BAD_SECKEY",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_BAD_SIGNATURE: Tcl_SetStringObj(tcl_result,"GPG_ERR_BAD_SIGNATURE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NO_PUBKEY: Tcl_SetStringObj(tcl_result,"GPG_ERR_NO_PUBKEY",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_CHECKSUM: Tcl_SetStringObj(tcl_result,"GPG_ERR_CHECKSUM",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_BAD_PASSPHRASE: Tcl_SetStringObj(tcl_result,"GPG_ERR_BAD_PASSPHRASE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_CIPHER_ALGO: Tcl_SetStringObj(tcl_result,"GPG_ERR_CIPHER_ALGO",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_KEYRING_OPEN: Tcl_SetStringObj(tcl_result,"GPG_ERR_KEYRING_OPEN",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_PACKET: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_PACKET",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_ARMOR: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_ARMOR",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NO_USER_ID: Tcl_SetStringObj(tcl_result,"GPG_ERR_NO_USER_ID",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NO_SECKEY: Tcl_SetStringObj(tcl_result,"GPG_ERR_NO_SECKEY",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_WRONG_SECKEY: Tcl_SetStringObj(tcl_result,"GPG_ERR_WRONG_SECKEY",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_BAD_KEY: Tcl_SetStringObj(tcl_result,"GPG_ERR_BAD_KEY",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_COMPR_ALGO: Tcl_SetStringObj(tcl_result,"GPG_ERR_COMPR_ALGO",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NO_PRIME: Tcl_SetStringObj(tcl_result,"GPG_ERR_NO_PRIME",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NO_ENCODING_METHOD: Tcl_SetStringObj(tcl_result,"GPG_ERR_NO_ENCODING_METHOD",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NO_ENCRYPTION_SCHEME: Tcl_SetStringObj(tcl_result,"GPG_ERR_NO_ENCRYPTION_SCHEME",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NO_SIGNATURE_SCHEME: Tcl_SetStringObj(tcl_result,"GPG_ERR_NO_SIGNATURE_SCHEME",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_ATTR: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_ATTR",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NO_VALUE: Tcl_SetStringObj(tcl_result,"GPG_ERR_NO_VALUE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NOT_FOUND: Tcl_SetStringObj(tcl_result,"GPG_ERR_NOT_FOUND",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_VALUE_NOT_FOUND: Tcl_SetStringObj(tcl_result,"GPG_ERR_VALUE_NOT_FOUND",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_SYNTAX: Tcl_SetStringObj(tcl_result,"GPG_ERR_SYNTAX",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_BAD_MPI: Tcl_SetStringObj(tcl_result,"GPG_ERR_BAD_MPI",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_PASSPHRASE: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_PASSPHRASE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_SIG_CLASS: Tcl_SetStringObj(tcl_result,"GPG_ERR_SIG_CLASS",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_RESOURCE_LIMIT: Tcl_SetStringObj(tcl_result,"GPG_ERR_RESOURCE_LIMIT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_KEYRING: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_KEYRING",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_TRUSTDB: Tcl_SetStringObj(tcl_result,"GPG_ERR_TRUSTDB",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_BAD_CERT: Tcl_SetStringObj(tcl_result,"GPG_ERR_BAD_CERT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_USER_ID: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_USER_ID",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNEXPECTED: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNEXPECTED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_TIME_CONFLICT: Tcl_SetStringObj(tcl_result,"GPG_ERR_TIME_CONFLICT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_KEYSERVER: Tcl_SetStringObj(tcl_result,"GPG_ERR_KEYSERVER",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_WRONG_PUBKEY_ALGO: Tcl_SetStringObj(tcl_result,"GPG_ERR_WRONG_PUBKEY_ALGO",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_TRIBUTE_TO_D_A: Tcl_SetStringObj(tcl_result,"GPG_ERR_TRIBUTE_TO_D_A",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_WEAK_KEY: Tcl_SetStringObj(tcl_result,"GPG_ERR_WEAK_KEY",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_KEYLEN: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_KEYLEN",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_ARG: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_ARG",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_BAD_URI: Tcl_SetStringObj(tcl_result,"GPG_ERR_BAD_URI",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_URI: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_URI",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NETWORK: Tcl_SetStringObj(tcl_result,"GPG_ERR_NETWORK",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNKNOWN_HOST: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNKNOWN_HOST",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_SELFTEST_FAILED: Tcl_SetStringObj(tcl_result,"GPG_ERR_SELFTEST_FAILED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NOT_ENCRYPTED: Tcl_SetStringObj(tcl_result,"GPG_ERR_NOT_ENCRYPTED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NOT_PROCESSED: Tcl_SetStringObj(tcl_result,"GPG_ERR_NOT_PROCESSED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNUSABLE_PUBKEY: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNUSABLE_PUBKEY",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNUSABLE_SECKEY: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNUSABLE_SECKEY",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_VALUE: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_VALUE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_BAD_CERT_CHAIN: Tcl_SetStringObj(tcl_result,"GPG_ERR_BAD_CERT_CHAIN",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_MISSING_CERT: Tcl_SetStringObj(tcl_result,"GPG_ERR_MISSING_CERT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NO_DATA: Tcl_SetStringObj(tcl_result,"GPG_ERR_NO_DATA",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_BUG: Tcl_SetStringObj(tcl_result,"GPG_ERR_BUG",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NOT_SUPPORTED: Tcl_SetStringObj(tcl_result,"GPG_ERR_NOT_SUPPORTED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_OP: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_OP",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_TIMEOUT: Tcl_SetStringObj(tcl_result,"GPG_ERR_TIMEOUT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INTERNAL: Tcl_SetStringObj(tcl_result,"GPG_ERR_INTERNAL",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EOF_GCRYPT: Tcl_SetStringObj(tcl_result,"GPG_ERR_EOF_GCRYPT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_OBJ: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_OBJ",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_TOO_SHORT: Tcl_SetStringObj(tcl_result,"GPG_ERR_TOO_SHORT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_TOO_LARGE: Tcl_SetStringObj(tcl_result,"GPG_ERR_TOO_LARGE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NO_OBJ: Tcl_SetStringObj(tcl_result,"GPG_ERR_NO_OBJ",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NOT_IMPLEMENTED: Tcl_SetStringObj(tcl_result,"GPG_ERR_NOT_IMPLEMENTED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_CONFLICT: Tcl_SetStringObj(tcl_result,"GPG_ERR_CONFLICT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_CIPHER_MODE: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_CIPHER_MODE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_FLAG: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_FLAG",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_HANDLE: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_HANDLE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_TRUNCATED: Tcl_SetStringObj(tcl_result,"GPG_ERR_TRUNCATED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INCOMPLETE_LINE: Tcl_SetStringObj(tcl_result,"GPG_ERR_INCOMPLETE_LINE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_RESPONSE: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_RESPONSE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NO_AGENT: Tcl_SetStringObj(tcl_result,"GPG_ERR_NO_AGENT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_AGENT: Tcl_SetStringObj(tcl_result,"GPG_ERR_AGENT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_DATA: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_DATA",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASSUAN_SERVER_FAULT: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASSUAN_SERVER_FAULT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASSUAN: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASSUAN",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_SESSION_KEY: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_SESSION_KEY",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_SEXP: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_SEXP",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNSUPPORTED_ALGORITHM: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNSUPPORTED_ALGORITHM",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NO_PIN_ENTRY: Tcl_SetStringObj(tcl_result,"GPG_ERR_NO_PIN_ENTRY",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_PIN_ENTRY: Tcl_SetStringObj(tcl_result,"GPG_ERR_PIN_ENTRY",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_BAD_PIN: Tcl_SetStringObj(tcl_result,"GPG_ERR_BAD_PIN",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_NAME: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_NAME",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_BAD_DATA: Tcl_SetStringObj(tcl_result,"GPG_ERR_BAD_DATA",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_PARAMETER: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_PARAMETER",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_WRONG_CARD: Tcl_SetStringObj(tcl_result,"GPG_ERR_WRONG_CARD",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NO_DIRMNGR: Tcl_SetStringObj(tcl_result,"GPG_ERR_NO_DIRMNGR",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_DIRMNGR: Tcl_SetStringObj(tcl_result,"GPG_ERR_DIRMNGR",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_CERT_REVOKED: Tcl_SetStringObj(tcl_result,"GPG_ERR_CERT_REVOKED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NO_CRL_KNOWN: Tcl_SetStringObj(tcl_result,"GPG_ERR_NO_CRL_KNOWN",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_CRL_TOO_OLD: Tcl_SetStringObj(tcl_result,"GPG_ERR_CRL_TOO_OLD",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_LINE_TOO_LONG: Tcl_SetStringObj(tcl_result,"GPG_ERR_LINE_TOO_LONG",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NOT_TRUSTED: Tcl_SetStringObj(tcl_result,"GPG_ERR_NOT_TRUSTED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_CANCELED: Tcl_SetStringObj(tcl_result,"GPG_ERR_CANCELED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_BAD_CA_CERT: Tcl_SetStringObj(tcl_result,"GPG_ERR_BAD_CA_CERT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_CERT_EXPIRED: Tcl_SetStringObj(tcl_result,"GPG_ERR_CERT_EXPIRED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_CERT_TOO_YOUNG: Tcl_SetStringObj(tcl_result,"GPG_ERR_CERT_TOO_YOUNG",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNSUPPORTED_CERT: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNSUPPORTED_CERT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNKNOWN_SEXP: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNKNOWN_SEXP",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNSUPPORTED_PROTECTION: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNSUPPORTED_PROTECTION",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_CORRUPTED_PROTECTION: Tcl_SetStringObj(tcl_result,"GPG_ERR_CORRUPTED_PROTECTION",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_AMBIGUOUS_NAME: Tcl_SetStringObj(tcl_result,"GPG_ERR_AMBIGUOUS_NAME",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_CARD: Tcl_SetStringObj(tcl_result,"GPG_ERR_CARD",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_CARD_RESET: Tcl_SetStringObj(tcl_result,"GPG_ERR_CARD_RESET",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_CARD_REMOVED: Tcl_SetStringObj(tcl_result,"GPG_ERR_CARD_REMOVED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_CARD: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_CARD",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_CARD_NOT_PRESENT: Tcl_SetStringObj(tcl_result,"GPG_ERR_CARD_NOT_PRESENT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NO_PKCS15_APP: Tcl_SetStringObj(tcl_result,"GPG_ERR_NO_PKCS15_APP",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NOT_CONFIRMED: Tcl_SetStringObj(tcl_result,"GPG_ERR_NOT_CONFIRMED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_CONFIGURATION: Tcl_SetStringObj(tcl_result,"GPG_ERR_CONFIGURATION",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NO_POLICY_MATCH: Tcl_SetStringObj(tcl_result,"GPG_ERR_NO_POLICY_MATCH",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_INDEX: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_INDEX",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_ID: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_ID",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NO_SCDAEMON: Tcl_SetStringObj(tcl_result,"GPG_ERR_NO_SCDAEMON",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_SCDAEMON: Tcl_SetStringObj(tcl_result,"GPG_ERR_SCDAEMON",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNSUPPORTED_PROTOCOL: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNSUPPORTED_PROTOCOL",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_BAD_PIN_METHOD: Tcl_SetStringObj(tcl_result,"GPG_ERR_BAD_PIN_METHOD",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_CARD_NOT_INITIALIZED: Tcl_SetStringObj(tcl_result,"GPG_ERR_CARD_NOT_INITIALIZED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNSUPPORTED_OPERATION: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNSUPPORTED_OPERATION",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_WRONG_KEY_USAGE: Tcl_SetStringObj(tcl_result,"GPG_ERR_WRONG_KEY_USAGE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NOTHING_FOUND: Tcl_SetStringObj(tcl_result,"GPG_ERR_NOTHING_FOUND",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_WRONG_BLOB_TYPE: Tcl_SetStringObj(tcl_result,"GPG_ERR_WRONG_BLOB_TYPE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_MISSING_VALUE: Tcl_SetStringObj(tcl_result,"GPG_ERR_MISSING_VALUE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_HARDWARE: Tcl_SetStringObj(tcl_result,"GPG_ERR_HARDWARE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_PIN_BLOCKED: Tcl_SetStringObj(tcl_result,"GPG_ERR_PIN_BLOCKED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_USE_CONDITIONS: Tcl_SetStringObj(tcl_result,"GPG_ERR_USE_CONDITIONS",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_PIN_NOT_SYNCED: Tcl_SetStringObj(tcl_result,"GPG_ERR_PIN_NOT_SYNCED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_CRL: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_CRL",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_BAD_BER: Tcl_SetStringObj(tcl_result,"GPG_ERR_BAD_BER",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_BER: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_BER",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ELEMENT_NOT_FOUND: Tcl_SetStringObj(tcl_result,"GPG_ERR_ELEMENT_NOT_FOUND",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_IDENTIFIER_NOT_FOUND: Tcl_SetStringObj(tcl_result,"GPG_ERR_IDENTIFIER_NOT_FOUND",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_TAG: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_TAG",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_LENGTH: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_LENGTH",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_KEYINFO: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_KEYINFO",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNEXPECTED_TAG: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNEXPECTED_TAG",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NOT_DER_ENCODED: Tcl_SetStringObj(tcl_result,"GPG_ERR_NOT_DER_ENCODED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NO_CMS_OBJ: Tcl_SetStringObj(tcl_result,"GPG_ERR_NO_CMS_OBJ",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_CMS_OBJ: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_CMS_OBJ",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNKNOWN_CMS_OBJ: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNKNOWN_CMS_OBJ",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNSUPPORTED_CMS_OBJ: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNSUPPORTED_CMS_OBJ",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNSUPPORTED_ENCODING: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNSUPPORTED_ENCODING",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNSUPPORTED_CMS_VERSION: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNSUPPORTED_CMS_VERSION",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNKNOWN_ALGORITHM: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNKNOWN_ALGORITHM",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_ENGINE: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_ENGINE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_PUBKEY_NOT_TRUSTED: Tcl_SetStringObj(tcl_result,"GPG_ERR_PUBKEY_NOT_TRUSTED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_DECRYPT_FAILED: Tcl_SetStringObj(tcl_result,"GPG_ERR_DECRYPT_FAILED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_KEY_EXPIRED: Tcl_SetStringObj(tcl_result,"GPG_ERR_KEY_EXPIRED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_SIG_EXPIRED: Tcl_SetStringObj(tcl_result,"GPG_ERR_SIG_EXPIRED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENCODING_PROBLEM: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENCODING_PROBLEM",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_STATE: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_STATE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_DUP_VALUE: Tcl_SetStringObj(tcl_result,"GPG_ERR_DUP_VALUE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_MISSING_ACTION: Tcl_SetStringObj(tcl_result,"GPG_ERR_MISSING_ACTION",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_MODULE_NOT_FOUND: Tcl_SetStringObj(tcl_result,"GPG_ERR_MODULE_NOT_FOUND",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_OID_STRING: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_OID_STRING",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_TIME: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_TIME",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_CRL_OBJ: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_CRL_OBJ",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNSUPPORTED_CRL_VERSION: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNSUPPORTED_CRL_VERSION",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_CERT_OBJ: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_CERT_OBJ",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNKNOWN_NAME: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNKNOWN_NAME",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_LOCALE_PROBLEM: Tcl_SetStringObj(tcl_result,"GPG_ERR_LOCALE_PROBLEM",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_NOT_LOCKED: Tcl_SetStringObj(tcl_result,"GPG_ERR_NOT_LOCKED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_PROTOCOL_VIOLATION: Tcl_SetStringObj(tcl_result,"GPG_ERR_PROTOCOL_VIOLATION",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_MAC: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_MAC",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_INV_REQUEST: Tcl_SetStringObj(tcl_result,"GPG_ERR_INV_REQUEST",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNKNOWN_EXTN: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNKNOWN_EXTN",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNKNOWN_CRIT_EXTN: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNKNOWN_CRIT_EXTN",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_LOCKED: Tcl_SetStringObj(tcl_result,"GPG_ERR_LOCKED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNKNOWN_OPTION: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNKNOWN_OPTION",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNKNOWN_COMMAND: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNKNOWN_COMMAND",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_BUFFER_TOO_SHORT: Tcl_SetStringObj(tcl_result,"GPG_ERR_BUFFER_TOO_SHORT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_SEXP_INV_LEN_SPEC: Tcl_SetStringObj(tcl_result,"GPG_ERR_SEXP_INV_LEN_SPEC",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_SEXP_STRING_TOO_LONG: Tcl_SetStringObj(tcl_result,"GPG_ERR_SEXP_STRING_TOO_LONG",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_SEXP_UNMATCHED_PAREN: Tcl_SetStringObj(tcl_result,"GPG_ERR_SEXP_UNMATCHED_PAREN",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_SEXP_NOT_CANONICAL: Tcl_SetStringObj(tcl_result,"GPG_ERR_SEXP_NOT_CANONICAL",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_SEXP_BAD_CHARACTER: Tcl_SetStringObj(tcl_result,"GPG_ERR_SEXP_BAD_CHARACTER",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_SEXP_BAD_QUOTATION: Tcl_SetStringObj(tcl_result,"GPG_ERR_SEXP_BAD_QUOTATION",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_SEXP_ZERO_PREFIX: Tcl_SetStringObj(tcl_result,"GPG_ERR_SEXP_ZERO_PREFIX",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_SEXP_NESTED_DH: Tcl_SetStringObj(tcl_result,"GPG_ERR_SEXP_NESTED_DH",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_SEXP_UNMATCHED_DH: Tcl_SetStringObj(tcl_result,"GPG_ERR_SEXP_UNMATCHED_DH",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_SEXP_UNEXPECTED_PUNC: Tcl_SetStringObj(tcl_result,"GPG_ERR_SEXP_UNEXPECTED_PUNC",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_SEXP_BAD_HEX_CHAR: Tcl_SetStringObj(tcl_result,"GPG_ERR_SEXP_BAD_HEX_CHAR",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_SEXP_ODD_HEX_NUMBERS: Tcl_SetStringObj(tcl_result,"GPG_ERR_SEXP_ODD_HEX_NUMBERS",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_SEXP_BAD_OCT_CHAR: Tcl_SetStringObj(tcl_result,"GPG_ERR_SEXP_BAD_OCT_CHAR",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_GENERAL: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_GENERAL",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_ACCEPT_FAILED: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_ACCEPT_FAILED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_CONNECT_FAILED: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_CONNECT_FAILED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_INV_RESPONSE: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_INV_RESPONSE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_INV_VALUE: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_INV_VALUE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_INCOMPLETE_LINE: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_INCOMPLETE_LINE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_LINE_TOO_LONG: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_LINE_TOO_LONG",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_NESTED_COMMANDS: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_NESTED_COMMANDS",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_NO_DATA_CB: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_NO_DATA_CB",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_NO_INQUIRE_CB: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_NO_INQUIRE_CB",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_NOT_A_SERVER: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_NOT_A_SERVER",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_NOT_A_CLIENT: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_NOT_A_CLIENT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_SERVER_START: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_SERVER_START",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_READ_ERROR: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_READ_ERROR",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_WRITE_ERROR: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_WRITE_ERROR",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_TOO_MUCH_DATA: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_TOO_MUCH_DATA",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_UNEXPECTED_CMD: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_UNEXPECTED_CMD",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_UNKNOWN_CMD: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_UNKNOWN_CMD",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_SYNTAX: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_SYNTAX",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_CANCELED: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_CANCELED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_NO_INPUT: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_NO_INPUT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_NO_OUTPUT: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_NO_OUTPUT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_PARAMETER: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_PARAMETER",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ASS_UNKNOWN_INQUIRE: Tcl_SetStringObj(tcl_result,"GPG_ERR_ASS_UNKNOWN_INQUIRE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_USER_1: Tcl_SetStringObj(tcl_result,"GPG_ERR_USER_1",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_USER_2: Tcl_SetStringObj(tcl_result,"GPG_ERR_USER_2",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_USER_3: Tcl_SetStringObj(tcl_result,"GPG_ERR_USER_3",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_USER_4: Tcl_SetStringObj(tcl_result,"GPG_ERR_USER_4",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_USER_5: Tcl_SetStringObj(tcl_result,"GPG_ERR_USER_5",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_USER_6: Tcl_SetStringObj(tcl_result,"GPG_ERR_USER_6",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_USER_7: Tcl_SetStringObj(tcl_result,"GPG_ERR_USER_7",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_USER_8: Tcl_SetStringObj(tcl_result,"GPG_ERR_USER_8",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_USER_9: Tcl_SetStringObj(tcl_result,"GPG_ERR_USER_9",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_USER_10: Tcl_SetStringObj(tcl_result,"GPG_ERR_USER_10",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_USER_11: Tcl_SetStringObj(tcl_result,"GPG_ERR_USER_11",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_USER_12: Tcl_SetStringObj(tcl_result,"GPG_ERR_USER_12",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_USER_13: Tcl_SetStringObj(tcl_result,"GPG_ERR_USER_13",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_USER_14: Tcl_SetStringObj(tcl_result,"GPG_ERR_USER_14",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_USER_15: Tcl_SetStringObj(tcl_result,"GPG_ERR_USER_15",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_USER_16: Tcl_SetStringObj(tcl_result,"GPG_ERR_USER_16",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_MISSING_ERRNO: Tcl_SetStringObj(tcl_result,"GPG_ERR_MISSING_ERRNO",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_UNKNOWN_ERRNO: Tcl_SetStringObj(tcl_result,"GPG_ERR_UNKNOWN_ERRNO",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EOF: Tcl_SetStringObj(tcl_result,"GPG_ERR_EOF",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_E2BIG: Tcl_SetStringObj(tcl_result,"GPG_ERR_E2BIG",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EACCES: Tcl_SetStringObj(tcl_result,"GPG_ERR_EACCES",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EADDRINUSE: Tcl_SetStringObj(tcl_result,"GPG_ERR_EADDRINUSE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EADDRNOTAVAIL: Tcl_SetStringObj(tcl_result,"GPG_ERR_EADDRNOTAVAIL",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EADV: Tcl_SetStringObj(tcl_result,"GPG_ERR_EADV",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EAFNOSUPPORT: Tcl_SetStringObj(tcl_result,"GPG_ERR_EAFNOSUPPORT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EAGAIN: Tcl_SetStringObj(tcl_result,"GPG_ERR_EAGAIN",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EALREADY: Tcl_SetStringObj(tcl_result,"GPG_ERR_EALREADY",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EAUTH: Tcl_SetStringObj(tcl_result,"GPG_ERR_EAUTH",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EBACKGROUND: Tcl_SetStringObj(tcl_result,"GPG_ERR_EBACKGROUND",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EBADE: Tcl_SetStringObj(tcl_result,"GPG_ERR_EBADE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EBADF: Tcl_SetStringObj(tcl_result,"GPG_ERR_EBADF",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EBADFD: Tcl_SetStringObj(tcl_result,"GPG_ERR_EBADFD",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EBADMSG: Tcl_SetStringObj(tcl_result,"GPG_ERR_EBADMSG",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EBADR: Tcl_SetStringObj(tcl_result,"GPG_ERR_EBADR",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EBADRPC: Tcl_SetStringObj(tcl_result,"GPG_ERR_EBADRPC",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EBADRQC: Tcl_SetStringObj(tcl_result,"GPG_ERR_EBADRQC",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EBADSLT: Tcl_SetStringObj(tcl_result,"GPG_ERR_EBADSLT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EBFONT: Tcl_SetStringObj(tcl_result,"GPG_ERR_EBFONT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EBUSY: Tcl_SetStringObj(tcl_result,"GPG_ERR_EBUSY",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ECANCELED: Tcl_SetStringObj(tcl_result,"GPG_ERR_ECANCELED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ECHILD: Tcl_SetStringObj(tcl_result,"GPG_ERR_ECHILD",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ECHRNG: Tcl_SetStringObj(tcl_result,"GPG_ERR_ECHRNG",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ECOMM: Tcl_SetStringObj(tcl_result,"GPG_ERR_ECOMM",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ECONNABORTED: Tcl_SetStringObj(tcl_result,"GPG_ERR_ECONNABORTED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ECONNREFUSED: Tcl_SetStringObj(tcl_result,"GPG_ERR_ECONNREFUSED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ECONNRESET: Tcl_SetStringObj(tcl_result,"GPG_ERR_ECONNRESET",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ED: Tcl_SetStringObj(tcl_result,"GPG_ERR_ED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EDEADLK: Tcl_SetStringObj(tcl_result,"GPG_ERR_EDEADLK",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EDEADLOCK: Tcl_SetStringObj(tcl_result,"GPG_ERR_EDEADLOCK",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EDESTADDRREQ: Tcl_SetStringObj(tcl_result,"GPG_ERR_EDESTADDRREQ",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EDIED: Tcl_SetStringObj(tcl_result,"GPG_ERR_EDIED",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EDOM: Tcl_SetStringObj(tcl_result,"GPG_ERR_EDOM",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EDOTDOT: Tcl_SetStringObj(tcl_result,"GPG_ERR_EDOTDOT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EDQUOT: Tcl_SetStringObj(tcl_result,"GPG_ERR_EDQUOT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EEXIST: Tcl_SetStringObj(tcl_result,"GPG_ERR_EEXIST",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EFAULT: Tcl_SetStringObj(tcl_result,"GPG_ERR_EFAULT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EFBIG: Tcl_SetStringObj(tcl_result,"GPG_ERR_EFBIG",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EFTYPE: Tcl_SetStringObj(tcl_result,"GPG_ERR_EFTYPE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EGRATUITOUS: Tcl_SetStringObj(tcl_result,"GPG_ERR_EGRATUITOUS",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EGREGIOUS: Tcl_SetStringObj(tcl_result,"GPG_ERR_EGREGIOUS",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EHOSTDOWN: Tcl_SetStringObj(tcl_result,"GPG_ERR_EHOSTDOWN",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EHOSTUNREACH: Tcl_SetStringObj(tcl_result,"GPG_ERR_EHOSTUNREACH",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EIDRM: Tcl_SetStringObj(tcl_result,"GPG_ERR_EIDRM",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EIEIO: Tcl_SetStringObj(tcl_result,"GPG_ERR_EIEIO",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EILSEQ: Tcl_SetStringObj(tcl_result,"GPG_ERR_EILSEQ",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EINPROGRESS: Tcl_SetStringObj(tcl_result,"GPG_ERR_EINPROGRESS",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EINTR: Tcl_SetStringObj(tcl_result,"GPG_ERR_EINTR",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EINVAL: Tcl_SetStringObj(tcl_result,"GPG_ERR_EINVAL",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EIO: Tcl_SetStringObj(tcl_result,"GPG_ERR_EIO",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EISCONN: Tcl_SetStringObj(tcl_result,"GPG_ERR_EISCONN",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EISDIR: Tcl_SetStringObj(tcl_result,"GPG_ERR_EISDIR",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EISNAM: Tcl_SetStringObj(tcl_result,"GPG_ERR_EISNAM",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EL2HLT: Tcl_SetStringObj(tcl_result,"GPG_ERR_EL2HLT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EL2NSYNC: Tcl_SetStringObj(tcl_result,"GPG_ERR_EL2NSYNC",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EL3HLT: Tcl_SetStringObj(tcl_result,"GPG_ERR_EL3HLT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EL3RST: Tcl_SetStringObj(tcl_result,"GPG_ERR_EL3RST",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ELIBACC: Tcl_SetStringObj(tcl_result,"GPG_ERR_ELIBACC",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ELIBBAD: Tcl_SetStringObj(tcl_result,"GPG_ERR_ELIBBAD",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ELIBEXEC: Tcl_SetStringObj(tcl_result,"GPG_ERR_ELIBEXEC",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ELIBMAX: Tcl_SetStringObj(tcl_result,"GPG_ERR_ELIBMAX",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ELIBSCN: Tcl_SetStringObj(tcl_result,"GPG_ERR_ELIBSCN",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ELNRNG: Tcl_SetStringObj(tcl_result,"GPG_ERR_ELNRNG",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ELOOP: Tcl_SetStringObj(tcl_result,"GPG_ERR_ELOOP",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EMEDIUMTYPE: Tcl_SetStringObj(tcl_result,"GPG_ERR_EMEDIUMTYPE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EMFILE: Tcl_SetStringObj(tcl_result,"GPG_ERR_EMFILE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EMLINK: Tcl_SetStringObj(tcl_result,"GPG_ERR_EMLINK",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EMSGSIZE: Tcl_SetStringObj(tcl_result,"GPG_ERR_EMSGSIZE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EMULTIHOP: Tcl_SetStringObj(tcl_result,"GPG_ERR_EMULTIHOP",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENAMETOOLONG: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENAMETOOLONG",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENAVAIL: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENAVAIL",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENEEDAUTH: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENEEDAUTH",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENETDOWN: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENETDOWN",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENETRESET: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENETRESET",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENETUNREACH: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENETUNREACH",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENFILE: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENFILE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOANO: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOANO",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOBUFS: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOBUFS",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOCSI: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOCSI",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENODATA: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENODATA",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENODEV: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENODEV",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOENT: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOENT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOEXEC: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOEXEC",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOLCK: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOLCK",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOLINK: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOLINK",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOMEDIUM: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOMEDIUM",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOMEM: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOMEM",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOMSG: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOMSG",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENONET: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENONET",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOPKG: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOPKG",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOPROTOOPT: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOPROTOOPT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOSPC: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOSPC",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOSR: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOSR",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOSTR: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOSTR",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOSYS: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOSYS",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOTBLK: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOTBLK",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOTCONN: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOTCONN",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOTDIR: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOTDIR",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOTEMPTY: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOTEMPTY",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOTNAM: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOTNAM",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOTSOCK: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOTSOCK",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOTSUP: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOTSUP",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOTTY: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOTTY",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENOTUNIQ: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENOTUNIQ",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ENXIO: Tcl_SetStringObj(tcl_result,"GPG_ERR_ENXIO",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EOPNOTSUPP: Tcl_SetStringObj(tcl_result,"GPG_ERR_EOPNOTSUPP",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EOVERFLOW: Tcl_SetStringObj(tcl_result,"GPG_ERR_EOVERFLOW",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EPERM: Tcl_SetStringObj(tcl_result,"GPG_ERR_EPERM",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EPFNOSUPPORT: Tcl_SetStringObj(tcl_result,"GPG_ERR_EPFNOSUPPORT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EPIPE: Tcl_SetStringObj(tcl_result,"GPG_ERR_EPIPE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EPROCLIM: Tcl_SetStringObj(tcl_result,"GPG_ERR_EPROCLIM",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EPROCUNAVAIL: Tcl_SetStringObj(tcl_result,"GPG_ERR_EPROCUNAVAIL",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EPROGMISMATCH: Tcl_SetStringObj(tcl_result,"GPG_ERR_EPROGMISMATCH",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EPROGUNAVAIL: Tcl_SetStringObj(tcl_result,"GPG_ERR_EPROGUNAVAIL",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EPROTO: Tcl_SetStringObj(tcl_result,"GPG_ERR_EPROTO",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EPROTONOSUPPORT: Tcl_SetStringObj(tcl_result,"GPG_ERR_EPROTONOSUPPORT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EPROTOTYPE: Tcl_SetStringObj(tcl_result,"GPG_ERR_EPROTOTYPE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ERANGE: Tcl_SetStringObj(tcl_result,"GPG_ERR_ERANGE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EREMCHG: Tcl_SetStringObj(tcl_result,"GPG_ERR_EREMCHG",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EREMOTE: Tcl_SetStringObj(tcl_result,"GPG_ERR_EREMOTE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EREMOTEIO: Tcl_SetStringObj(tcl_result,"GPG_ERR_EREMOTEIO",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ERESTART: Tcl_SetStringObj(tcl_result,"GPG_ERR_ERESTART",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EROFS: Tcl_SetStringObj(tcl_result,"GPG_ERR_EROFS",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ERPCMISMATCH: Tcl_SetStringObj(tcl_result,"GPG_ERR_ERPCMISMATCH",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ESHUTDOWN: Tcl_SetStringObj(tcl_result,"GPG_ERR_ESHUTDOWN",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ESOCKTNOSUPPORT: Tcl_SetStringObj(tcl_result,"GPG_ERR_ESOCKTNOSUPPORT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ESPIPE: Tcl_SetStringObj(tcl_result,"GPG_ERR_ESPIPE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ESRCH: Tcl_SetStringObj(tcl_result,"GPG_ERR_ESRCH",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ESRMNT: Tcl_SetStringObj(tcl_result,"GPG_ERR_ESRMNT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ESTALE: Tcl_SetStringObj(tcl_result,"GPG_ERR_ESTALE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ESTRPIPE: Tcl_SetStringObj(tcl_result,"GPG_ERR_ESTRPIPE",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ETIME: Tcl_SetStringObj(tcl_result,"GPG_ERR_ETIME",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ETIMEDOUT: Tcl_SetStringObj(tcl_result,"GPG_ERR_ETIMEDOUT",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ETOOMANYREFS: Tcl_SetStringObj(tcl_result,"GPG_ERR_ETOOMANYREFS",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_ETXTBSY: Tcl_SetStringObj(tcl_result,"GPG_ERR_ETXTBSY",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EUCLEAN: Tcl_SetStringObj(tcl_result,"GPG_ERR_EUCLEAN",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EUNATCH: Tcl_SetStringObj(tcl_result,"GPG_ERR_EUNATCH",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EUSERS: Tcl_SetStringObj(tcl_result,"GPG_ERR_EUSERS",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EWOULDBLOCK: Tcl_SetStringObj(tcl_result,"GPG_ERR_EWOULDBLOCK",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EXDEV: Tcl_SetStringObj(tcl_result,"GPG_ERR_EXDEV",-1); returnval=TCL_ERROR;break;
    case GPG_ERR_EXFULL: Tcl_SetStringObj(tcl_result,"GPG_ERR_EXFULL",-1); returnval=TCL_ERROR;break;
    }
    if (returnval != TCL_OK) {
        switch (($1 >> GPG_ERR_SOURCE_SHIFT) & GPG_ERR_SOURCE_MASK) {
            case GPG_ERR_SOURCE_UNKNOWN: Tcl_ListObjAppendElement(interp,tcl_result,Tcl_NewStringObj("GPG_ERR_SOURCE_UNKNOWN",-1)); break;
            case GPG_ERR_SOURCE_GCRYPT: Tcl_ListObjAppendElement(interp,tcl_result,Tcl_NewStringObj("GPG_ERR_SOURCE_GCRYPT",-1)); break;
            case GPG_ERR_SOURCE_GPG: Tcl_ListObjAppendElement(interp,tcl_result,Tcl_NewStringObj("GPG_ERR_SOURCE_GPG",-1)); break;
            case GPG_ERR_SOURCE_GPGSM: Tcl_ListObjAppendElement(interp,tcl_result,Tcl_NewStringObj("GPG_ERR_SOURCE_GPGSM",-1)); break;
            case GPG_ERR_SOURCE_GPGAGENT: Tcl_ListObjAppendElement(interp,tcl_result,Tcl_NewStringObj("GPG_ERR_SOURCE_GPGAGENT",-1)); break;
            case GPG_ERR_SOURCE_PINENTRY: Tcl_ListObjAppendElement(interp,tcl_result,Tcl_NewStringObj("GPG_ERR_SOURCE_PINENTRY",-1)); break;
            case GPG_ERR_SOURCE_SCD: Tcl_ListObjAppendElement(interp,tcl_result,Tcl_NewStringObj("GPG_ERR_SOURCE_SCD",-1)); break;
            case GPG_ERR_SOURCE_GPGME: Tcl_ListObjAppendElement(interp,tcl_result,Tcl_NewStringObj("GPG_ERR_SOURCE_GPGME",-1)); break;
            case GPG_ERR_SOURCE_KEYBOX: Tcl_ListObjAppendElement(interp,tcl_result,Tcl_NewStringObj("GPG_ERR_SOURCE_KEYBOX",-1)); break;
            case GPG_ERR_SOURCE_KSBA: Tcl_ListObjAppendElement(interp,tcl_result,Tcl_NewStringObj("GPG_ERR_SOURCE_KSBA",-1)); break;
            case GPG_ERR_SOURCE_DIRMNGR: Tcl_ListObjAppendElement(interp,tcl_result,Tcl_NewStringObj("GPG_ERR_SOURCE_DIRMNGR",-1)); break;
            case GPG_ERR_SOURCE_GSTI: Tcl_ListObjAppendElement(interp,tcl_result,Tcl_NewStringObj("GPG_ERR_SOURCE_GSTI",-1)); break;
            case GPG_ERR_SOURCE_ANY: Tcl_ListObjAppendElement(interp,tcl_result,Tcl_NewStringObj("GPG_ERR_SOURCE_ANY",-1)); break;
            case GPG_ERR_SOURCE_USER_1: Tcl_ListObjAppendElement(interp,tcl_result,Tcl_NewStringObj("GPG_ERR_SOURCE_USER_1",-1)); break;
            case GPG_ERR_SOURCE_USER_2: Tcl_ListObjAppendElement(interp,tcl_result,Tcl_NewStringObj("GPG_ERR_SOURCE_USER_2",-1)); break;
            case GPG_ERR_SOURCE_USER_3: Tcl_ListObjAppendElement(interp,tcl_result,Tcl_NewStringObj("GPG_ERR_SOURCE_USER_3",-1)); break;
            case GPG_ERR_SOURCE_USER_4: Tcl_ListObjAppendElement(interp,tcl_result,Tcl_NewStringObj("GPG_ERR_SOURCE_USER_4",-1)); break;
        }
        SWIG_fail;
    }
}

/* need typemaps for:
 * gpgme_ctx_t *ctx
 * gpgme_data_t *r_dh
 * gpgme_key_t *r_key
 * gpgme_trust_item_t *r_item
 * gpgme_engine_info_t *engine_info
 */

%typemap(in, numinputs=0) gpgme_ctx_t *ctx (gpgme_ctx_t result_ctx) {
    $1 = &result_ctx;
}
%typemap(argout) gpgme_ctx_t *ctx {
    Tcl_ListObjAppendElement(interp,Tcl_GetObjResult(interp),SWIG_NewInstanceObj(*$1,SWIGTYPE_p_gpgme_context,0));
}

%typemap(in, numinputs=0) gpgme_data_t *r_dh (gpgme_data_t result_dh) {
    $1 = &result_dh;
}

%typemap(argout) gpgme_data_t *r_dh {
    Tcl_ListObjAppendElement(interp,Tcl_GetObjResult(interp),SWIG_NewInstanceObj(*$1,SWIGTYPE_p_gpgme_data,0));
}

%apply gpgme_data_t *r_dh {gpgme_data_t *dh};

%typemap(in, numinputs=0) gpgme_key_t *r_key (gpgme_key_t result_key) {
    $1 = &result_key;
}
%typemap(argout) gpgme_key_t *r_key {
    Tcl_ListObjAppendElement(interp,Tcl_GetObjResult(interp),SWIG_NewInstanceObj(*$1,SWIGTYPE_p__gpgme_key,0));
}

%typemap(in, numinputs=0) gpgme_trust_item_t *r_item (gpgme_trust_item_t result_item) {
    $1 = &result_item;
}
%typemap(argout) gpgme_trust_item_t *r_item {
    Tcl_ListObjAppendElement(interp,Tcl_GetObjResult(interp),SWIG_NewInstanceObj(*$1,SWIGTYPE_p__gpgme_trust_item,0));
}

%typemap(in, numinputs=0) gpgme_engine_info_t *engine_info (gpgme_engine_info_t result_ei) {
    $1 = &result_ei;
}
%typemap(argout) gpgme_engine_info_t *engine_info {
    Tcl_ListObjAppendElement(interp,Tcl_GetObjResult(interp),SWIG_NewInstanceObj(*$1,SWIGTYPE_p__gpgme_engine_info,0));
}



/* need to deal with these callback functions: */

/* Request a passphrase from the user.  */                                      
/* typedef gpgme_error_t (*gpgme_passphrase_cb_t) (void *hook,                     
                                                const char *uid_hint,           
                                                const char *passphrase_info,    
                                                int prev_was_bad, int fd);      
*/

%{
    
typedef struct {
    Tcl_Interp *theinterp;
    Tcl_Obj *thecommand;
} tcl_callback_hook;
    
typedef int bool;
static gpgme_error_t tcl_passphrase_cb(void *hook, const char *uid_hint, 
                                       const char *passphrase_info, 
                                       int prev_was_bad, int fd) {
    int length;
    char *passphrase;
    int objc,io;
    Tcl_Obj **objv;
    Tcl_Obj *commandlist;
    tcl_callback_hook *tclhook = (tcl_callback_hook*) hook;
    
#ifdef DEBUG
    fprintf(stderr,"*** tcl_passphrase_cb: hook is 0x%llx\n",(unsigned long long) hook);
    fprintf(stderr,"*** tcl_passphrase_cb: commandlist is 0x%llx\n",(unsigned long long) commandlist);
    fprintf(stderr,"*** tcl_passphrase_cb: tclhook->thecommand->refCount is %d\n",tclhook->thecommand->refCount);
#endif
    commandlist = Tcl_DuplicateObj(tclhook->thecommand);
    Tcl_IncrRefCount(commandlist);
#ifdef DEBUG
    fprintf(stderr,"*** tcl_passphrase_cb: commandlist->refCount is %d\n",commandlist->refCount);
    fprintf(stderr,"*** tcl_passphrase_cb: uid_hint is 0x%llx\n",(unsigned long long) uid_hint);
#endif
    if (uid_hint == NULL) {
        if (Tcl_ListObjAppendElement(tclhook->theinterp,commandlist,
                                     Tcl_NewObj()) == TCL_ERROR) {
            Tcl_BackgroundError(tclhook->theinterp);
            return GPG_ERR_EINVAL;
        }
    } else {
        if (Tcl_ListObjAppendElement(tclhook->theinterp,commandlist,
                                     Tcl_NewStringObj(uid_hint,-1)) == TCL_ERROR) {
            Tcl_BackgroundError(tclhook->theinterp);
            return GPG_ERR_EINVAL;
        }
    }
#ifdef DEBUG
    fprintf(stderr,"*** tcl_passphrase_cb: passphrase_info is 0x%llx\n",(unsigned long long) passphrase_info);
#endif
    if (passphrase_info == NULL) {
        if (Tcl_ListObjAppendElement(tclhook->theinterp,commandlist,
                                     Tcl_NewObj()) == TCL_ERROR) {
            Tcl_BackgroundError(tclhook->theinterp);
            return GPG_ERR_EINVAL;
        }
    } else {
        if (Tcl_ListObjAppendElement(tclhook->theinterp,commandlist,
                                     Tcl_NewStringObj(passphrase_info,-1)) == TCL_ERROR) {
            Tcl_BackgroundError(tclhook->theinterp);
            return GPG_ERR_EINVAL;
        }
    }
#ifdef DEBUG
    fprintf(stderr,"*** tcl_passphrase_cb: prev_was_bad is %d\n",prev_was_bad);
#endif
    if (Tcl_ListObjAppendElement(tclhook->theinterp,commandlist,
                                 Tcl_NewBooleanObj(prev_was_bad)) == TCL_ERROR) {
        Tcl_BackgroundError(tclhook->theinterp);
        return GPG_ERR_EINVAL;
    }
#ifdef DEBUG
    fprintf(stderr,"*** tcl_passphrase_cb: About to call Eval\n");
#endif
    if (Tcl_EvalObjEx(tclhook->theinterp,commandlist,TCL_EVAL_GLOBAL) == TCL_ERROR) {
        Tcl_BackgroundError(tclhook->theinterp);
        return GPG_ERR_EINVAL;
    }
#ifdef DEBUG
    fprintf(stderr,"*** tcl_passphrase_cb: Eval returned\n");
#endif
    passphrase = Tcl_GetStringFromObj(Tcl_GetObjResult(tclhook->theinterp),
                                      &length);
#ifdef DEBUG
    fprintf(stderr,"*** tcl_passphrase_cb: passphrase is '%s'\n",passphrase);
#endif
    write(fd,passphrase,length);
    write(fd,"\n",1);
#ifdef DEBUG    
    fprintf(stderr,"*** tcl_passphrase_cb: commandlist->refCount is %d\n",commandlist->refCount);
#endif
    Tcl_DecrRefCount(commandlist);
    return GPG_ERR_NO_ERROR;
}
    
static int tcl_free_passphrase_cb(Tcl_Interp *interp, gpgme_ctx_t ctx) {
    tcl_callback_hook *tclhook;
    gpgme_passphrase_cb_t cb;
    void *hook_value;
    
    gpgme_get_passphrase_cb(ctx,&cb,&hook_value);
    if (cb == tcl_passphrase_cb) {
        tclhook = (tcl_callback_hook *) hook_value;
        Tcl_DecrRefCount(tclhook->thecommand);
        Tcl_Free((char *) tclhook);
        gpgme_set_passphrase_cb(ctx,NULL,NULL);
        return 1;
    } else {
        return 0;
    }
}
    
static void tcl_progress_cb (void *opaque, const char *what, int type, 
                             int current, int total) {
    int objc,io;
    Tcl_Obj **objv;
    Tcl_Obj *commandlist;
    tcl_callback_hook *tclhook = (tcl_callback_hook*) opaque;
    
#ifdef DEBUG
    fprintf(stderr,"*** tcl_progress_cb: opaque is 0x%llx\n",(unsigned long long) opaque);
    fprintf(stderr,"*** tcl_progress_cb: commandlist is 0x%llx\n",(unsigned long long) commandlist);
#endif
    commandlist = Tcl_DuplicateObj(tclhook->thecommand);
    Tcl_IncrRefCount(commandlist);
#ifdef DEBUG
    fprintf(stderr,"*** tcl_progress_cb: what is 0x%llx\n",(unsigned long long) what);
#endif
    if (what == NULL) {
        if (Tcl_ListObjAppendElement(tclhook->theinterp,commandlist,
                                     Tcl_NewObj()) == TCL_ERROR) {
            Tcl_BackgroundError(tclhook->theinterp);
            return;
        }
    } else {
        if (Tcl_ListObjAppendElement(tclhook->theinterp,commandlist,
                                     Tcl_NewStringObj(what,-1)) == TCL_ERROR) {
            Tcl_BackgroundError(tclhook->theinterp);
            return;
        }
    }
#ifdef DEBUG
    fprintf(stderr,"*** tcl_progress_cb: type is %d\n",type);
#endif
    if (Tcl_ListObjAppendElement(tclhook->theinterp,commandlist,
                                 Tcl_NewIntObj(type)) == TCL_ERROR) {
        Tcl_BackgroundError(tclhook->theinterp);
        return;
    }
#ifdef DEBUG
    fprintf(stderr,"*** tcl_progress_cb: current is %d\n",current);
#endif
    if (Tcl_ListObjAppendElement(tclhook->theinterp,commandlist,
                                 Tcl_NewIntObj(current)) == TCL_ERROR) {
        Tcl_BackgroundError(tclhook->theinterp);
        return;
    }
#ifdef DEBUG
    fprintf(stderr,"*** tcl_progress_cb: total is %d\n",total);
#endif
    if (Tcl_ListObjAppendElement(tclhook->theinterp,commandlist,
                                 Tcl_NewIntObj(total)) == TCL_ERROR) {
        Tcl_BackgroundError(tclhook->theinterp);
        return;
    }
#ifdef DEBUG
    fprintf(stderr,"*** tcl_progress_cb: About to call Eval\n");
#endif
    if (Tcl_EvalObjEx(tclhook->theinterp,commandlist,TCL_EVAL_GLOBAL) == TCL_ERROR) {
        Tcl_BackgroundError(tclhook->theinterp);
        return;
    }
#ifdef DEBUG
    fprintf(stderr,"*** tcl_progress_cb: Eval returned\n");
#endif
    Tcl_DecrRefCount(commandlist);
}
    
static int tcl_free_progress_cb(Tcl_Interp *interp, gpgme_ctx_t ctx) {
    tcl_callback_hook *tclhook;
    gpgme_progress_cb_t cb;
    void *hook_value;
    
    gpgme_get_progress_cb(ctx,&cb,&hook_value);
    if (cb == tcl_progress_cb) {
        tclhook = (tcl_callback_hook *) hook_value;
        Tcl_DecrRefCount(tclhook->thecommand);
        Tcl_Free((char *) tclhook);
        gpgme_set_progress_cb(ctx,NULL,NULL);
        return 1;
    } else {
        return 0;
    }
}
    
%}


%typemap(in, numinputs=1) (gpgme_passphrase_cb_t cb, void *hook_value) (tcl_callback_hook *tcl_hook) {
    int l;
    char *cmd = Tcl_GetStringFromObj($input,&l);
    if (l == 0) {
        $1 = NULL;
        $2 = NULL;
    } else {
        tcl_hook = (tcl_callback_hook *) Tcl_Alloc(sizeof(tcl_callback_hook));
        tcl_hook->theinterp = interp;
        tcl_hook->thecommand = $input;
        Tcl_IncrRefCount($input);
        $1 = tcl_passphrase_cb;
#ifdef DEBUG
        fprintf(stderr,"*** $symname: $1_name = 0x%llx\n",(unsigned long long) $1);
#endif
        $2 = (void *) tcl_hook;
    }
}

%typemap(in, numinputs=0) (gpgme_passphrase_cb_t *cb, void **hook_value) (gpgme_passphrase_cb_t passphrase_cb_tmp, void *hook_tmp) {
    $1 = &passphrase_cb_tmp;
    $2 = &hook_tmp;
}

%typemap(argout) (gpgme_passphrase_cb_t *cb, void **hook_value) {
#ifdef DEBUG
    fprintf(stderr,"*** $symname: $1_name = 0x%llx\n",(unsigned long long) *$1);
#endif
    if (*$1 == tcl_passphrase_cb) {
        tcl_callback_hook *tcl_hook = (tcl_callback_hook *) *$2;
        Tcl_SetObjResult(interp,tcl_hook->thecommand);
    }
}

bool tcl_free_passphrase_cb(Tcl_Interp *interp, gpgme_ctx_t ctx);

/* Inform the user about progress made.  */                                     
/*typedef void (*gpgme_progress_cb_t) (void *opaque, const char *what,            
                                     int type, int current, int total);         
*/

%typemap(in, numinputs=1) (gpgme_progress_cb_t cb, void *hook_value)  (tcl_callback_hook *tcl_hook) {
    int l;
    char *cmd = Tcl_GetStringFromObj($input,&l);
    if (l == 0) {
        $1 = NULL;
        $2 = NULL;
    } else {
        tcl_hook = (tcl_callback_hook *) Tcl_Alloc(sizeof(tcl_callback_hook));
        tcl_hook->theinterp = interp;
        tcl_hook->thecommand = $input;
        Tcl_IncrRefCount($input);
        $1 = tcl_progress_cb;
#ifdef DEBUG
        fprintf(stderr,"*** $symname: $1_name = 0x%llx\n",(unsigned long long) $1);
#endif
        $2 = (void *) tcl_hook;
    }
}

%typemap(in, numinputs=0) (gpgme_progress_cb_t *cb, void **hook_value) (gpgme_progress_cb_t progress_cb_tmp, void *hook_tmp) {
    $1 = &progress_cb_tmp;
    $2 = &hook_tmp;
}

%typemap(argout) (gpgme_progress_cb_t *cb, void **hook_value) {
#ifdef DEBUG
    fprintf(stderr,"*** $symname: $1_name = 0x%llx\n",(unsigned long long) *$1);
#endif
    if (*$1 == tcl_progress_cb) {
        tcl_callback_hook *tcl_hook = (tcl_callback_hook *) *$2;
        Tcl_SetObjResult(interp,tcl_hook->thecommand);
    }
}

bool tcl_free_progress_cb(Tcl_Interp *interp, gpgme_ctx_t ctx);

/* Typemap for gpgme_data_new_from_mem args: Tcl String => gpgme_data_t obj */

%typemap (in, numinputs=1) (const char *buffer, size_t size, int copy) (int s) {
    $1 = Tcl_GetStringFromObj($input,&s);
    $2 = (size_t)s;
    $3 = 1;
}

/* Typemaps for gpgme_data_release_and_get_mem: gpgme_data_t obj => Tcl String */

%typemap (in, numinputs=0) size_t *r_len (size_t r_len) {
    $1 = &r_len;
}


%typemap (out) char * {
    Tcl_SetObjResult(interp,Tcl_NewStringObj($1,-1));
    if (strcmp("$symname","gpgme_data_release_and_get_mem") == 0) {
        gpgme_free($1);
    }
}

%apply int Tcl_Result { int tcl_gpgme_data_release_and_get_mem };

int tcl_gpgme_data_release_and_get_mem (Tcl_Interp *interp, gpgme_data_t dh);
%{
static int tcl_gpgme_data_release_and_get_mem (Tcl_Interp *interp, gpgme_data_t dh) {
    char *result;
    size_t length;
    result = gpgme_data_release_and_get_mem(dh, &length);
    Tcl_SetObjResult(interp,Tcl_NewStringObj(result,length));
    gpgme_free(result);
    return TCL_OK;
}
%}


%typemap(in) gpgme_key_t recp[] {
    Tcl_Obj **Kobjv;
    int       Kobjc,io,res;
    if (Tcl_ListObjGetElements(interp,$input,&Kobjc,&Kobjv) == TCL_ERROR) return TCL_ERROR;
    $1 = (gpgme_key_t *) Tcl_Alloc(sizeof(gpgme_key_t) * (Kobjc+1));
    for (io = 0; io < Kobjc; io++) {
        void *argp = 0 ;
        res = SWIG_ConvertPtr(Kobjv[io], &argp,SWIGTYPE_p__gpgme_key, 0 |  0 );
        if (!SWIG_IsOK(res)) {
            SWIG_exception_fail(SWIG_ArgError(res), "in '$symname' element of $1_name is not a gpgme_key_t!");
        }
        $1[io] = (gpgme_key_t)(argp);
    }
    $1[io] = NULL;
}

%typemap(freearg) gpgme_key_t recp[] {
    Tcl_Free((char *) $1);
}

%typemap(in) const char *pattern[] {
    Tcl_Obj **Pobjv;
    int       Pobjc,io;
    if (Tcl_ListObjGetElements(interp,$input,&Pobjc,&Pobjv) == TCL_ERROR) return TCL_ERROR;
    $1 = (const char **) Tcl_Alloc(sizeof(const char *) * (Pobjc+1));
    for (io = 0; io < Pobjc; io++) {
        $1[io] = Tcl_GetStringFromObj(Pobjv[io],NULL);
    }
    $1[io] = NULL;
}

%typemap(freearg) const char *pattern[] {
    Tcl_Free((char *) $1);
}

%typemap(in) int fd {
    int mode;
    ClientData handle;
    Tcl_Channel chan = Tcl_GetChannel(interp, 
                                      Tcl_GetStringFromObj($input,NULL), 
                                      &mode);
    if (chan == NULL) {
        SWIG_exception_fail(SWIG_ArgError(SWIG_ERROR), "in '$symname': not a channel!");
    }
    if (Tcl_GetChannelHandle(chan,mode,&handle) == TCL_OK) {
        $1 = (int) handle;
    }
}
        

%include "gpgme.h"

