'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "4e33cd97dbd57fbeb7b3e1bd18a8984e",
"version.json": "c991f28107d02d63723d29c856c537d1",
"index.html": "d3321745350eed4fbbf5f2bb45e5aac9",
"/": "d3321745350eed4fbbf5f2bb45e5aac9",
"main.dart.js": "0644d8b9c5ee557bbadc7619a6696bdf",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "d8571cf6091e9f2a39e86eac3a6cf375",
"assets/AssetManifest.json": "1896c3db22cd000c2e06fb1e91ef8d79",
"assets/NOTICES": "e9f17d641f07dcd3712ab4d73447a72d",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "6e6fa662d46e1c7ff36f2d8164ce055b",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/fluttertoast/assets/toastify.js": "56e2c9cedd97f10e7e5f1cebd85d53e3",
"assets/packages/fluttertoast/assets/toastify.css": "a85675050054f179444bc5ad70ffc635",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "bfa429b6c68bd04503ee8a912d74e581",
"assets/fonts/MaterialIcons-Regular.otf": "d57e1716c239f18ca647333f925c0720",
"assets/assets/cards/svgs/clubs_j.svg": "4d161a58c95595b209b46b0fce0d5f3a",
"assets/assets/cards/svgs/clubs_k.svg": "7cf47b897d884aa8dc340a5d2e20ea43",
"assets/assets/cards/svgs/hearts_j.svg": "5505bc9ee367b650a2cd9a2885b57d4c",
"assets/assets/cards/svgs/diamonds_9.svg": "8fb853cc66b59effce3dfcdc96bb1d67",
"assets/assets/cards/svgs/diamonds_8.svg": "d9f8f8c3ab4765e570985a3043df1b10",
"assets/assets/cards/svgs/hearts_k.svg": "75f6a3b7b72b7dadaf5c066a57ad074a",
"assets/assets/cards/svgs/hearts_9.svg": "554d46c201529f8712587295f490db47",
"assets/assets/cards/svgs/diamonds_j.svg": "ed049c62929e4d03406d961ce6003f5f",
"assets/assets/cards/svgs/hearts_10.svg": "4946093ee64dd0d1921112504ef12271",
"assets/assets/cards/svgs/diamonds_k.svg": "dfaf4129ccbef005f1a626cb9cf4ebe2",
"assets/assets/cards/svgs/hearts_8.svg": "172313d46e94ddbaae3108317807f9bd",
"assets/assets/cards/svgs/spades_10.svg": "f0c8403d38a618e039d317b06c2b7848",
"assets/assets/cards/svgs/clubs_9.svg": "56893b72a1d6ca17b41037a013053b52",
"assets/assets/cards/svgs/clubs_8.svg": "dc333fbee88580931ae47b3d78935ad2",
"assets/assets/cards/svgs/spades_4.svg": "ee3a88010d2d817631b37149e1747002",
"assets/assets/cards/svgs/spades_5.svg": "b86e43a61b8a4c64c2de5661d3fc31d6",
"assets/assets/cards/svgs/spades_a.svg": "84d5e28162a95911ca29f2c444ff8ca2",
"assets/assets/cards/svgs/spades_7.svg": "827a6d98dd1458a9da05782e27eb7e69",
"assets/assets/cards/svgs/diamonds_10.svg": "4f7473b46f22ff4ccec783e0c8ffde0e",
"assets/assets/cards/svgs/spades_6.svg": "cc53e6db9fe74716b39ae82806b6a095",
"assets/assets/cards/svgs/spades_2.svg": "61c943d92894d0008e093fc63779bdaf",
"assets/assets/cards/svgs/spades_3.svg": "473de77f0e1f470327b88b92e5c8f747",
"assets/assets/cards/svgs/spades_q.svg": "7874b844dc65ac54c2ee00a28ee1298a",
"assets/assets/cards/svgs/spades_k.svg": "39a34428143b96d339f1d9037a5c8597",
"assets/assets/cards/svgs/clubs_10.svg": "b7331fc3dcbce5052c4436c4d68a92a2",
"assets/assets/cards/svgs/spades_j.svg": "5f71284072c4ca0f7e3bd4e7b9bf1601",
"assets/assets/cards/svgs/card_back.svg": "5f4fd417fb2b8223f0b547e65878b792",
"assets/assets/cards/svgs/spades_8.svg": "3cbc5c6743120460a45c284d1aaaf0e0",
"assets/assets/cards/svgs/spades_9.svg": "9afd3ca31cec016f51e9519bbea25783",
"assets/assets/cards/svgs/hearts_6.svg": "2845ca239bc5490dd8457e4e7452b225",
"assets/assets/cards/svgs/diamonds_3.svg": "989e383abe9f8468488aa05b2d74313f",
"assets/assets/cards/svgs/clubs_5.svg": "f041cfe5465b470f14bef41ff88d3c73",
"assets/assets/cards/svgs/clubs_4.svg": "4e3ba8a755a98d9ba206515e5dafec4b",
"assets/assets/cards/svgs/diamonds_2.svg": "851d5c6ba5612e974fdee41da7bb39fb",
"assets/assets/cards/svgs/hearts_7.svg": "6b934009a489dc3ac7bf9922aaf5ab38",
"assets/assets/cards/svgs/hearts_a.svg": "561a4183217dbaf2f89424cf7983edde",
"assets/assets/cards/svgs/hearts_5.svg": "6a49921c7f9c80283202ea67a84940e1",
"assets/assets/cards/svgs/diamonds_q.svg": "88ccc71f00ff52c7c3736633c2e0bc6c",
"assets/assets/cards/svgs/clubs_6.svg": "df15a9827aa789585d0d24f01e2dbdfb",
"assets/assets/cards/svgs/clubs_a.svg": "ff7ca2f8e68018f4de641bdcd9a38a45",
"assets/assets/cards/svgs/clubs_7.svg": "4159ca585448c390ed467d8155bc88f6",
"assets/assets/cards/svgs/hearts_4.svg": "dc2495b710de0b0fa6112918f000c3fc",
"assets/assets/cards/svgs/hearts_q.svg": "999a4cc1ecbeb110aaac044d3a878f74",
"assets/assets/cards/svgs/diamonds_5.svg": "f2f0b1fa56c4ef3689355f63818225ce",
"assets/assets/cards/svgs/clubs_3.svg": "404b5a0cef608c790484949e56033e55",
"assets/assets/cards/svgs/card_template.svg": "ee85b04cfe6a331e9678b93b60332de3",
"assets/assets/cards/svgs/clubs_2.svg": "39b2a56c60e020891e037ad00a4ed152",
"assets/assets/cards/svgs/diamonds_4.svg": "21cb80800e2623084a7db520d809c785",
"assets/assets/cards/svgs/card_face_down.svg": "b4a46f42b4d800188b8baf3049193e3c",
"assets/assets/cards/svgs/hearts_3.svg": "d080723f42de06f54389e26f93bd15ae",
"assets/assets/cards/svgs/diamonds_6.svg": "29cb56ca5f84282590f529bbde12cc50",
"assets/assets/cards/svgs/clubs_q.svg": "f1ebecdb788e2103baa0c17d28da22bd",
"assets/assets/cards/svgs/diamonds_7.svg": "236844e160e0b3873f7ba4b16cad230e",
"assets/assets/cards/svgs/diamonds_a.svg": "8c19c5eb20acdd4ba5419c6180885729",
"assets/assets/cards/svgs/hearts_2.svg": "bc0a2f50f51cd22deb9fd2312724d804",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
