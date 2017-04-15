const VALID_EMAIL_RE = /[_a-z0-9+-]+@[a-z0-9+-]+(\.([a-z0-9+-])+)+/;

export function isValidEmail(email) {
    return VALID_EMAIL_RE.test(email);
}


export default { isValidEmail };
