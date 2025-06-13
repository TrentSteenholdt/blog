// @ts-check
(function () {
  'use strict';


  if (isDateTimeFormatSupported()) {
    formatDates();
  }

  ////////////////
  function formatDates() {
    const language = navigator.language;
    const dateTimeOptions = { month: 'long', year: 'numeric', day: 'numeric' };
    const dateTimeFormat = new Intl.DateTimeFormat(language);

    const relativeTimeOptions = { numeric: 'auto' };
    // @ts-ignore
    const relativeTimeFormat = new Intl.RelativeTimeFormat(language, relativeTimeOptions);

    const oneDayInMs = 24 * 60 * 60 * 1000;
    const thirtyDaysInMs = 30 * oneDayInMs;

    const publishDates = [...document.querySelectorAll('.publish-date time')];

    publishDates.forEach(date => {
      const timeSincePublishInMs = new Date().getTime() - new Date(date.textContent).getTime();

      if ((timeSincePublishInMs > thirtyDaysInMs) || !isRelativeTimeFormatSupported()) {
        date.textContent = dateTimeFormat.format(new Date(date.textContent));
      } else {
        const daysSincePublish = Math.floor(timeSincePublishInMs / oneDayInMs);

        date.textContent = relativeTimeFormat.format(-daysSincePublish, 'day');
      }
    });
  }

  function isDateTimeFormatSupported() {
    return typeof Intl.DateTimeFormat === 'function';
  }

  function isRelativeTimeFormatSupported() {
    // @ts-ignore
    return typeof Intl.RelativeTimeFormat === 'function';
  }

      
}());
