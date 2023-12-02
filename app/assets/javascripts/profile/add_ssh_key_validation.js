export default class AddSshKeyValidation {
  constructor(
    supportedAlgorithms,
    inputElement,
    warningElement,
    originalSubmitElement,
    confirmSubmitElement,
  ) {
    this.inputElement = inputElement;
    this.form = inputElement.form;

    this.supportedAlgorithms = supportedAlgorithms;
    this.publicKeyRegExp = new RegExp(`^(${this.supportedAlgorithms.join('|')})`);

    this.warningElement = warningElement;

    this.originalSubmitElement = originalSubmitElement;
    this.confirmSubmitElement = confirmSubmitElement;

    this.isValid = false;
  }

  register() {
    this.form.addEventListener('submit', (event) => this.submit(event));

    this.confirmSubmitElement.addEventListener('click', () => {
      this.isValid = true;
      this.form.submit();
    });

    this.inputElement.addEventListener('input', () => this.toggleWarning(false));
  }

  submit(event) {
    this.isValid = this.isPublicKey(this.inputElement.value);

    if (this.isValid) return true;

    event.preventDefault();
    this.toggleWarning(true);
    return false;
  }

  toggleWarning(isVisible) {
    this.warningElement.classList.toggle('hide', !isVisible);
    this.originalSubmitElement.classList.toggle('hide', isVisible);
  }

  isPublicKey(value) {
    return this.publicKeyRegExp.test(value);
  }
}
