/*!
 * Welcome Page banner script and configuration.
 * 
 * This script fetches instance information from the API and displays a banner if the instance 
 * matches any of the configured banners.
 * 
 * This script was is AI assisted.
 * 
 * INSTANCE_BANNERS is a list of banner definitions.
 * 
 * A banner is shown only when both instanceMode and instanceName match
 * the values returned by /api/instance-mode.json.
 * 
 * Each banner must define a type (info | success | warning | danger).
 * 
 * Titles and messages must be provided in both English and French.
 * 
 * If the API is unavailable or no banner matches, nothing is displayed.
 */
const INSTANCE_BANNERS = [
  {
    match: {
      instanceMode: "TEST",
      instanceName: "GRDI"
    },
    banner: {
      type: "warning",
      titleEn: "TEST ENVIRONMENT",
      messageEn:
        "This is the DINA test instance. The demo account has write access so users can explore and experiment freely. Data created in this environment is temporary and is not persisted.",
      titleFr: "ENVIRONNEMENT DE TEST",
      messageFr:
        "Ceci est l’instance de test de DINA. Le compte de démonstration dispose d’un accès en écriture afin de permettre l’exploration et les essais. Les données créées dans cet environnement sont temporaires et ne sont pas conservées."
    }
  }
];

(function () {
  // API endpoint for fetching instance information.
  const ENDPOINT = "/api/instance.json";

  // Banner containers (English + French)
  const EN_CONTAINER_ID = "instance-banner-en";
  const FR_CONTAINER_ID = "instance-banner-fr";

  fetch(ENDPOINT, { cache: "no-store" })
    .then(response => {
      if (!response.ok) return;
      return response.json();
    })
    .then(data => {
      const bannerConfig = findMatchingBanner(data);
      if (bannerConfig) {
        renderEnglishBanner(bannerConfig);
        renderFrenchBanner(bannerConfig);
      }
    })
    .catch(() => {
      // Fail silently
    });

  function findMatchingBanner(instanceData) {
    return INSTANCE_BANNERS.find(entry =>
      entry.match.instanceMode === instanceData["instance-mode"] &&
      entry.match.instanceName === instanceData["instance-name"]
    );
  }

  function renderEnglishBanner(config) {
    renderBanner(
      EN_CONTAINER_ID,
      config.banner.type,
      config.banner.titleEn,
      config.banner.messageEn,
      "en"
    );
  }

  function renderFrenchBanner(config) {
    renderBanner(
      FR_CONTAINER_ID,
      config.banner.type,
      config.banner.titleFr,
      config.banner.messageFr,
      "fr"
    );
  }

  function renderBanner(containerId, type, title, message, lang) {
    const container = document.getElementById(containerId);
    if (!container) return;

    container.innerHTML = `
      <section class="alert alert-${type}" role="alert" lang="${lang}">
        <h3>${escapeHtml(title)}</h3>
        <p>${escapeHtml(message)}</p>
      </section>
    `;
  }

  function escapeHtml(str) {
    return String(str).replace(/[&<>"']/g, c => ({
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#39;"
    }[c]));
  }
})();
