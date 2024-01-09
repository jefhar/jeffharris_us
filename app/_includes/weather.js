//  Weather
const weatherAPIUrl = 'https://api.weather.gov/gridpoints/GSP/118,64/forecast';
const weatherAlertAPIUrl = 'https://api.weather.gov/alerts/active/zone/NCC119';
const apiOptions = {
  headers: new Headers({'User-Agent': '(jeffharris.us, jeff@jeffharris.us)'})
};
const weatherDom = document.getElementById('weatherRow');
const weatherAlertCards = [];
const weatherCards = [];
const alertRequest = new Request(weatherAlertAPIUrl, apiOptions);
const request = new Request(weatherAPIUrl, apiOptions);
fetch(alertRequest)
  .then((result) => result.json())
  .then((data) => {
    const features = data?.features;
    if (features === null) {
      return [];
    }

    return features.map((feature) => ({
      description: feature.properties.description,
      effective: feature.properties.effective,
      expires: new Date(feature.properties.expires),
      headline: feature.properties.headline,
      severity: feature.properties.severity,
    }));

  })
  .then((alerts) => {
    if (!alerts.length) {
      return;
    }
    const alertCards = alerts.map((alert) => {
      const card = document.createElement('div');
      card.classList.add('card', 'text-white', 'bg-danger', 'mb-3', 'mx-2', 'border', 'border-danger');

      const cardHeader = document.createElement('div');
      cardHeader.classList.add('card-header', 'bg-danger');
      cardHeader.innerHTML = `<h4>${alert.headline}</h4>`;
      card.appendChild(cardHeader);

      const cardBody = document.createElement('div');
      cardBody.classList.add('card-body');

      const cardTitle = document.createElement('div');
      cardTitle.classList.add('card-title');
      cardTitle.innerText = `${alert.severity} from: ${alert.effective.toLocaleString()} to ${alert.expires.toLocaleString()}`

      const cardText = document.createElement('p');
      cardText.classList.add('card-text');
      cardText.innerHTML = `${alert.description.replaceAll('*', '<br />*')}`;

      cardBody.appendChild(cardTitle);
      cardBody.appendChild(cardText);

      card.appendChild(cardHeader);
      card.appendChild(cardBody);

      return card;
    });
    alertCards.forEach((card) => {
      document.getElementById('weatherAlertRow').appendChild(card);
    });

    document.getElementById('weatherAlerts').classList.replace('invisible', 'visible');
  });

fetch(request).then((response) => {
  if (!response.ok) {
    alert(`Unable to fetch weather from API. Server Error ${response.status}.`);
  }
  return response;
})
  .then((result) => result.json())
  .then((data) => {
    const {periods, updated} = data.properties;
    const date = new Date(updated);
    document.getElementById('weatherUpdated').innerText = `Updated at ${date.toLocaleString()}`;
    for (let i = 0; i < 8; ++i) {
      const period = periods[i];
      let card = document.createElement('div');
      card.classList.add('col-6', 'col-md-4', 'col-lg-3');
      if (i > 3) {
        card.classList.add('d-none', 'd-md-block');
      }
      if (i > 5) {
        card.classList.replace('d-md-block', 'd-lg-block');
      }
      card.innerHTML =
        `<div class="card mb-2">
  <h5 class="card-header">${period.name}</h5>
  <div class="card-body">
    <h6 class="card-title">${period.shortForecast}</h6>
    <p class="card-text hyphenate small">
<img class="float-left weather-icon rounded mr-2" src="${period.icon}" alt="${period.shortForecast}">
${period.detailedForecast}</p>
  </div>
</div>`;
      weatherCards.push(card);
    }
  })
  .catch((error) => {
    alert('Fetching weather failed. Please try again in a few moments.');
  })
  .finally(() => {
    weatherCards.forEach(card => {
      weatherDom.appendChild(card);
    });
  });
